import type { PopupRoute, PopupState, PopupTabKey, WalletSummary } from './popup_types'

type Listener = (state: PopupState) => void

const defaultWallets: WalletSummary[] = [
  { id: 'wallet-1', name: 'Account 1', address: 'cosmos1k8pa9c38g4nq2f08d63a9gn6vdg8v3duaw2sp4' },
  { id: 'wallet-2', name: 'Account 2', address: 'cosmos1l3l7m9q2f08d63a9gn6vdg8v3duaw2sp4k8pa9c' },
]

const rootRoute: PopupRoute = {
  id: 'Tabs',
  presentation: 'push',
}

let state: PopupState = {
  activeTab: 'tokens',
  stack: [rootRoute],
  wallets: defaultWallets,
  activeWalletId: defaultWallets[0].id,
  isLocked: false,

  searchInputValue: '',
  searchKeyword: '',

  sendDraft: {
    tokenId: 'token-1',
    to: '',
    amount: '',
    memo: '',
  },
  sendDraftErrors: {},
  sendFeedback: '',
  sendFeedbackTone: 'neutral',
  sendSubmitting: false,
}

const listeners = new Set<Listener>()

export const popupStore = {
  getState(): PopupState {
    return state
  },
  setState(updater: (prev: PopupState) => PopupState): void {
    state = updater(state)
    listeners.forEach((listener) => listener(state))
  },
  subscribe(listener: Listener): () => void {
    listeners.add(listener)
    return () => {
      listeners.delete(listener)
    }
  },
}

export const popupActions = {
  setActiveTab(tab: PopupTabKey): void {
    popupStore.setState((prev) => ({ ...prev, activeTab: tab }))
  },
  push(route: PopupRoute): void {
    popupStore.setState((prev) => ({ ...prev, stack: [...prev.stack, route] }))
  },
  replace(route: PopupRoute): void {
    popupStore.setState((prev) => {
      if (prev.stack.length <= 1) {
        return { ...prev, stack: [rootRoute, route] }
      }
      return { ...prev, stack: [...prev.stack.slice(0, -1), route] }
    })
  },
  pop(): void {
    popupStore.setState((prev) => {
      if (prev.stack.length <= 1) {
        return prev
      }
      return { ...prev, stack: prev.stack.slice(0, -1) }
    })
  },
  popToRoot(): void {
    popupStore.setState((prev) => ({ ...prev, stack: [prev.stack[0]] }))
  },
  popToBase(): void {
    popupStore.setState((prev) => {
      let baseIndex = 0
      for (let i = prev.stack.length - 1; i >= 0; i--) {
        if (prev.stack[i].presentation === 'push') {
          baseIndex = i
          break
        }
      }
      return { ...prev, stack: prev.stack.slice(0, baseIndex + 1) }
    })
  },
  resetToRoot(): void {
    popupStore.setState((prev) => ({ ...prev, stack: [prev.stack[0]] }))
  },
  setLocked(isLocked: boolean): void {
    popupStore.setState((prev) => ({ ...prev, isLocked }))
  },
  setActiveWallet(id: string): void {
    popupStore.setState((prev) => ({ ...prev, activeWalletId: id }))
  },
  setSearchInput(value: string): void {
    const keyword = value.trim().toLowerCase()
    popupStore.setState((prev) => ({
      ...prev,
      searchInputValue: value,
      searchKeyword: keyword,
    }))
  },
  resetSendFeedback(): void {
    popupStore.setState((prev) => ({
      ...prev,
      sendDraftErrors: {},
      sendFeedback: '',
      sendFeedbackTone: 'neutral',
    }))
  },
  updateSendDraft(key: keyof PopupState['sendDraft'], value: string): void {
    popupStore.setState((prev) => ({
      ...prev,
      sendDraft: {
        ...prev.sendDraft,
        [key]: value,
      },
    }))
  },
  setSendSubmitting(value: boolean): void {
    popupStore.setState((prev) => ({ ...prev, sendSubmitting: value }))
  },
  setSendFeedback(message: string, tone: PopupState['sendFeedbackTone']): void {
    popupStore.setState((prev) => ({ ...prev, sendFeedback: message, sendFeedbackTone: tone }))
  },
  setSendErrors(errors: PopupState['sendDraftErrors']): void {
    popupStore.setState((prev) => ({ ...prev, sendDraftErrors: errors }))
  },
}
