import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { EventDetailPage } from './EventDetailPage'
import type { IndexerEvent } from '../api/walletApi'

const mocks = vi.hoisted(() => {
  return {
    getIndexerEventById: vi.fn(),
    signOut: vi.fn(),
  }
})

vi.mock('../api/walletApi', async () => {
  const actual = await vi.importActual<typeof import('../api/walletApi')>('../api/walletApi')
  return {
    ...actual,
    walletApi: {
      ...actual.walletApi,
      getIndexerEventById: mocks.getIndexerEventById,
    },
  }
})

vi.mock('../auth/useAuth', () => {
  return {
    useAuth: () => ({
      signOut: mocks.signOut,
    }),
  }
})

const buildEvent = (id: string): IndexerEvent => ({
  id,
  type: 'transfer',
  height: 1024,
  blockHash: 'block-hash',
  parentHash: 'parent-hash',
  payload: '{"amount":"100"}',
  producedAt: '2026-03-04T00:00:00.000Z',
  persistedAt: '2026-03-04T00:00:10.000Z',
})

describe('EventDetailPage', () => {
  beforeEach(() => {
    mocks.getIndexerEventById.mockReset()
    mocks.signOut.mockReset()
  })

  it('路由 state 包含事件时直接渲染且不回源', () => {
    const routeEvent = buildEvent('evt-route')
    render(
      <MemoryRouter initialEntries={[{ pathname: '/events/evt-route', state: { event: routeEvent } }]}>
        <Routes>
          <Route path="/events/:eventId" element={<EventDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    expect(screen.getByText('交易详情')).toBeInTheDocument()
    expect(screen.getByText('evt-route')).toBeInTheDocument()
    expect(mocks.getIndexerEventById).not.toHaveBeenCalled()
  })

  it('路由 state 缺失时按事件 ID 回源加载详情', async () => {
    const fetchedEvent = buildEvent('evt-fetch')
    mocks.getIndexerEventById.mockResolvedValue({
      event: fetchedEvent,
    })

    render(
      <MemoryRouter initialEntries={['/events/evt-fetch']}>
        <Routes>
          <Route path="/events/:eventId" element={<EventDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(mocks.getIndexerEventById).toHaveBeenCalledWith(
        'evt-fetch',
        expect.objectContaining({
          retryCount: 2,
          retryBackoffMs: 250,
        }),
      )
    })

    expect(screen.getByText('evt-fetch')).toBeInTheDocument()
    expect(mocks.signOut).not.toHaveBeenCalled()
  })
})
