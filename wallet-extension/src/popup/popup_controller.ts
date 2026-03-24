import { popupActions, popupStore } from './popup_store'
import { extensionRoutes } from './routes'
import { getBaseAndOverlay, popupKeyboardShortcuts, renderAppShell, sendFlow, tokenItems } from './popup_screens'
import type { CloseBehavior, PopupRoute, PopupScreenId } from './popup_types'

export function mountPopup(root: HTMLDivElement): void {
  const unsubscribe = popupStore.subscribe((state) => {
    const { base, overlay, transparentOverlay } = getBaseAndOverlay(state.stack)
    root.innerHTML = renderAppShell(state, base, overlay, transparentOverlay)
    bindEvents(root)
    bindFocus(root)
  })

  const initial = popupStore.getState()
  const { base, overlay, transparentOverlay } = getBaseAndOverlay(initial.stack)
  root.innerHTML = renderAppShell(initial, base, overlay, transparentOverlay)
  bindEvents(root)
  bindFocus(root)

  window.addEventListener('keydown', (event) => {
    const state = popupStore.getState()
    const { transparentOverlay } = getBaseAndOverlay(state.stack)
    if (popupKeyboardShortcuts.shouldHandleSlash(event)) {
      event.preventDefault()
      openSearch()
      return
    }
    if (popupKeyboardShortcuts.isEscape(event)) {
      if (transparentOverlay.length) {
        event.preventDefault()
        closeTop()
        return
      }
      const hasModal = state.stack.some((route) => route.presentation === 'modal')
      if (hasModal) {
        event.preventDefault()
        closeTop()
      }
    }
  })

  window.addEventListener('beforeunload', () => {
    unsubscribe()
  })
}

function bindFocus(root: HTMLDivElement): void {
  const searchInput = root.querySelector<HTMLInputElement>('#search-input')
  if (searchInput && document.activeElement !== searchInput) {
    window.setTimeout(() => searchInput.focus(), 0)
    return
  }
  const sendTo = root.querySelector<HTMLInputElement>('#send-to-input')
  if (sendTo && document.activeElement !== sendTo) {
    window.setTimeout(() => sendTo.focus(), 0)
    return
  }
}

function bindEvents(root: HTMLDivElement): void {
  root.querySelectorAll<HTMLButtonElement>('[data-tab]').forEach((element) => {
    element.addEventListener('click', () => {
      const tab = element.dataset.tab as any
      if (tab === 'tokens' || tab === 'collectibles' || tab === 'activity') {
        popupActions.setActiveTab(tab)
      }
    })
  })

  root.querySelectorAll<HTMLElement>('[data-action="open-token-detail"]').forEach((element) => {
    element.addEventListener('click', () => {
      const id = element.getAttribute('data-id') ?? ''
      popupActions.push({ id: 'TokenDetail', presentation: 'push', params: { id }, title: 'Token' })
    })
  })

  root.querySelectorAll<HTMLElement>('[data-action="open-activity-detail"]').forEach((element) => {
    element.addEventListener('click', () => {
      const id = element.getAttribute('data-id') ?? ''
      popupActions.push({ id: 'ActivityDetail', presentation: 'push', params: { id }, title: 'Activity' })
    })
  })

  root.querySelectorAll<HTMLElement>('[data-action="open-collectible-detail"]').forEach((element) => {
    element.addEventListener('click', () => {
      popupActions.push({ id: 'CollectiblesDetail', presentation: 'push', title: 'Collectible' })
    })
  })

  root.querySelectorAll<HTMLButtonElement>('[data-action="back"]').forEach((element) => {
    element.addEventListener('click', () => {
      popupActions.pop()
    })
  })

  root.querySelectorAll<HTMLButtonElement>('[data-action="close"]').forEach((element) => {
    element.addEventListener('click', () => closeTop())
  })

  root.querySelectorAll<HTMLButtonElement>('[data-action="settings"]').forEach((element) => {
    element.addEventListener('click', () => {
      popupActions.push({ id: 'Settings', presentation: 'modal', title: 'Settings', showClose: true })
    })
  })

  root.querySelectorAll<HTMLButtonElement>('[data-action="wallet-drawer"]').forEach((element) => {
    element.addEventListener('click', () => {
      popupActions.push({ id: 'WalletDrawer', presentation: 'modal', title: 'Wallets', showClose: true })
    })
  })

  root.querySelectorAll<HTMLButtonElement>('[data-action="avatar"]').forEach((element) => {
    element.addEventListener('click', () => {
      popupActions.push({ id: 'AvatarPopover', presentation: 'modal', title: 'Account', showClose: true })
    })
  })

  root.querySelectorAll<HTMLButtonElement>('[data-action="open-settings"]').forEach((element) => {
    element.addEventListener('click', () => {
      closeTop()
      popupActions.push({ id: 'Settings', presentation: 'modal', title: 'Settings', showClose: true })
    })
  })

  root.querySelectorAll<HTMLButtonElement>('[data-action="lock"]').forEach((element) => {
    element.addEventListener('click', () => {
      popupActions.setLocked(true)
      popupActions.popToRoot()
    })
  })

  root.querySelectorAll<HTMLButtonElement>('[data-action="unlock"]').forEach((element) => {
    element.addEventListener('click', () => {
      popupActions.setLocked(false)
    })
  })

  root.querySelectorAll<HTMLButtonElement>('[data-action="open-receive"]').forEach((element) => {
    element.addEventListener('click', () => {
      popupActions.push({ id: 'Receive', presentation: 'modal', title: 'Receive', showClose: true })
    })
  })

  root.querySelectorAll<HTMLButtonElement>('[data-action="copy-address"]').forEach((element) => {
    element.addEventListener('click', async () => {
      const activeWallet = popupStore.getState().wallets.find((w) => w.id === popupStore.getState().activeWalletId)
      if (!activeWallet) return
      await navigator.clipboard.writeText(activeWallet.address)
    })
  })

  root.querySelectorAll<HTMLButtonElement>('[data-action="open-send"]').forEach((element) => {
    element.addEventListener('click', () => openSend())
  })

  root.querySelectorAll<HTMLDivElement>('[data-action="modal-mask"]').forEach((element) => {
    element.addEventListener('click', (event) => {
      if (event.target === element) {
        closeTop()
      }
    })
  })

  root.querySelectorAll<HTMLDivElement>('[data-action="search-mask"]').forEach((element) => {
    element.addEventListener('click', (event) => {
      if (event.target === element) {
        closeTop()
      }
    })
  })

  root.querySelectorAll<HTMLButtonElement>('[data-action="select-wallet"]').forEach((element) => {
    element.addEventListener('click', () => {
      const id = element.getAttribute('data-id') ?? ''
      popupActions.setActiveWallet(id)
      closeTop()
    })
  })

  root.querySelectorAll<HTMLInputElement>('[data-field="search"]').forEach((element) => {
    element.addEventListener('input', () => {
      popupActions.setSearchInput(element.value)
    })
  })

  root.querySelectorAll<HTMLInputElement>('[data-field="send-to"]').forEach((element) => {
    element.addEventListener('input', () => popupActions.updateSendDraft('to', element.value))
  })
  root.querySelectorAll<HTMLInputElement>('[data-field="send-amount"]').forEach((element) => {
    element.addEventListener('input', () => popupActions.updateSendDraft('amount', element.value))
  })
  root.querySelectorAll<HTMLInputElement>('[data-field="send-memo"]').forEach((element) => {
    element.addEventListener('input', () => popupActions.updateSendDraft('memo', element.value))
  })

  root.querySelectorAll<HTMLButtonElement>('[data-action="select-send-token"]').forEach((element) => {
    element.addEventListener('click', () => {
      const id = element.getAttribute('data-id') ?? tokenItems[0].id
      popupActions.updateSendDraft('tokenId', id)
    })
  })

  root.querySelectorAll<HTMLButtonElement>('[data-action="send-prev"]').forEach((element) => {
    element.addEventListener('click', () => {
      popupActions.resetSendFeedback()
      popupActions.pop()
    })
  })

  root.querySelectorAll<HTMLButtonElement>('[data-action="close-send"]').forEach((element) => {
    element.addEventListener('click', () => {
      const behavior = (element.getAttribute('data-close-behavior') ?? 'reset') as CloseBehavior
      closeByBehavior(behavior)
    })
  })

  root.querySelectorAll<HTMLButtonElement>('[data-action="send-next"]').forEach((element) => {
    element.addEventListener('click', () => {
      const next = (element.getAttribute('data-next') ?? '') as PopupScreenId
      goSendNext(next)
    })
  })

  root.querySelectorAll<HTMLButtonElement>('[data-action="send-submit"]').forEach((element) => {
    element.addEventListener('click', () => submitSend())
  })
}

function openSearch(): void {
  const state = popupStore.getState()
  const { transparentOverlay } = getBaseAndOverlay(state.stack)
  if (transparentOverlay.length && transparentOverlay[transparentOverlay.length - 1].id === 'Search') {
    return
  }
  popupActions.push({ id: 'Search', presentation: 'transparentModal', title: 'Search', showClose: true })
}

function openSend(): void {
  popupActions.resetSendFeedback()
  popupActions.push({ id: 'SendToken', presentation: 'modal', title: extensionRoutes.sendToken, showClose: true, closeBehavior: 'reset' })
}

function closeTop(): void {
  const state = popupStore.getState()
  if (state.stack.length <= 1) return
  const top = state.stack[state.stack.length - 1]
  if (top.showClose && top.closeBehavior) {
    closeByBehavior(top.closeBehavior)
    return
  }
  popupActions.pop()
}

function closeByBehavior(behavior: CloseBehavior): void {
  if (behavior === 'go-back') {
    popupActions.pop()
    return
  }
  if (behavior === 'pop-root-once' || behavior === 'pop-root-twice') {
    popupActions.popToBase()
    return
  }
  popupActions.popToBase()
}

function goSendNext(next: PopupScreenId): void {
  const state = popupStore.getState()
  popupActions.resetSendFeedback()
  const errors = sendFlow.validate(state)
  if (next === 'SendAddress') {
    popupActions.push({ id: 'SendAddress', presentation: 'modal', title: extensionRoutes.sendAddress, showClose: true, closeBehavior: 'pop-root-twice' })
    return
  }
  if (next === 'SendAmount') {
    if (errors.to) {
      popupActions.setSendErrors(errors)
      popupActions.setSendFeedback('字段校验未通过，请修正后继续。', 'error')
      return
    }
    popupActions.setSendErrors({ ...state.sendDraftErrors, to: undefined })
    popupActions.push({ id: 'SendAmount', presentation: 'modal', title: extensionRoutes.sendAmount, showClose: true, closeBehavior: 'pop-root-twice' })
    return
  }
  if (next === 'SendConfirm') {
    if (errors.to || errors.amount || errors.memo) {
      popupActions.setSendErrors(errors)
      popupActions.setSendFeedback('字段校验未通过，请修正后继续。', 'error')
      return
    }
    popupActions.setSendErrors({})
    popupActions.push({ id: 'SendConfirm', presentation: 'modal', title: extensionRoutes.sendConfirm, showClose: true, closeBehavior: 'pop-root-twice' })
  }
}

function submitSend(): void {
  const state = popupStore.getState()
  const errors = sendFlow.validate(state)
  if (errors.to || errors.amount || errors.memo) {
    popupActions.setSendErrors(errors)
    popupActions.setSendFeedback('字段校验未通过，请修正后继续。', 'error')
    return
  }
  popupActions.setSendSubmitting(true)
  popupActions.setSendFeedback('交易广播中，请稍候...', 'neutral')
  window.setTimeout(() => {
    popupActions.setSendSubmitting(false)
    popupActions.setSendFeedback('交易已提交，正在等待链上确认。', 'success')
  }, 760)
}
