const parseNumberEnv = (value: string | undefined, fallback: number, min: number): number => {
  if (!value) {
    return fallback
  }
  const parsed = Number(value)
  if (!Number.isFinite(parsed)) {
    return fallback
  }
  if (parsed < min) {
    return min
  }
  return parsed
}

export const appEnv = {
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8082',
  apiTimeoutMs: parseNumberEnv(import.meta.env.VITE_API_TIMEOUT_MS, 5000, 1000),
  apiRetryCount: parseNumberEnv(import.meta.env.VITE_API_RETRY_COUNT, 1, 0),
  notificationStreamToken: import.meta.env.VITE_NOTIFICATION_STREAM_TOKEN || '',
}
