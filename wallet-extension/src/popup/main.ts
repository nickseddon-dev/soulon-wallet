import '../styles/base.css'
import '../styles/popup.css'

import { mountPopup } from './popup_controller'

const root = document.querySelector<HTMLDivElement>('#popup-root')

if (!root) {
  throw new Error('popup root not found')
}

mountPopup(root)

