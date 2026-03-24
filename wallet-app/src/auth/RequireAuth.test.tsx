import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation } from 'react-router-dom'
import { describe, expect, it } from 'vitest'
import { RequireAuth } from './RequireAuth'
import { authContext } from './context'
import type { AuthContextValue } from './context'

const noop = (): void => undefined

const createAuthValue = (overrides: Partial<AuthContextValue>): AuthContextValue => {
  return {
    session: null,
    isAuthenticated: false,
    invalidReason: '',
    signIn: noop,
    signOut: noop,
    clearInvalidReason: noop,
    ...overrides,
  }
}

function LoginStateProbe() {
  const location = useLocation()
  const state = location.state as { from?: string; reason?: string } | null
  return (
    <div>
      <span>登录页</span>
      <span>{state?.from ?? ''}</span>
      <span>{state?.reason ?? ''}</span>
    </div>
  )
}

describe('RequireAuth', () => {
  it('未登录时跳转到登录页并携带来源与原因', () => {
    const authValue = createAuthValue({
      invalidReason: '会话已过期，请重新登录。',
    })

    render(
      <authContext.Provider value={authValue}>
        <MemoryRouter initialEntries={['/state?tab=latest']}>
          <Routes>
            <Route path="/login" element={<LoginStateProbe />} />
            <Route element={<RequireAuth />}>
              <Route path="/state" element={<div>受保护页面</div>} />
            </Route>
          </Routes>
        </MemoryRouter>
      </authContext.Provider>,
    )

    expect(screen.getByText('登录页')).toBeInTheDocument()
    expect(screen.getByText('/state?tab=latest')).toBeInTheDocument()
    expect(screen.getByText('会话已过期，请重新登录。')).toBeInTheDocument()
    expect(screen.queryByText('受保护页面')).not.toBeInTheDocument()
  })

  it('已登录时渲染受保护页面', () => {
    const authValue = createAuthValue({
      isAuthenticated: true,
      session: {
        accountId: 'user-1',
        expiresAt: Date.now() + 60_000,
      },
    })

    render(
      <authContext.Provider value={authValue}>
        <MemoryRouter initialEntries={['/state']}>
          <Routes>
            <Route path="/login" element={<div>登录页</div>} />
            <Route element={<RequireAuth />}>
              <Route path="/state" element={<div>受保护页面</div>} />
            </Route>
          </Routes>
        </MemoryRouter>
      </authContext.Provider>,
    )

    expect(screen.getByText('受保护页面')).toBeInTheDocument()
    expect(screen.queryByText('登录页')).not.toBeInTheDocument()
  })
})
