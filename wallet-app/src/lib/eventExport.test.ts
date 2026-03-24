import { describe, expect, it } from 'vitest'
import type { IndexerEvent, IndexerEventsResponse } from '../api/walletApi'
import {
  buildEventsExportFileName,
  collectAllEvents,
  isExportCancelledError,
  isExportLimitExceededError,
  serializeEventsToCsv,
  serializeEventsToJson,
} from './eventExport'

const mockEvents: IndexerEvent[] = [
  {
    id: 'evt-1',
    type: 'new_block',
    height: 101,
    blockHash: '0xabc',
    payload: '{"k":"v"}',
    producedAt: '2026-03-05T00:00:00Z',
  },
  {
    id: 'evt-2',
    type: 'tx',
    height: 102,
    blockHash: '0xdef',
    payload: 'line1\nline2',
    producedAt: '2026-03-05T00:01:00Z',
  },
]

describe('event export serialization', () => {
  it('serializes events to json', () => {
    const json = serializeEventsToJson(mockEvents)
    expect(json).toContain('"id": "evt-1"')
    expect(json).toContain('"height": 102')
  })

  it('serializes events to csv with escaped payload', () => {
    const csv = serializeEventsToCsv(mockEvents)
    expect(csv.startsWith('id,type,height,block_hash,produced_at,payload\n')).toBe(true)
    expect(csv).toContain('"evt-1","new_block","101","0xabc","2026-03-05T00:00:00Z","{""k"":""v""}"')
    expect(csv).toContain('"line1\nline2"')
  })

  it('builds deterministic export file name', () => {
    const fileName = buildEventsExportFileName('csv', new Date('2026-03-05T08:09:10'))
    expect(fileName).toBe('events-20260305-080910.csv')
  })

  it('collects all events through pagination', async () => {
    const pages: IndexerEventsResponse[] = [
      {
        events: [mockEvents[0]],
        total: 2,
        offset: 0,
        limit: 1,
        hasMore: true,
      },
      {
        events: [mockEvents[1]],
        total: 2,
        offset: 1,
        limit: 1,
        hasMore: false,
      },
    ]
    let cursor = 0
    const events = await collectAllEvents(async () => {
      const response = pages[cursor]
      cursor += 1
      return response
    }, { order: 'desc' }, { pageSize: 1 })
    expect(events).toHaveLength(2)
    expect(events[0].id).toBe('evt-1')
    expect(events[1].id).toBe('evt-2')
  })

  it('stops when empty page is returned', async () => {
    const events = await collectAllEvents(async () => {
      return {
        events: [],
        total: 0,
        offset: 0,
        limit: 200,
        hasMore: true,
      }
    }, { order: 'desc' })
    expect(events).toHaveLength(0)
  })

  it('reports pagination progress', async () => {
    const progress: Array<{ page: number; totalCollected: number }> = []
    const pages: IndexerEventsResponse[] = [
      {
        events: [mockEvents[0]],
        total: 2,
        offset: 0,
        limit: 1,
        hasMore: true,
      },
      {
        events: [mockEvents[1]],
        total: 2,
        offset: 1,
        limit: 1,
        hasMore: false,
      },
    ]
    let cursor = 0
    await collectAllEvents(async () => {
      const response = pages[cursor]
      cursor += 1
      return response
    }, { order: 'desc' }, {
      pageSize: 1,
      onProgress: (snapshot) => progress.push(snapshot),
    })
    expect(progress).toEqual([
      { page: 1, totalCollected: 1 },
      { page: 2, totalCollected: 2 },
    ])
  })

  it('supports cancellation with abort signal', async () => {
    const controller = new AbortController()
    let called = false
    await expect(
      collectAllEvents(async () => {
        called = true
        return {
          events: [mockEvents[0]],
          total: 1,
          offset: 0,
          limit: 1,
          hasMore: false,
        }
      }, { order: 'desc' }, { signal: controller.signal }),
    ).resolves.toHaveLength(1)
    expect(called).toBe(true)

    controller.abort()
    await expect(
      collectAllEvents(async () => {
        return {
          events: [mockEvents[0]],
          total: 1,
          offset: 0,
          limit: 1,
          hasMore: false,
        }
      }, { order: 'desc' }, { signal: controller.signal }),
    ).rejects.toSatisfy((error: unknown) => isExportCancelledError(error))
  })

  it('fails when total exceeds export limit', async () => {
    await expect(
      collectAllEvents(async () => {
        return {
          events: [mockEvents[0]],
          total: 10001,
          offset: 0,
          limit: 1,
          hasMore: false,
        }
      }, { order: 'desc' }, { maxRecords: 10000 }),
    ).rejects.toSatisfy((error: unknown) => isExportLimitExceededError(error))
  })
})
