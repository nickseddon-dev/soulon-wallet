export const extensionRoutes = {
  root: '/popup',

  tabs: '/popup/tabs',
  tokens: '/popup/tokens',
  collectibles: '/popup/collectibles',
  activity: '/popup/activity',

  tokenDetail: '/popup/tokens/detail',
  activityDetail: '/popup/activity/detail',
  collectiblesDetail: '/popup/collectibles/detail',
  collectiblesCollection: '/popup/collectibles/collection',

  search: '/popup/search',

  sendToken: '/popup/send/token',
  sendAddress: '/popup/send/address',
  sendAmount: '/popup/send/amount',
  sendConfirm: '/popup/send/confirm',

  receive: '/popup/receive',
  settings: '/popup/settings',

  unlock: '/popup/unlock',
} as const

export type ExtensionRouteKey = keyof typeof extensionRoutes
