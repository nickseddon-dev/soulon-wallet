import { appEnv } from '../config/env'
import { apiClient } from './client'
import type { RequestLifecycleEvent, RequestTraceContext } from './client'
import { chainApiPaths } from './chainApiContract'

export type HealthResponse = {
  status: string
}

export type IndexerStateResponse = {
  tipHeight: number
  tipHash: string
  total: number
  reorgs: number
}

export type IndexerEvent = {
  id: string
  type: string
  height: number
  blockHash: string
  parentHash?: string
  rollbackFrom?: number
  payload: string
  producedAt: string
  persistedAt?: string
}

export type IndexerEventsQuery = {
  limit?: number
  offset?: number
  order?: 'asc' | 'desc'
  type?: string
  minHeight?: number
  maxHeight?: number
}

export type IndexerEventsResponse = {
  events: IndexerEvent[]
  total: number
  offset: number
  limit: number
  hasMore: boolean
}

export type IndexerEventsRequestOptions = {
  retryCount?: number
  retryBackoffMs?: number
  traceContext?: RequestTraceContext
  onLifecycle?: (event: RequestLifecycleEvent) => void
}

export type IndexerEventDetailResponse = {
  event: IndexerEvent
}

export type SignatureChallengeResponse = {
  requestId: string
  accountId: string
  challengeMessage: string
  expiresAt: string
}

export type SignatureAuthorizeResponse = {
  success: boolean
  signature: string
  accountId: string
  requestId: string
  authorizedAt: string
}

export type NotificationMessage = {
  id: string
  type: string
  height: number
  blockHash: string
  parentHash?: string
  payload: string
  producedAt: string
  persistedAt?: string
  receivedAt: string
}

export type NotificationsResponse = {
  notifications: NotificationMessage[]
  total: number
  offset: number
  limit: number
  hasMore: boolean
}

export const walletApi = {
  getHealth: async (): Promise<HealthResponse> => {
    return apiClient.get<HealthResponse>(chainApiPaths.health)
  },
  getIndexerState: async (): Promise<IndexerStateResponse> => {
    return apiClient.get<IndexerStateResponse>(chainApiPaths.indexerState)
  },
  getIndexerEvents: async (
    query: IndexerEventsQuery,
    options: IndexerEventsRequestOptions = {},
  ): Promise<IndexerEventsResponse> => {
    return apiClient.get<IndexerEventsResponse>(chainApiPaths.indexerEvents, {
      query,
      retryCount: options.retryCount,
      retryBackoffMs: options.retryBackoffMs,
      traceContext: options.traceContext,
      onLifecycle: options.onLifecycle,
    })
  },
  getIndexerEventById: async (
    eventId: string,
    options: IndexerEventsRequestOptions = {},
  ): Promise<IndexerEventDetailResponse> => {
    return apiClient.get<IndexerEventDetailResponse>(
      `${chainApiPaths.indexerEvents}/${encodeURIComponent(eventId)}`,
      {
      retryCount: options.retryCount,
      retryBackoffMs: options.retryBackoffMs,
      traceContext: options.traceContext,
      onLifecycle: options.onLifecycle,
      },
    )
  },
  getNotifications: async (query: { limit?: number; offset?: number } = {}): Promise<NotificationsResponse> => {
    return apiClient.get<NotificationsResponse>(chainApiPaths.notifications, {
      query,
    })
  },
  getNotificationsStreamUrl: (initialLimit?: number): string => {
    const url = new URL(chainApiPaths.notificationsStream, appEnv.apiBaseUrl)
    if (typeof initialLimit === 'number' && Number.isFinite(initialLimit) && initialLimit > 0) {
      url.searchParams.set('initialLimit', String(initialLimit))
    }
    if (appEnv.notificationStreamToken) {
      url.searchParams.set('token', appEnv.notificationStreamToken)
    }
    return url.toString()
  },
  createSignatureChallenge: async (accountId: string): Promise<SignatureChallengeResponse> => {
    return apiClient.request<SignatureChallengeResponse>(chainApiPaths.authSignatureChallenge, {
      method: 'POST',
      body: {
        accountId,
      },
    })
  },
  confirmSignatureAuthorization: async (input: {
    accountId: string
    requestId: string
    signature: string
  }): Promise<SignatureAuthorizeResponse> => {
    return apiClient.request<SignatureAuthorizeResponse>(chainApiPaths.authSignatureConfirm, {
      method: 'POST',
      body: input,
    })
  },
}
