import { useEffect, useMemo, useRef, useState } from 'react'
import { Link, useLocation, useParams } from 'react-router-dom'
import type { RequestLifecycleEvent } from '../api/client'
import { ApiClientError, isSessionInvalidError } from '../api/errors'
import { walletApi } from '../api/walletApi'
import type { IndexerEvent } from '../api/walletApi'
import { useAuth } from '../auth/useAuth'

type EventDetailLocationState = {
  event?: IndexerEvent
}

const RETRY_COUNT = 2
const RETRY_BACKOFF_MS = 250

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

const formatPayload = (payload: string): string => {
  if (!payload) {
    return '-'
  }
  try {
    return JSON.stringify(JSON.parse(payload), null, 2)
  } catch {
    return payload
  }
}

export function EventDetailPage() {
  const { signOut } = useAuth()
  const { eventId } = useParams<{ eventId: string }>()
  const location = useLocation()
  const locationState = location.state as EventDetailLocationState | null
  const routeEvent = locationState?.event
  const [event, setEvent] = useState<IndexerEvent | null>(routeEvent ?? null)
  const [loading, setLoading] = useState<boolean>(false)
  const [error, setError] = useState<string>('')
  const [lifecycle, setLifecycle] = useState<RequestLifecycleEvent | null>(null)
  const lifecycleRef = useRef<RequestLifecycleEvent | null>(null)
  const targetEventId = eventId?.trim() ?? ''

  const effectiveEvent = useMemo<IndexerEvent | null>(() => {
    if (routeEvent?.id === targetEventId) {
      return routeEvent
    }
    return event
  }, [event, routeEvent, targetEventId])

  useEffect(() => {
    if (!targetEventId) {
      return
    }
    if (routeEvent?.id === targetEventId) {
      return
    }
    let mounted = true
    const run = async () => {
      setLoading(true)
      setError('')
      setEvent(null)
      try {
        const response = await walletApi.getIndexerEventById(targetEventId, {
          retryCount: RETRY_COUNT,
          retryBackoffMs: RETRY_BACKOFF_MS,
          traceContext: {
            feature: 'event_detail_page',
            action: 'fetch_event_detail',
          },
          onLifecycle: (nextEvent) => {
            lifecycleRef.current = nextEvent
            if (!mounted) {
              return
            }
            setLifecycle(nextEvent)
          },
        })
        if (!mounted) {
          return
        }
        setEvent(response.event)
      } catch (requestError) {
        if (!mounted) {
          return
        }
        if (isSessionInvalidError(requestError)) {
          signOut('会话已失效，请重新登录。')
          return
        }
        if (requestError instanceof ApiClientError) {
          if (requestError.status === 404) {
            setError(`未找到事件 ${targetEventId}`)
            return
          }
          const attribution = lifecycleRef.current?.attribution
          const attributionText = attribution
            ? ` layer=${attribution.layer} reason=${attribution.reason} retryable=${String(attribution.retryable)}`
            : ''
          setError(
            `code=${requestError.code} status=${requestError.status ?? '-'} msg=${requestError.message}${attributionText}`,
          )
          return
        }
        setError(requestError instanceof Error ? requestError.message : '未知错误')
      } finally {
        if (mounted) {
          setLoading(false)
        }
      }
    }
    void run()
    return () => {
      mounted = false
    }
  }, [routeEvent, signOut, targetEventId])

  if (!effectiveEvent && loading) {
    return (
      <section className="panel-page">
        <div className="panel-overview">
          <p className="page-kicker">Spot Event Detail</p>
          <h2>交易详情</h2>
          <p className="page-description">正在回源加载事件详情，请稍候。</p>
        </div>
        <p>加载中...</p>
      </section>
    )
  }

  if (!effectiveEvent) {
    return (
      <section className="panel-page">
        <div className="panel-overview">
          <p className="page-kicker">Spot Event Detail</p>
          <h2>交易详情</h2>
          <p className="page-description">未找到交易详情数据，请返回列表或稍后重试。</p>
        </div>
        <p className="error-text">{error || (targetEventId ? '未找到事件详情。' : '事件ID无效，请从列表重新进入。')}</p>
        <p className="meta-line">
          请求观测: stage={lifecycle?.stage ?? '-'} requestId={lifecycle?.requestId ?? '-'} attempt=
          {lifecycle ? `${lifecycle.attempt + 1}/${lifecycle.maxRetries + 1}` : '-'} duration=
          {lifecycle?.durationMs ?? '-'}ms attribution=
          {lifecycle?.attribution
            ? `${lifecycle.attribution.layer}/${lifecycle.attribution.reason}/${lifecycle.attribution.code ?? '-'}`
            : '-'}
        </p>
        <div className="page-actions">
          <Link to="/events">返回交易与事件列表</Link>
        </div>
      </section>
    )
  }

  return (
    <section className="panel-page">
      <div className="panel-overview">
        <p className="page-kicker">Spot Event Detail</p>
        <h2>交易详情</h2>
        <p className="page-description">查看事件关键字段与 payload 内容，辅助定位链路行为与状态变化。</p>
      </div>
      <div className="exchange-card detail-head-card">
        <p className="meta-line">事件ID: {eventId}</p>
      </div>
      {error ? <p className="error-text">{error}</p> : null}
      <div className="detail-grid">
        <div className="state-card">
          <span>ID</span>
          <strong>{effectiveEvent.id}</strong>
        </div>
        <div className="state-card">
          <span>类型</span>
          <strong>{effectiveEvent.type}</strong>
        </div>
        <div className="state-card">
          <span>高度</span>
          <strong>{effectiveEvent.height}</strong>
        </div>
        <div className="state-card">
          <span>区块哈希</span>
          <strong>{effectiveEvent.blockHash || '-'}</strong>
        </div>
        <div className="state-card">
          <span>父区块哈希</span>
          <strong>{effectiveEvent.parentHash || '-'}</strong>
        </div>
        <div className="state-card">
          <span>回滚高度</span>
          <strong>{effectiveEvent.rollbackFrom ?? '-'}</strong>
        </div>
        <div className="state-card">
          <span>产生时间</span>
          <strong>{formatEventTime(effectiveEvent.producedAt)}</strong>
        </div>
        <div className="state-card">
          <span>持久化时间</span>
          <strong>{formatEventTime(effectiveEvent.persistedAt ?? '')}</strong>
        </div>
      </div>
      <div className="payload-panel exchange-card">
        <h3>Payload</h3>
        <pre>{formatPayload(effectiveEvent.payload)}</pre>
      </div>
      <p className="meta-line">
        请求观测: stage={lifecycle?.stage ?? '-'} requestId={lifecycle?.requestId ?? '-'} attempt=
        {lifecycle ? `${lifecycle.attempt + 1}/${lifecycle.maxRetries + 1}` : '-'} duration=
        {lifecycle?.durationMs ?? '-'}ms attribution=
        {lifecycle?.attribution
          ? `${lifecycle.attribution.layer}/${lifecycle.attribution.reason}/${lifecycle.attribution.code ?? '-'}`
          : '-'}
      </p>
      <div className="page-actions">
        <Link to="/events">返回交易与事件列表</Link>
      </div>
    </section>
  )
}
