export type PopupTabKey = 'tokens' | 'collectibles' | 'activity'

export type CloseBehavior = 'go-back' | 'pop-root-once' | 'pop-root-twice' | 'reset'

export type PopupScreenId =
  | 'Tabs'
  | 'TokenDetail'
  | 'ActivityDetail'
  | 'CollectiblesDetail'
  | 'CollectiblesCollection'
  | 'Search'
  | 'WalletDrawer'
  | 'AvatarPopover'
  | 'SendToken'
  | 'SendAddress'
  | 'SendAmount'
  | 'SendConfirm'
  | 'Receive'
  | 'Settings'
  | 'Unlock'

export type PopupPresentation = 'push' | 'modal' | 'transparentModal'

export type PopupRoute = {
  id: PopupScreenId
  presentation: PopupPresentation
  title?: string
  showClose?: boolean
  closeBehavior?: CloseBehavior
  params?: Record<string, unknown>
}

export type WalletSummary = {
  id: string
  name: string
  address: string
}

export type TokenListItem = {
  id: string
  symbol: string
  title: string
  description: string
  meta: string
  status: 'default' | 'success' | 'warning' | 'danger'
}

export type ActivityListItem = {
  id: string
  title: string
  description: string
  meta: string
  status: 'default' | 'success' | 'warning' | 'danger'
}

export type CollectibleListItem = {
  id: string
  title: string
  description: string
  meta: string
  status: 'default' | 'success' | 'warning' | 'danger'
}

export type SendDraft = {
  tokenId: string
  to: string
  amount: string
  memo: string
}

export type SendDraftErrors = Partial<Record<keyof SendDraft, string>>

export type PopupState = {
  activeTab: PopupTabKey
  stack: PopupRoute[]
  wallets: WalletSummary[]
  activeWalletId: string
  isLocked: boolean

  searchInputValue: string
  searchKeyword: string

  sendDraft: SendDraft
  sendDraftErrors: SendDraftErrors
  sendFeedback: string
  sendFeedbackTone: 'neutral' | 'error' | 'success'
  sendSubmitting: boolean
}
