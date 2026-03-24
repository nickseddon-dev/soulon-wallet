import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import type { RequestLifecycleEvent } from '../api/client'
import { useAuth } from '../auth/useAuth'
import { ApiClientError, isSessionInvalidError } from '../api/errors'
import { walletApi } from '../api/walletApi'
import type { IndexerEvent, IndexerEventsResponse } from '../api/walletApi'
import {
  buildEventsExportFileName,
  collectAllEvents,
  downloadTextFile,
  isExportCancelledError,
  isExportLimitExceededError,
  serializeEventsToCsv,
  serializeEventsToJson,
} from '../lib/eventExport'

const PAGE_SIZE_OPTIONS = [10, 20, 50]
const RETRY_COUNT = 2
const RETRY_BACKOFF_MS = 250
const MAX_EXPORT_RECORDS = 10000

type EventsQueryState = {
  limit: number
  order: 'asc' | 'desc'
  type?: string
  minHeight?: number
  maxHeight?: number
}

const parseHeightFilter = (value: string): number | null => {
  const trimmed = value.trim()
  if (!trimmed) {
    return null
  }
  const parsed = Number(trimmed)
  if (!Number.isInteger(parsed) || parsed < 0) {
    return null
  }
  return parsed
}

const formatEventPayload = (payload: string): string => {
  try {
    const parsed = JSON.parse(payload)
    return JSON.stringify(parsed)
  } catch {
    return payload
  }
}

const formatEventTime = (value: string): string => {
  if (!value) {
    return '-'
  }
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) {
    return value
  }
  return date.toLocaleString('zh-CN')
}

export function EventsPage() {
  const { signOut } = useAuth()
  const [eventData, setEventData] = useState<IndexerEventsResponse | null>(null)
  const [loading, setLoading] = useState<boolean>(true)
  const [error, setError] = useState<string>('')
  const [offset, setOffset] = useState<number>(0)
  const [queryState, setQueryState] = useState<EventsQueryState>({
    limit: PAGE_SIZE_OPTIONS[0],
    order: 'desc',
  })
  const [limitInput, setLimitInput] = useState<number>(PAGE_SIZE_OPTIONS[0])
  const [orderInput, setOrderInput] = useState<'asc' | 'desc'>('desc')
  const [eventTypeInput, setEventTypeInput] = useState<string>('')
  const [minHeightInput, setMinHeightInput] = useState<string>('')
  const [maxHeightInput, setMaxHeightInput] = useState<string>('')
  const [lifecycle, setLifecycle] = useState<RequestLifecycleEvent | null>(null)
  const [exportingAll, setExportingAll] = useState<boolean>(false)
  const [exportProgress, setExportProgress] = useState<string>('')
  const lifecycleRef = useRef<RequestLifecycleEvent | null>(null)
  const exportAbortRef = useRef<AbortController | null>(null)

  const loadEvents = useCallback(async (nextOffset: number, nextQuery: EventsQueryState) => {
    setLoading(true)
    try {
      const response = await walletApi.getIndexerEvents({
        limit: nextQuery.limit,
        offset: nextOffset,
        order: nextQuery.order,
        type: nextQuery.type,
        minHeight: nextQuery.minHeight,
        maxHeight: nextQuery.maxHeight,
      }, {
        retryCount: RETRY_COUNT,
        retryBackoffMs: RETRY_BACKOFF_MS,
        traceContext: {
          feature: 'events_page',
          action: 'fetch_events',
        },
        onLifecycle: (event) => {
          lifecycleRef.current = event
          setLifecycle(event)
        },
      })
      setEventData(response)
      setError('')
    } catch (requestError) {
      if (isSessionInvalidError(requestError)) {
        signOut('会话已失效，请重新登录。')
        return
      }
      if (requestError instanceof ApiClientError) {
        const attribution = lifecycleRef.current?.attribution
        const attributionText = attribution
          ? ` layer=${attribution.layer} reason=${attribution.reason} retryable=${String(attribution.retryable)}`
          : ''
        setError(
          `code=${requestError.code} status=${requestError.status ?? '-'} msg=${requestError.message}${attributionText}`,
        )
      } else {
        setError(requestError instanceof Error ? requestError.message : '未知错误')
      }
    } finally {
      setLoading(false)
    }
  }, [signOut])

  useEffect(() => {
    void loadEvents(offset, queryState)
  }, [loadEvents, offset, queryState])

  const events = useMemo<IndexerEvent[]>(() => {
    return eventData?.events ?? []
  }, [eventData?.events])

  const currentPage = Math.floor(offset / queryState.limit) + 1
  const canPrev = offset > 0
  const canNext = Boolean(eventData?.hasMore)

  const applyFilters = () => {
    const minHeight = parseHeightFilter(minHeightInput)
    const maxHeight = parseHeightFilter(maxHeightInput)
    if ((minHeightInput.trim() && minHeight === null) || (maxHeightInput.trim() && maxHeight === null)) {
      setError('高度筛选必须是大于等于 0 的整数')
      return
    }
    if (minHeight !== null && maxHeight !== null && minHeight > maxHeight) {
      setError('最小高度不能大于最大高度')
      return
    }
    setOffset(0)
    setQueryState({
      limit: limitInput,
      order: orderInput,
      type: eventTypeInput.trim() || undefined,
      minHeight: minHeight ?? undefined,
      maxHeight: maxHeight ?? undefined,
    })
    setError('')
  }

  const resetFilters = () => {
    setLimitInput(PAGE_SIZE_OPTIONS[0])
    setOrderInput('desc')
    setEventTypeInput('')
    setMinHeightInput('')
    setMaxHeightInput('')
    setOffset(0)
    setQueryState({
      limit: PAGE_SIZE_OPTIONS[0],
      order: 'desc',
    })
    setError('')
  }

  const exportAsJson = () => {
    if (!events.length) {
      setError('当前页没有可导出的事件数据')
      return
    }
    const payload = serializeEventsToJson(events)
    downloadTextFile(payload, buildEventsExportFileName('json'), 'application/json;charset=utf-8')
    setError('')
  }

  const exportAsCsv = () => {
    if (!events.length) {
      setError('当前页没有可导出的事件数据')
      return
    }
    const payload = serializeEventsToCsv(events)
    downloadTextFile(payload, buildEventsExportFileName('csv'), 'text/csv;charset=utf-8')
    setError('')
  }

  const exportAllAsJson = async () => {
    exportAbortRef.current?.abort()
    const abortController = new AbortController()
    exportAbortRef.current = abortController
    setExportingAll(true)
    setExportProgress('开始拉取事件...')
    try {
      const allEvents = await collectAllEvents(
        (query) => walletApi.getIndexerEvents(query),
        {
          order: queryState.order,
          type: queryState.type,
          minHeight: queryState.minHeight,
          maxHeight: queryState.maxHeight,
        },
        {
          signal: abortController.signal,
          maxRecords: MAX_EXPORT_RECORDS,
          onProgress: ({ page, totalCollected }) => {
            setExportProgress(`已拉取 ${page} 页，累计 ${totalCollected} 条`)
          },
        },
      )
      if (!allEvents.length) {
        setError('筛选条件下没有可导出的事件数据')
        setExportProgress('')
        return
      }
      const payload = serializeEventsToJson(allEvents)
      downloadTextFile(payload, buildEventsExportFileName('json'), 'application/json;charset=utf-8')
      setError('')
      setExportProgress(`导出完成，共 ${allEvents.length} 条`)
    } catch (requestError) {
      if (isExportCancelledError(requestError)) {
        setExportProgress('导出已取消')
        return
      }
      if (isExportLimitExceededError(requestError)) {
        setExportProgress('')
        setError(`导出数据量超过 ${MAX_EXPORT_RECORDS} 条上限，请收窄筛选条件后重试`)
        return
      }
      if (isSessionInvalidError(requestError)) {
        signOut('会话已失效，请重新登录。')
        setExportProgress('')
        return
      }
      setExportProgress('')
      setError(requestError instanceof Error ? requestError.message : '全量导出失败')
    } finally {
      if (exportAbortRef.current === abortController) {
        exportAbortRef.current = null
      }
      setExportingAll(false)
    }
  }

  const exportAllAsCsv = async () => {
    exportAbortRef.current?.abort()
    const abortController = new AbortController()
    exportAbortRef.current = abortController
    setExportingAll(true)
    setExportProgress('开始拉取事件...')
    try {
      const allEvents = await collectAllEvents(
        (query) => walletApi.getIndexerEvents(query),
        {
          order: queryState.order,
          type: queryState.type,
          minHeight: queryState.minHeight,
          maxHeight: queryState.maxHeight,
        },
        {
          signal: abortController.signal,
          maxRecords: MAX_EXPORT_RECORDS,
          onProgress: ({ page, totalCollected }) => {
            setExportProgress(`已拉取 ${page} 页，累计 ${totalCollected} 条`)
          },
        },
      )
      if (!allEvents.length) {
        setError('筛选条件下没有可导出的事件数据')
        setExportProgress('')
        return
      }
      const payload = serializeEventsToCsv(allEvents)
      downloadTextFile(payload, buildEventsExportFileName('csv'), 'text/csv;charset=utf-8')
      setError('')
      setExportProgress(`导出完成，共 ${allEvents.length} 条`)
    } catch (requestError) {
      if (isExportCancelledError(requestError)) {
        setExportProgress('导出已取消')
        return
      }
      if (isExportLimitExceededError(requestError)) {
        setExportProgress('')
        setError(`导出数据量超过 ${MAX_EXPORT_RECORDS} 条上限，请收窄筛选条件后重试`)
        return
      }
      if (isSessionInvalidError(requestError)) {
        signOut('会话已失效，请重新登录。')
        setExportProgress('')
        return
      }
      setExportProgress('')
      setError(requestError instanceof Error ? requestError.message : '全量导出失败')
    } finally {
      if (exportAbortRef.current === abortController) {
        exportAbortRef.current = null
      }
      setExportingAll(false)
    }
  }

  const cancelExport = () => {
    exportAbortRef.current?.abort()
  }

  return (
    <section className="panel-page">
      <div className="panel-overview">
        <p className="page-kicker">Spot Event Stream</p>
        <h2>交易与事件</h2>
        <p className="page-description">按条件筛选并分页查看链上事件，快速追踪异常和业务轨迹。</p>
      </div>
      <div className="exchange-card filter-card">
        <div className="page-actions">
          <label className="field-inline">
            每页
            <select value={limitInput} onChange={(event) => setLimitInput(Number(event.target.value))} disabled={loading}>
              {PAGE_SIZE_OPTIONS.map((option) => (
                <option key={option} value={option}>
                  {option}
                </option>
              ))}
            </select>
          </label>
          <label className="field-inline">
            排序
            <select
              value={orderInput}
              onChange={(event) => setOrderInput(event.target.value as 'asc' | 'desc')}
              disabled={loading}
            >
              <option value="desc">desc</option>
              <option value="asc">asc</option>
            </select>
          </label>
          <label className="field-inline">
            事件类型
            <input
              value={eventTypeInput}
              onChange={(event) => setEventTypeInput(event.target.value)}
              placeholder="如 new_block"
              disabled={loading}
            />
          </label>
          <label className="field-inline">
            最小高度
            <input
              value={minHeightInput}
              onChange={(event) => setMinHeightInput(event.target.value)}
              placeholder=">=0"
              disabled={loading}
            />
          </label>
          <label className="field-inline">
            最大高度
            <input
              value={maxHeightInput}
              onChange={(event) => setMaxHeightInput(event.target.value)}
              placeholder=">=0"
              disabled={loading}
            />
          </label>
          <button type="button" onClick={applyFilters} disabled={loading}>
            应用筛选
          </button>
          <button type="button" onClick={resetFilters} disabled={loading}>
            重置
          </button>
          <button type="button" onClick={() => setOffset(0)} disabled={loading}>
            刷新列表
          </button>
          <button type="button" onClick={exportAsJson} disabled={loading || exportingAll || !events.length}>
            导出JSON
          </button>
          <button type="button" onClick={exportAsCsv} disabled={loading || exportingAll || !events.length}>
            导出CSV
          </button>
          <button type="button" onClick={() => void exportAllAsJson()} disabled={loading || exportingAll}>
            {exportingAll ? '导出中...' : '导出全部JSON'}
          </button>
          <button type="button" onClick={() => void exportAllAsCsv()} disabled={loading || exportingAll}>
            {exportingAll ? '导出中...' : '导出全部CSV'}
          </button>
          <button type="button" onClick={cancelExport} disabled={!exportingAll}>
            取消导出
          </button>
        </div>
      </div>
      {error ? <p className="error-text">{error}</p> : null}
      {exportProgress ? <p className="events-meta">{exportProgress}</p> : null}
      <div className="events-meta-grid">
        <p className="events-meta events-meta-card">
          总数: {eventData?.total ?? 0}，当前页: {currentPage}，offset: {offset}，limit: {queryState.limit}，order:{' '}
          {queryState.order}，type: {queryState.type ?? '全部'}，height: {queryState.minHeight ?? '-'} ~{' '}
          {queryState.maxHeight ?? '-'}
        </p>
        <p className="events-meta events-meta-card">
          请求观测: stage={lifecycle?.stage ?? '-'} requestId={lifecycle?.requestId ?? '-'} attempt=
          {lifecycle ? `${lifecycle.attempt + 1}/${lifecycle.maxRetries + 1}` : '-'} duration=
          {lifecycle?.durationMs ?? '-'}ms attribution=
          {lifecycle?.attribution
            ? `${lifecycle.attribution.layer}/${lifecycle.attribution.reason}/${lifecycle.attribution.code ?? '-'}`
            : '-'}
        </p>
      </div>
      <div className="events-table-wrap">
        <table className="events-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>类型</th>
              <th>高度</th>
              <th>区块哈希</th>
              <th>时间</th>
              <th>Payload</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            {events.map((event) => (
              <tr key={event.id}>
                <td>{event.id}</td>
                <td>{event.type}</td>
                <td>{event.height}</td>
                <td>{event.blockHash || '-'}</td>
                <td>{formatEventTime(event.producedAt)}</td>
                <td>{formatEventPayload(event.payload)}</td>
                <td>
                  <Link className="table-link" to={`/events/${event.id}`} state={{ event }}>
                    查看详情
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {!loading && !events.length ? <p>暂无事件数据。</p> : null}
      </div>
      <div className="pagination-actions">
        <button
          type="button"
          onClick={() => setOffset((value) => Math.max(value - queryState.limit, 0))}
          disabled={loading || !canPrev}
        >
          上一页
        </button>
        <button
          type="button"
          onClick={() => setOffset((value) => value + queryState.limit)}
          disabled={loading || !canNext}
        >
          下一页
        </button>
      </div>
    </section>
  )
}
