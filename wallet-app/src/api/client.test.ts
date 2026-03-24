import { afterEach, describe, expect, it, vi } from 'vitest'
import { ApiClient } from './client'
import { ApiClientError } from './errors'

const createMockResponse = (status: number, payload: unknown): Response => {
  return {
    ok: status >= 200 && status < 300,
    status,
    json: vi.fn().mockResolvedValue(payload),
  } as unknown as Response
}

describe('ApiClient structured error mapping', () => {
  const fetchMock = vi.fn()
  const client = new ApiClient({
    baseUrl: 'http://127.0.0.1:8082',
    timeoutMs: 2000,
    retryCount: 0,
  })

  afterEach(() => {
    fetchMock.mockReset()
    vi.unstubAllGlobals()
  })

  it('解析后端错误码并映射为语义错误', async () => {
    fetchMock.mockResolvedValue(
      createMockResponse(400, {
        code: 'INSUFFICIENT_FUNDS',
        message: 'insufficient funds',
        retryable: false,
      }),
    )
    vi.stubGlobal('fetch', fetchMock)

    await expect(client.get('/v1/chain/txs/ABC')).rejects.toSatisfy((error: unknown) => {
      expect(error).toBeInstanceOf(ApiClientError)
      const requestError = error as ApiClientError
      expect(requestError.code).toBe('INSUFFICIENT_FUNDS')
      expect(requestError.message).toBe('insufficient funds')
      expect(requestError.retryable).toBe(false)
      return true
    })
  })

  it('未知错误码回退 HTTP_ERROR', async () => {
    fetchMock.mockResolvedValue(
      createMockResponse(418, {
        code: 'UNKNOWN_SERVER_CODE',
        message: 'teapot',
      }),
    )
    vi.stubGlobal('fetch', fetchMock)

    await expect(client.get('/v1/health')).rejects.toSatisfy((error: unknown) => {
      expect(error).toBeInstanceOf(ApiClientError)
      const requestError = error as ApiClientError
      expect(requestError.code).toBe('HTTP_ERROR')
      expect(requestError.message).toBe('teapot')
      return true
    })
  })
})
