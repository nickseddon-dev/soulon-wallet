import { fireEvent, render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { describe, expect, it } from 'vitest'
import { WebsiteDownloadPage } from './WebsiteDownloadPage'
import { WebsiteHomePage } from './WebsiteHomePage'
import { WebsiteInfoPage } from './WebsiteInfoPage'
import { WebsiteLayout } from './WebsiteLayout'

describe('Website pages motion regression', () => {
  it('首页区块注入入场与悬停动效类名', () => {
    render(
      <MemoryRouter>
        <WebsiteHomePage />
      </MemoryRouter>,
    )

    expect(screen.getByRole('heading', { level: 2, name: '面向桌面端的钱包官网首页' })).toBeInTheDocument()
    expect(document.querySelectorAll('.site-motion-rise').length).toBeGreaterThan(0)
    expect(document.querySelectorAll('.site-card-interactive').length).toBe(6)
  })

  it('下载与信息页卡片保持交互动效结构', () => {
    const { rerender } = render(
      <MemoryRouter>
        <WebsiteDownloadPage />
      </MemoryRouter>,
    )

    expect(screen.getByRole('heading', { level: 2, name: '下载页' })).toBeInTheDocument()
    expect(document.querySelectorAll('.site-download-grid .site-card-interactive').length).toBe(3)

    rerender(
      <MemoryRouter>
        <WebsiteInfoPage />
      </MemoryRouter>,
    )

    expect(screen.getByRole('heading', { level: 2, name: '信息页' })).toBeInTheDocument()
    expect(document.querySelectorAll('.site-info-list .site-card-interactive').length).toBe(4)
  })

  it('路由切换时挂载页面过渡容器', () => {
    render(
      <MemoryRouter initialEntries={['/site']}>
        <Routes>
          <Route path="/site" element={<WebsiteLayout />}>
            <Route index element={<WebsiteHomePage />} />
            <Route path="download" element={<WebsiteDownloadPage />} />
          </Route>
        </Routes>
      </MemoryRouter>,
    )

    expect(document.querySelector('.site-page-transition')?.getAttribute('data-route-key')).toBe('/site')
    fireEvent.click(screen.getByRole('link', { name: '下载' }))

    expect(document.querySelector('.site-page-transition')?.getAttribute('data-route-key')).toBe('/site/download')
  })
})
