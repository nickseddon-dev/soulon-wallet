import { appEnv } from '../config/env'
import {
  ApiClientError,
  isWalletSemanticErrorCode,
  resolveWalletSemanticErrorMessage,
  type ApiErrorCode,
} from './errors'

type HttpMethod = 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE'

export type RequestTraceContext = {
  feature: string
  action: string
  requestId?: string
}

export type RequestErrorAttribution = {
  layer: 'http' | 'transport' | 'parse' | 'unknown'
  reason: string
  status?: number
  code?: string
  retryable: boolean
}

export type RequestLifecycleEvent = {
  stage: 'start' | 'retry' | 'success' | 'failure'
  requestId: string
  path: string
  url: string
  method: HttpMethod
  feature?: string
  action?: string
  attempt: number
  maxRetries: number
  durationMs: number
  status?: number
  attribution?: RequestErrorAttribution
}

export type RequestOptions = {
  method?: HttpMethod
  query?: Record<string, string | number | boolean | undefined>
  headers?: Record<string, string>
  body?: unknown
  timeoutMs?: number
  retryCount?: number
  retryBackoffMs?: number
  traceContext?: RequestTraceContext
  onLifecycle?: (event: RequestLifecycleEvent) => void
}

const sleep = async (ms: number) => {
  await new Promise((resolve) => {
    setTimeout(resolve, ms)
  })
}

const isRetryableStatus = (status: number): boolean => {
  return status === 429 || status >= 500
}

const buildUrl = (baseUrl: string, path: string, query?: RequestOptions['query']): string => {
  const normalizedBase = baseUrl.endsWith('/') ? baseUrl.slice(0, -1) : baseUrl
  const normalizedPath = path.startsWith('/') ? path : `/${path}`
  const url = new URL(`${normalizedBase}${normalizedPath}`)
  if (query) {
    for (const [key, value] of Object.entries(query)) {
      if (value === undefined) {
        continue
      }
      url.searchParams.set(key, String(value))
    }
  }
  return url.toString()
}

const resolveErrorMessage = (payload: unknown, fallback: string): string => {
  if (payload && typeof payload === 'object') {
    if ('error' in payload && typeof payload.error === 'string') {
      return payload.error
    }
    if ('message' in payload && typeof payload.message === 'string') {
      return payload.message
    }
  }
  return fallback
}

type StructuredErrorPayload = {
  code?: ApiErrorCode
  message: string
  retryable?: boolean
}

const resolveStructuredErrorPayload = (payload: unknown, fallback: string): StructuredErrorPayload => {
  const message = resolveErrorMessage(payload, fallback)
  if (!payload || typeof payload !== 'object') {
    return { message }
  }
  const payloadCode = 'code' in payload && typeof payload.code === 'string' ? payload.code.trim() : ''
  const payloadRetryable =
    'retryable' in payload && typeof payload.retryable === 'boolean' ? payload.retryable : undefined
  if (payloadCode && isWalletSemanticErrorCode(payloadCode)) {
    return {
      code: payloadCode,
      message: resolveWalletSemanticErrorMessage(payloadCode, message),
      retryable: payloadRetryable,
    }
  }
  return {
    message,
    retryable: payloadRetryable,
  }
}

const createRequestId = (traceContext?: RequestTraceContext): string => {
  if (traceContext?.requestId) {
    return traceContext.requestId
  }
  return `req_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 8)}`
}

export class ApiClient {
  private readonly baseUrl: string
  private readonly timeoutMs: number
  private readonly retryCount: number

  constructor(input: { baseUrl: string; timeoutMs: number; retryCount: number }) {
    this.baseUrl = input.baseUrl
    this.timeoutMs = input.timeoutMs
    this.retryCount = input.retryCount
  }

  async request<T>(path: string, options: RequestOptions = {}): Promise<T> {
    const method = options.method ?? 'GET'
    const timeoutMs = options.timeoutMs ?? this.timeoutMs
    const defaultRetryCount = method === 'GET' ? this.retryCount : 0
    const maxRetries = options.retryCount ?? defaultRetryCount
    const retryBackoffMs = options.retryBackoffMs ?? 200
    const url = buildUrl(this.baseUrl, path, options.query)
    const body = options.body === undefined ? undefined : JSON.stringify(options.body)
    const requestStartedAt = Date.now()
    const requestId = createRequestId(options.traceContext)
    const headers: Record<string, string> = {
      Accept: 'application/json',
      ...options.headers,
    }
    if (body) {
      headers['Content-Type'] = 'application/json'
    }

    options.onLifecycle?.({
      stage: 'start',
      requestId,
      path,
      url,
      method,
      feature: options.traceContext?.feature,
      action: options.traceContext?.action,
      attempt: 0,
      maxRetries,
      durationMs: 0,
    })

    let attempt = 0
    while (attempt <= maxRetries) {
      const controller = new AbortController()
      const timeoutId = setTimeout(() => {
        controller.abort('timeout')
      }, timeoutMs)
      try {
        const response = await fetch(url, {
          method,
          headers,
          body,
          signal: controller.signal,
        })
        if (!response.ok) {
          let payload: unknown
          try {
            payload = await response.json()
          } catch {
            payload = undefined
          }
          const structuredError = resolveStructuredErrorPayload(payload, `HTTP ${response.status}`)
          const errorCode = structuredError.code ?? 'HTTP_ERROR'
          const retryable = structuredError.retryable ?? isRetryableStatus(response.status)
          const error = new ApiClientError({
            code: errorCode,
            message: structuredError.message,
            status: response.status,
            retryable,
          })
          const elapsed = Date.now() - requestStartedAt
          if (error.retryable && attempt < maxRetries) {
            attempt += 1
            options.onLifecycle?.({
              stage: 'retry',
              requestId,
              path,
              url,
              method,
              feature: options.traceContext?.feature,
              action: options.traceContext?.action,
              attempt,
              maxRetries,
              durationMs: elapsed,
              status: response.status,
              attribution: {
                layer: 'http',
                reason: 'retryable_http_status',
                status: response.status,
                code: error.code,
                retryable: true,
              },
            })
            await sleep(retryBackoffMs * attempt)
            continue
          }
          options.onLifecycle?.({
            stage: 'failure',
            requestId,
            path,
            url,
            method,
            feature: options.traceContext?.feature,
            action: options.traceContext?.action,
            attempt,
            maxRetries,
            durationMs: elapsed,
            status: response.status,
            attribution: {
              layer: 'http',
              reason: 'http_status_not_ok',
              status: response.status,
              code: error.code,
              retryable: error.retryable,
            },
          })
          throw error
        }
        try {
          const data = (await response.json()) as T
          options.onLifecycle?.({
            stage: 'success',
            requestId,
            path,
            url,
            method,
            feature: options.traceContext?.feature,
            action: options.traceContext?.action,
            attempt,
            maxRetries,
            durationMs: Date.now() - requestStartedAt,
            status: response.status,
          })
          return data
        } catch {
          const parseError = new ApiClientError({
            code: 'PARSE_ERROR',
            message: '响应解析失败',
            retryable: false,
          })
          options.onLifecycle?.({
            stage: 'failure',
            requestId,
            path,
            url,
            method,
            feature: options.traceContext?.feature,
            action: options.traceContext?.action,
            attempt,
            maxRetries,
            durationMs: Date.now() - requestStartedAt,
            status: response.status,
            attribution: {
              layer: 'parse',
              reason: 'response_json_parse_failed',
              code: parseError.code,
              retryable: false,
            },
          })
          throw parseError
        }
      } catch (error) {
        const isAbortError = error instanceof DOMException && error.name === 'AbortError'
        if (isAbortError) {
          const timeoutError = new ApiClientError({
            code: 'TIMEOUT',
            message: `请求超时（>${timeoutMs}ms）`,
            retryable: true,
          })
          const elapsed = Date.now() - requestStartedAt
          if (attempt < maxRetries) {
            attempt += 1
            options.onLifecycle?.({
              stage: 'retry',
              requestId,
              path,
              url,
              method,
              feature: options.traceContext?.feature,
              action: options.traceContext?.action,
              attempt,
              maxRetries,
              durationMs: elapsed,
              attribution: {
                layer: 'transport',
                reason: 'request_timeout',
                code: timeoutError.code,
                retryable: true,
              },
            })
            await sleep(retryBackoffMs * attempt)
            continue
          }
          options.onLifecycle?.({
            stage: 'failure',
            requestId,
            path,
            url,
            method,
            feature: options.traceContext?.feature,
            action: options.traceContext?.action,
            attempt,
            maxRetries,
            durationMs: elapsed,
            attribution: {
              layer: 'transport',
              reason: 'request_timeout',
              code: timeoutError.code,
              retryable: true,
            },
          })
          throw timeoutError
        }
        if (error instanceof ApiClientError) {
          throw error
        }
        const networkError = new ApiClientError({
          code: 'NETWORK',
          message: error instanceof Error ? error.message : '网络异常',
          retryable: true,
        })
        const elapsed = Date.now() - requestStartedAt
        if (attempt < maxRetries) {
          attempt += 1
          options.onLifecycle?.({
            stage: 'retry',
            requestId,
            path,
            url,
            method,
            feature: options.traceContext?.feature,
            action: options.traceContext?.action,
            attempt,
            maxRetries,
            durationMs: elapsed,
            attribution: {
              layer: 'transport',
              reason: 'network_exception',
              code: networkError.code,
              retryable: true,
            },
          })
          await sleep(retryBackoffMs * attempt)
          continue
        }
        options.onLifecycle?.({
          stage: 'failure',
          requestId,
          path,
          url,
          method,
          feature: options.traceContext?.feature,
          action: options.traceContext?.action,
          attempt,
          maxRetries,
          durationMs: elapsed,
          attribution: {
            layer: 'transport',
            reason: 'network_exception',
            code: networkError.code,
            retryable: true,
          },
        })
        throw networkError
      } finally {
        clearTimeout(timeoutId)
      }
    }
    throw new ApiClientError({
      code: 'UNKNOWN',
      message: '请求失败',
      retryable: false,
    })
  }

  async get<T>(path: string, options: Omit<RequestOptions, 'method' | 'body'> = {}): Promise<T> {
    return this.request<T>(path, {
      ...options,
      method: 'GET',
    })
  }
}

export const apiClient = new ApiClient({
  baseUrl: appEnv.apiBaseUrl,
  timeoutMs: appEnv.apiTimeoutMs,
  retryCount: appEnv.apiRetryCount,
})
