import { extensionRoutes } from './routes'
import type {
  ActivityListItem,
  CollectibleListItem,
  PopupRoute,
  PopupState,
  PopupTabKey,
  SendDraftErrors,
  TokenListItem,
  WalletSummary,
} from './popup_types'

export const tokenItems: TokenListItem[] = [
  {
    id: 'token-1',
    symbol: 'SOUL',
    title: 'SOUL',
    description: '可用余额 1,243.66',
    meta: '24h +2.8%',
    status: 'success',
  },
  {
    id: 'token-2',
    symbol: 'stSOUL',
    title: 'stSOUL',
    description: '质押余额 325.24',
    meta: '预计年化 11.2%',
    status: 'default',
  },
  {
    id: 'token-3',
    symbol: 'uUSDC',
    title: 'uUSDC',
    description: '可用余额 845.20',
    meta: '跨链通道 channel-8',
    status: 'warning',
  },
]

export const activityItems: ActivityListItem[] = [
  {
    id: 'activity-1',
    title: '发送成功',
    description: '向 cosmos1...k2r9 转账 8.50 SOUL',
    meta: '2 分钟前 · Tx#B34B',
    status: 'success',
  },
  {
    id: 'activity-2',
    title: '待确认',
    description: '向 osmo1...tc94 转账 32.00 uUSDC',
    meta: '刚刚 · 等待区块确认',
    status: 'warning',
  },
  {
    id: 'activity-3',
    title: '失败重试',
    description: 'Gas 估算不足，交易未上链',
    meta: '12 分钟前 · 可重试',
    status: 'danger',
  },
]

export const collectibleItems: CollectibleListItem[] = [
  {
    id: 'collectible-1',
    title: 'Mad Lads #1844',
    description: 'Collection: Mad Lads',
    meta: 'Floor 64.1 SOL',
    status: 'warning',
  },
  {
    id: 'collectible-2',
    title: 'xNFT Badge',
    description: 'Collection: Backpack',
    meta: 'Verified',
    status: 'default',
  },
  {
    id: 'collectible-3',
    title: 'Genesis Access',
    description: 'Collection: Coral',
    meta: 'Unlisted',
    status: 'success',
  },
]

const escapeHtml = (value: string): string =>
  value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;')

const getStatusClass = (status: 'default' | 'success' | 'warning' | 'danger'): string => {
  if (status === 'success') return 'status-success'
  if (status === 'warning') return 'status-warning'
  if (status === 'danger') return 'status-danger'
  return ''
}

const formatAddressShort = (address: string): string => {
  if (address.length <= 12) return address
  return `${address.slice(0, 8)}...${address.slice(-4)}`
}

export const getBaseAndOverlay = (
  stack: PopupRoute[],
): { base: PopupRoute; overlay: PopupRoute[]; transparentOverlay: PopupRoute[] } => {
  const baseIndex = (() => {
    for (let i = stack.length - 1; i >= 0; i--) {
      if (stack[i].presentation === 'push') return i
    }
    return 0
  })()
  const base = stack[baseIndex]
  const overlay = stack.slice(baseIndex + 1).filter((route) => route.presentation === 'modal')
  const transparentOverlay = stack.slice(baseIndex + 1).filter((route) => route.presentation === 'transparentModal')
  return { base, overlay, transparentOverlay }
}

export const getTabTitle = (tab: PopupTabKey): string => {
  if (tab === 'tokens') return 'Tokens'
  if (tab === 'collectibles') return 'Collectibles'
  return 'Activity'
}

export const renderAppShell = (state: PopupState, base: PopupRoute, overlay: PopupRoute[], transparent: PopupRoute[]): string => {
  const activeWallet = state.wallets.find((wallet) => wallet.id === state.activeWalletId) ?? state.wallets[0]
  const baseContent = renderBaseContent(state, base, activeWallet)
  const overlayContent = overlay.length ? renderModal(state, overlay[overlay.length - 1], activeWallet) : ''
  const transparentContent = transparent.length ? renderTransparentModal(state, transparent[transparent.length - 1]) : ''
  return `
    <div class="popup-root">
      ${baseContent}
      ${overlayContent}
      ${transparentContent}
    </div>
  `
}

const renderBaseContent = (state: PopupState, base: PopupRoute, activeWallet: WalletSummary): string => {
  if (state.isLocked) {
    return renderLockedScreen()
  }
  if (base.id === 'TokenDetail') return renderTokenDetailScreen(state, activeWallet)
  if (base.id === 'ActivityDetail') return renderActivityDetailScreen(state)
  if (base.id === 'CollectiblesDetail') return renderCollectiblesDetailScreen(state)
  if (base.id === 'CollectiblesCollection') return renderCollectiblesCollectionScreen(state)
  return renderTabsScreen(state, activeWallet)
}

const renderLockedScreen = (): string => {
  return `
    <div class="popup-shell">
      <header class="popup-header">
        <div class="popup-title-block">
          <p class="popup-eyebrow">Wallet Extension</p>
          <h1 class="popup-title">Soulon Wallet</h1>
          <p class="popup-subtitle">当前路径：${extensionRoutes.unlock}</p>
        </div>
      </header>
      <section class="ext-card">
        <div class="page-head">
          <h2>解锁钱包</h2>
        </div>
        <div class="page-scroll">
          <label class="field-block">
            密码
            <input class="ext-input" data-field="unlock" type="password" placeholder="输入密码" />
          </label>
          <div class="popup-action-row">
            <button class="ext-button" data-action="unlock">解锁</button>
          </div>
        </div>
      </section>
    </div>
  `
}

const renderTabsScreen = (state: PopupState, activeWallet: WalletSummary): string => {
  const tab = state.activeTab
  const currentItems = getTabItems(state)
  const routeText = tab === 'tokens' ? extensionRoutes.tokens : tab === 'collectibles' ? extensionRoutes.collectibles : extensionRoutes.activity
  return `
    <div class="popup-shell">
      ${renderRootHeader(activeWallet)}
      ${renderTopTabs(tab)}
      ${renderSearchHint(state)}
      ${renderPrimaryActions()}
      <section class="ext-card">
        <div class="page-head">
          <h2>${getTabTitle(tab)}</h2>
          <span class="ext-badge">${currentItems.length} 条</span>
        </div>
        <div class="page-scroll">
          ${renderItemList(tab, currentItems)}
        </div>
      </section>
      <p class="footer-note">当前路径：${routeText}</p>
    </div>
  `
}

const renderRootHeader = (activeWallet: WalletSummary): string => {
  return `
    <header class="popup-header">
      <button class="icon-button" data-action="avatar" aria-label="avatar">
        <span class="avatar-circle">A</span>
      </button>
      <button class="wallet-button" data-action="wallet-drawer" aria-label="wallet">
        <span class="wallet-name">${escapeHtml(activeWallet.name)}</span>
        <span class="wallet-address">${escapeHtml(formatAddressShort(activeWallet.address))}</span>
      </button>
      <button class="icon-button" data-action="settings" aria-label="settings">
        <span class="icon-dot"></span>
      </button>
    </header>
  `
}

const renderTopTabs = (activeTab: PopupTabKey): string => {
  const tabs: { key: PopupTabKey; label: string }[] = [
    { key: 'tokens', label: 'Tokens' },
    { key: 'collectibles', label: 'Collectibles' },
    { key: 'activity', label: 'Activity' },
  ]
  return `
    <div class="tab-nav" role="tablist">
      ${tabs
        .map((tab) => {
          const isActive = tab.key === activeTab
          return `<button class="tab-item ${isActive ? 'active' : ''}" role="tab" aria-selected="${isActive}" data-tab="${tab.key}">${tab.label}</button>`
        })
        .join('')}
    </div>
  `
}

const renderSearchHint = (state: PopupState): string => {
  const hint = state.searchKeyword ? `已筛选 ${getSearchResults(state).length} 条结果` : '按 / 键打开搜索'
  return `<p class="search-feedback">${hint}</p>`
}

const renderPrimaryActions = (): string => {
  return `
    <div class="popup-action-row">
      <button class="ext-button" data-action="open-send">发送</button>
      <button class="ext-button ghost" data-action="open-receive">接收</button>
    </div>
  `
}

const renderItemList = (tab: PopupTabKey, items: Array<TokenListItem | ActivityListItem | CollectibleListItem>): string => {
  if (!items.length) {
    return `<div class="empty-state ext-card">暂无数据</div>`
  }
  return items
    .map((item) => {
      const dataAttrs =
        tab === 'tokens'
          ? `data-action="open-token-detail" data-id="${item.id}"`
          : tab === 'activity'
            ? `data-action="open-activity-detail" data-id="${item.id}"`
            : `data-action="open-collectible-detail" data-id="${item.id}"`
      return `
        <article class="ext-card clickable" ${dataAttrs}>
          <div class="item-row">
            <div>
              <p class="item-title">${escapeHtml(item.title)}</p>
              <p class="item-desc">${escapeHtml(item.description)}</p>
              <p class="item-meta">${escapeHtml(item.meta)}</p>
            </div>
            <span class="ext-badge ${getStatusClass(item.status)}">${item.status === 'default' ? '信息' : item.status}</span>
          </div>
        </article>
      `
    })
    .join('')
}

const renderTokenDetailScreen = (state: PopupState, activeWallet: WalletSummary): string => {
  const tokenId = String(state.stack[state.stack.length - 1].params?.id ?? '')
  const token = tokenItems.find((item) => item.id === tokenId) ?? tokenItems[0]
  return `
    <div class="popup-shell">
      ${renderHeaderWithBack(token.symbol)}
      <section class="ext-card">
        <div class="page-scroll">
          <div class="detail-head">
            <h2>${escapeHtml(token.title)}</h2>
            <p class="detail-sub">${escapeHtml(token.description)}</p>
            <p class="detail-meta">${escapeHtml(token.meta)}</p>
          </div>
          <div class="detail-grid">
            <div class="detail-row"><span>钱包</span><strong>${escapeHtml(activeWallet.name)}</strong></div>
            <div class="detail-row"><span>地址</span><strong>${escapeHtml(formatAddressShort(activeWallet.address))}</strong></div>
          </div>
        </div>
      </section>
    </div>
  `
}

const renderActivityDetailScreen = (state: PopupState): string => {
  const activityId = String(state.stack[state.stack.length - 1].params?.id ?? '')
  const activity = activityItems.find((item) => item.id === activityId) ?? activityItems[0]
  return `
    <div class="popup-shell">
      ${renderHeaderWithBack('Activity')}
      <section class="ext-card">
        <div class="page-scroll">
          <div class="detail-head">
            <h2>${escapeHtml(activity.title)}</h2>
            <p class="detail-sub">${escapeHtml(activity.description)}</p>
            <p class="detail-meta">${escapeHtml(activity.meta)}</p>
          </div>
          <div class="detail-grid">
            <div class="detail-row"><span>状态</span><strong>${escapeHtml(activity.status)}</strong></div>
            <div class="detail-row"><span>备注</span><strong>Mock Detail</strong></div>
          </div>
        </div>
      </section>
    </div>
  `
}

const renderCollectiblesDetailScreen = (_state: PopupState): string => {
  return `
    <div class="popup-shell">
      ${renderHeaderWithBack('Collectible')}
      <section class="ext-card">
        <div class="page-scroll">
          <div class="empty-state ext-card">收藏品详情暂以占位呈现</div>
        </div>
      </section>
    </div>
  `
}

const renderCollectiblesCollectionScreen = (_state: PopupState): string => {
  return `
    <div class="popup-shell">
      ${renderHeaderWithBack('Collection')}
      <section class="ext-card">
        <div class="page-scroll">
          <div class="empty-state ext-card">集合页暂以占位呈现</div>
        </div>
      </section>
    </div>
  `
}

const renderHeaderWithBack = (title: string, action: 'back' | 'send-prev' = 'back'): string => {
  return `
    <header class="popup-header simple">
      <button class="icon-button" data-action="${action}" aria-label="back">←</button>
      <div class="popup-title-inline">${escapeHtml(title)}</div>
      <div class="header-spacer"></div>
    </header>
  `
}

const renderHeaderWithClose = (title: string): string => {
  return `
    <header class="popup-header simple">
      <button class="icon-button" data-action="close" aria-label="close">✕</button>
      <div class="popup-title-inline">${escapeHtml(title)}</div>
      <div class="header-spacer"></div>
    </header>
  `
}

const renderModal = (state: PopupState, route: PopupRoute, activeWallet: WalletSummary): string => {
  return `
    <div class="ext-modal-mask modal-open" data-action="modal-mask">
      <div class="ext-modal" role="dialog" aria-modal="true">
        ${renderModalScreen(state, route, activeWallet)}
      </div>
    </div>
  `
}

const renderModalScreen = (state: PopupState, route: PopupRoute, activeWallet: WalletSummary): string => {
  if (route.id === 'WalletDrawer') {
    return `
      ${renderHeaderWithClose('Wallets')}
      <div class="modal-content">
        ${renderWalletDrawer(state.wallets, activeWallet.id)}
      </div>
    `
  }
  if (route.id === 'AvatarPopover') {
    return `
      ${renderHeaderWithClose('Account')}
      <div class="modal-content">
        <div class="modal-grid"><span>当前钱包</span><strong>${escapeHtml(activeWallet.name)}</strong></div>
        <div class="modal-actions">
          <button class="ext-button ghost" data-action="lock">锁定</button>
          <button class="ext-button" data-action="open-settings">设置</button>
        </div>
      </div>
    `
  }
  if (route.id === 'Settings') {
    return `
      ${renderHeaderWithClose('Settings')}
      <div class="modal-content">
        <div class="modal-grid"><span>Network</span><strong>Mainnet</strong></div>
        <div class="modal-grid"><span>Currency</span><strong>USD</strong></div>
        <div class="modal-actions">
          <button class="ext-button ghost" data-action="lock">锁定</button>
          <button class="ext-button" data-action="close">完成</button>
        </div>
      </div>
    `
  }
  if (route.id === 'Receive') {
    return `
      ${renderHeaderWithClose('Receive')}
      <div class="modal-content">
        <div class="modal-grid"><span>地址</span><strong>${escapeHtml(activeWallet.address)}</strong></div>
        <div class="modal-actions">
          <button class="ext-button ghost" data-action="copy-address">复制地址</button>
          <button class="ext-button" data-action="close">完成</button>
        </div>
      </div>
    `
  }
  if (route.id === 'SendToken') return renderSendTokenScreen(state)
  if (route.id === 'SendAddress') return renderSendAddressScreen(state)
  if (route.id === 'SendAmount') return renderSendAmountScreen(state)
  if (route.id === 'SendConfirm') return renderSendConfirmScreen(state)
  return `
    ${renderHeaderWithClose('Modal')}
    <div class="modal-content">
      <div class="empty-state ext-card">未实现的模态页面</div>
    </div>
  `
}

const renderWalletDrawer = (wallets: WalletSummary[], activeWalletId: string): string => {
  return `
    <div class="drawer-list">
      ${wallets
        .map((wallet) => {
          const selected = wallet.id === activeWalletId
          return `
            <button class="drawer-item ${selected ? 'active' : ''}" data-action="select-wallet" data-id="${wallet.id}">
              <span class="drawer-title">${escapeHtml(wallet.name)}</span>
              <span class="drawer-sub">${escapeHtml(formatAddressShort(wallet.address))}</span>
            </button>
          `
        })
        .join('')}
    </div>
  `
}

const validateSendDraft = (state: PopupState): SendDraftErrors => {
  const nextErrors: SendDraftErrors = {}
  const trimmedTo = state.sendDraft.to.trim().toLowerCase()
  const trimmedAmount = state.sendDraft.amount.trim()
  const trimmedMemo = state.sendDraft.memo.trim()
  if (!/^cosmos1[0-9a-z]{20,}$/.test(trimmedTo)) {
    nextErrors.to = '请输入有效 cosmos 地址（cosmos1...）'
  }
  if (!/^\d+(\.\d{1,6})?$/.test(trimmedAmount) || Number(trimmedAmount) <= 0) {
    nextErrors.amount = '请输入大于 0 的金额，最多 6 位小数'
  }
  if (trimmedMemo.length > 60) {
    nextErrors.memo = '备注需不超过 60 个字符'
  }
  return nextErrors
}

const renderSendTokenScreen = (state: PopupState): string => {
  return `
    ${renderHeaderWithClose('选择 Token')}
    <div class="modal-content">
      ${tokenItems
        .map((token) => {
          const selected = token.id === state.sendDraft.tokenId
          return `
            <button class="drawer-item ${selected ? 'active' : ''}" data-action="select-send-token" data-id="${token.id}">
              <span class="drawer-title">${escapeHtml(token.symbol)}</span>
              <span class="drawer-sub">${escapeHtml(token.description)}</span>
            </button>
          `
        })
        .join('')}
      <div class="modal-actions">
        <button class="ext-button ghost" data-action="close-send" data-close-behavior="reset">取消</button>
        <button class="ext-button" data-action="send-next" data-next="SendAddress">下一步</button>
      </div>
    </div>
  `
}

const renderSendAddressScreen = (state: PopupState): string => {
  const error = state.sendDraftErrors.to
  return `
    ${renderHeaderWithBack('收款地址', 'send-prev')}
    <div class="modal-content">
      <label class="field-block">
        收款地址
        <input id="send-to-input" class="ext-input ${error ? 'field-error' : ''}" data-field="send-to" value="${escapeHtml(state.sendDraft.to)}" />
        ${error ? `<span class="field-feedback error">${escapeHtml(error)}</span>` : ''}
      </label>
      ${renderSendFeedback(state)}
      <div class="modal-actions">
        <button class="ext-button ghost" data-action="send-prev">返回</button>
        <button class="ext-button" data-action="send-next" data-next="SendAmount">下一步</button>
      </div>
    </div>
  `
}

const renderSendAmountScreen = (state: PopupState): string => {
  const amountError = state.sendDraftErrors.amount
  const memoError = state.sendDraftErrors.memo
  return `
    ${renderHeaderWithBack('填写金额', 'send-prev')}
    <div class="modal-content">
      <label class="field-block">
        金额
        <input id="send-amount-input" class="ext-input ${amountError ? 'field-error' : ''}" data-field="send-amount" value="${escapeHtml(state.sendDraft.amount)}" />
        ${amountError ? `<span class="field-feedback error">${escapeHtml(amountError)}</span>` : ''}
      </label>
      <label class="field-block">
        备注
        <input id="send-memo-input" class="ext-input ${memoError ? 'field-error' : ''}" data-field="send-memo" value="${escapeHtml(state.sendDraft.memo)}" />
        ${memoError ? `<span class="field-feedback error">${escapeHtml(memoError)}</span>` : ''}
      </label>
      ${renderSendFeedback(state)}
      <div class="modal-actions">
        <button class="ext-button ghost" data-action="send-prev">返回</button>
        <button class="ext-button" data-action="send-next" data-next="SendConfirm">确认</button>
      </div>
    </div>
  `
}

const renderSendConfirmScreen = (state: PopupState): string => {
  const token = tokenItems.find((item) => item.id === state.sendDraft.tokenId) ?? tokenItems[0]
  return `
    ${renderHeaderWithBack('确认发送', 'send-prev')}
    <div class="modal-content">
      <div class="modal-grid"><span>Token</span><strong>${escapeHtml(token.symbol)}</strong></div>
      <div class="modal-grid"><span>收款方</span><strong>${escapeHtml(formatAddressShort(state.sendDraft.to))}</strong></div>
      <div class="modal-grid"><span>金额</span><strong>${escapeHtml(state.sendDraft.amount)}</strong></div>
      <div class="modal-grid"><span>备注</span><strong>${escapeHtml(state.sendDraft.memo || '-')}</strong></div>
      ${renderSendFeedback(state)}
      <div class="modal-actions">
        <button class="ext-button ghost" data-action="send-prev">返回修改</button>
        <button class="ext-button" data-action="send-submit" ${state.sendSubmitting ? 'disabled' : ''}>${state.sendSubmitting ? '广播中...' : '确认发送'}</button>
      </div>
    </div>
  `
}

const renderSendFeedback = (state: PopupState): string => {
  if (!state.sendFeedback) return ''
  const cls = state.sendFeedbackTone === 'error' ? 'error' : state.sendFeedbackTone === 'success' ? 'success' : ''
  return `<div class="form-feedback ${cls}">${escapeHtml(state.sendFeedback)}</div>`
}

const renderTransparentModal = (state: PopupState, route: PopupRoute): string => {
  if (route.id !== 'Search') return ''
  const results = getSearchResults(state)
  return `
    <div class="ext-modal-mask modal-transparent" data-action="search-mask">
      <div class="ext-modal transparent" role="dialog" aria-modal="true">
        ${renderHeaderWithClose('Search')}
        <div class="modal-content">
          <label class="field-block">
            搜索
            <input id="search-input" class="ext-input" data-field="search" value="${escapeHtml(state.searchInputValue)}" placeholder="Search tokens, collectibles, activity" />
          </label>
          <div class="page-scroll">
            ${results.length ? renderSearchResults(results) : `<div class="empty-state ext-card">无匹配结果</div>`}
          </div>
        </div>
      </div>
    </div>
  `
}

const getSearchResults = (state: PopupState): Array<TokenListItem | ActivityListItem | CollectibleListItem> => {
  const keyword = state.searchKeyword
  if (!keyword) return []
  const bag = [...tokenItems, ...collectibleItems, ...activityItems]
  return bag.filter((item) => `${item.title} ${item.description} ${item.meta}`.toLowerCase().includes(keyword))
}

const renderSearchResults = (results: Array<TokenListItem | ActivityListItem | CollectibleListItem>): string => {
  return results
    .map((item) => {
      return `
        <article class="ext-card">
          <div class="item-row">
            <div>
              <p class="item-title">${escapeHtml(item.title)}</p>
              <p class="item-desc">${escapeHtml(item.description)}</p>
              <p class="item-meta">${escapeHtml(item.meta)}</p>
            </div>
          </div>
        </article>
      `
    })
    .join('')
}

const getTabItems = (state: PopupState): Array<TokenListItem | ActivityListItem | CollectibleListItem> => {
  if (state.activeTab === 'tokens') return tokenItems
  if (state.activeTab === 'collectibles') return collectibleItems
  return activityItems
}

export const popupKeyboardShortcuts = {
  shouldHandleSlash(event: KeyboardEvent): boolean {
    if (event.key !== '/') return false
    const target = event.target as HTMLElement | null
    if (target?.tagName === 'INPUT' || target?.tagName === 'TEXTAREA') return false
    return true
  },
  isEscape(event: KeyboardEvent): boolean {
    return event.key === 'Escape'
  },
}

export const sendFlow = {
  validate(state: PopupState): SendDraftErrors {
    return validateSendDraft(state)
  },
}
