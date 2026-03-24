import type { IndexerEvent, IndexerEventsQuery, IndexerEventsResponse } from '../api/walletApi'

const CSV_HEADER = ['id', 'type', 'height', 'block_hash', 'produced_at', 'payload']

const escapeCsv = (value: string): string => {
  const escaped = value.replace(/"/g, '""')
  return `"${escaped}"`
}

export const serializeEventsToJson = (events: IndexerEvent[]): string => {
  return JSON.stringify(events, null, 2)
}

export const serializeEventsToCsv = (events: IndexerEvent[]): string => {
  const rows = events.map((event) =>
    [
      event.id,
      event.type,
      String(event.height),
      event.blockHash ?? '',
      event.producedAt,
      event.payload,
    ]
      .map((value) => escapeCsv(value))
      .join(','),
  )
  return [CSV_HEADER.join(','), ...rows].join('\n')
}

export const buildEventsExportFileName = (format: 'json' | 'csv', now: Date = new Date()): string => {
  const year = now.getFullYear()
  const month = String(now.getMonth() + 1).padStart(2, '0')
  const day = String(now.getDate()).padStart(2, '0')
  const hour = String(now.getHours()).padStart(2, '0')
  const minute = String(now.getMinutes()).padStart(2, '0')
  const second = String(now.getSeconds()).padStart(2, '0')
  return `events-${year}${month}${day}-${hour}${minute}${second}.${format}`
}

export const downloadTextFile = (content: string, fileName: string, mimeType: string) => {
  const blob = new Blob([content], { type: mimeType })
  const href = URL.createObjectURL(blob)
  const anchor = document.createElement('a')
  anchor.href = href
  anchor.download = fileName
  document.body.appendChild(anchor)
  anchor.click()
  document.body.removeChild(anchor)
  URL.revokeObjectURL(href)
}

type FetchEventsPage = (query: IndexerEventsQuery) => Promise<IndexerEventsResponse>

type CollectAllEventsOptions = {
  pageSize?: number
  maxPages?: number
  maxRecords?: number
  signal?: AbortSignal
  onProgress?: (snapshot: { page: number; totalCollected: number }) => void
}

const EXPORT_CANCELLED_ERROR = 'EXPORT_CANCELLED'
const EXPORT_LIMIT_EXCEEDED_ERROR = 'EXPORT_LIMIT_EXCEEDED'

export const isExportCancelledError = (error: unknown): boolean => {
  return error instanceof Error && error.message === EXPORT_CANCELLED_ERROR
}

export const isExportLimitExceededError = (error: unknown): boolean => {
  return error instanceof Error && error.message === EXPORT_LIMIT_EXCEEDED_ERROR
}

export const collectAllEvents = async (
  fetchPage: FetchEventsPage,
  query: Omit<IndexerEventsQuery, 'offset' | 'limit'>,
  options: CollectAllEventsOptions = {},
): Promise<IndexerEvent[]> => {
  const pageSize = options.pageSize ?? 200
  const maxPages = options.maxPages ?? 500
  const maxRecords = options.maxRecords ?? 10000
  const events: IndexerEvent[] = []
  let offset = 0
  let hasMore = true
  let pageCount = 0

  while (hasMore && pageCount < maxPages) {
    if (options.signal?.aborted) {
      throw new Error(EXPORT_CANCELLED_ERROR)
    }
    const response = await fetchPage({
      ...query,
      limit: pageSize,
      offset,
    })
    if (response.total > maxRecords) {
      throw new Error(EXPORT_LIMIT_EXCEEDED_ERROR)
    }
    events.push(...response.events)
    if (events.length > maxRecords) {
      throw new Error(EXPORT_LIMIT_EXCEEDED_ERROR)
    }
    hasMore = response.hasMore
    pageCount += 1
    if (!response.events.length) {
      break
    }
    offset += response.events.length
    options.onProgress?.({
      page: pageCount,
      totalCollected: events.length,
    })
  }

  if (options.signal?.aborted) {
    throw new Error(EXPORT_CANCELLED_ERROR)
  }

  return events
}
