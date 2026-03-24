export const walletSemanticErrorCodes = [
  'INVALID_ARGUMENT',
  'INSUFFICIENT_FUNDS',
  'OUT_OF_GAS',
  'INVALID_SEQUENCE',
  'UNAUTHORIZED',
  'CHAIN_UNAVAILABLE',
  'NOT_FOUND',
  'METHOD_NOT_ALLOWED',
  'TX_REJECTED',
  'INTERNAL_ERROR',
] as const

export type WalletSemanticErrorCode = (typeof walletSemanticErrorCodes)[number]
export type TransportErrorCode = 'TIMEOUT' | 'NETWORK' | 'HTTP_ERROR' | 'PARSE_ERROR' | 'UNKNOWN'
export type ApiErrorCode = TransportErrorCode | WalletSemanticErrorCode

const walletSemanticErrorCodeSet = new Set<string>(walletSemanticErrorCodes)

const walletSemanticErrorMessages: Record<WalletSemanticErrorCode, string> = {
  INVALID_ARGUMENT: '请求参数不合法，请检查后重试。',
  INSUFFICIENT_FUNDS: '余额不足，请补充资产后重试。',
  OUT_OF_GAS: 'Gas 不足，请提高手续费后重试。',
  INVALID_SEQUENCE: '账户序列号不一致，请刷新状态后重试。',
  UNAUTHORIZED: '当前请求未授权，请重新登录。',
  CHAIN_UNAVAILABLE: '链端暂不可用，请稍后重试。',
  NOT_FOUND: '请求资源不存在或已删除。',
  METHOD_NOT_ALLOWED: '当前接口不支持该请求方法。',
  TX_REJECTED: '交易被链端拒绝，请检查交易参数。',
  INTERNAL_ERROR: '服务内部异常，请稍后重试。',
}

export class ApiClientError extends Error {
  readonly code: ApiErrorCode
  readonly status?: number
  readonly retryable: boolean

  constructor(input: { code: ApiErrorCode; message: string; status?: number; retryable: boolean }) {
    super(input.message)
    this.name = 'ApiClientError'
    this.code = input.code
    this.status = input.status
    this.retryable = input.retryable
  }
}

export const isWalletSemanticErrorCode = (code: string): code is WalletSemanticErrorCode => {
  return walletSemanticErrorCodeSet.has(code)
}

export const resolveWalletSemanticErrorMessage = (
  code: WalletSemanticErrorCode,
  message?: string,
): string => {
  const normalizedMessage = message?.trim()
  if (normalizedMessage) {
    return normalizedMessage
  }
  return walletSemanticErrorMessages[code]
}

export const isSessionInvalidError = (error: unknown): error is ApiClientError => {
  if (!(error instanceof ApiClientError)) {
    return false
  }
  if (error.code === 'UNAUTHORIZED') {
    return true
  }
  return error.code === 'HTTP_ERROR' && (error.status === 401 || error.status === 403)
}
