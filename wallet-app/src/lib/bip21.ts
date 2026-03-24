import {
  BIP21_ERROR_CODES,
  generateBip21Uri,
  parseBip21Uri,
  type Bip21ErrorCode,
} from '../../../soulon-wallet/dist/core/bip21.js'
import { SoulonWalletError } from '../../../soulon-wallet/dist/core/errors.js'

export type Bip21FormInput = {
  address: string
  amount: string
  memo: string
}

const BIP21_ERROR_LABELS: Record<Bip21ErrorCode, string> = {
  [BIP21_ERROR_CODES.INVALID_URI]: 'URI 格式无效',
  [BIP21_ERROR_CODES.INVALID_SCHEME]: '协议头无效',
  [BIP21_ERROR_CODES.INVALID_ADDRESS]: '地址无效',
  [BIP21_ERROR_CODES.INVALID_AMOUNT]: '金额无效',
}

const buildUiErrorMessage = (code: string, fallback: string): string => {
  if (code in BIP21_ERROR_LABELS) {
    return `BIP-21 输入有误：${BIP21_ERROR_LABELS[code as Bip21ErrorCode]}`
  }
  return `BIP-21 输入有误：${fallback}`
}

export const toUnifiedBip21Error = (error: unknown): string => {
  if (error instanceof SoulonWalletError) {
    return buildUiErrorMessage(error.code, error.message)
  }
  if (error instanceof Error) {
    return buildUiErrorMessage('UNKNOWN', error.message)
  }
  return buildUiErrorMessage('UNKNOWN', '未知错误')
}

export const createBip21PaymentUri = (input: Bip21FormInput): string => {
  return generateBip21Uri({
    address: input.address,
    amount: input.amount.trim() ? input.amount : undefined,
    memo: input.memo.trim() ? input.memo : undefined,
  })
}

export const parseBip21Input = (uri: string): Bip21FormInput => {
  const parsed = parseBip21Uri(uri)
  return {
    address: parsed.address,
    amount: parsed.amount ?? '',
    memo: parsed.memo ?? '',
  }
}
