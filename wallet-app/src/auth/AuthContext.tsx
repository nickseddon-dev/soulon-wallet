import { useEffect, useMemo, useState } from 'react'
import type { ReactNode } from 'react'
import { authContext } from './context'
import type { AuthContextValue, AuthSession } from './context'

const SESSION_STORAGE_KEY = 'wallet-app-auth-session'
const DEFAULT_SESSION_TTL_MS = 30 * 60 * 1000

const parseStoredSession = (): AuthSession | null => {
  const raw = localStorage.getItem(SESSION_STORAGE_KEY)
  if (!raw) {
    return null
  }
  try {
    const parsed = JSON.parse(raw) as AuthSession
    if (!parsed.accountId || !parsed.expiresAt || parsed.expiresAt <= Date.now()) {
      localStorage.removeItem(SESSION_STORAGE_KEY)
      return null
    }
    return parsed
  } catch {
    localStorage.removeItem(SESSION_STORAGE_KEY)
    return null
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<AuthSession | null>(() => parseStoredSession())
  const [invalidReason, setInvalidReason] = useState<string>('')

  useEffect(() => {
    const timer = setInterval(() => {
      setSession((previous) => {
        if (!previous) {
          return previous
        }
        if (previous.expiresAt > Date.now()) {
          return previous
        }
        localStorage.removeItem(SESSION_STORAGE_KEY)
        setInvalidReason('会话已过期，请重新登录。')
        return null
      })
    }, 10 * 1000)
    return () => {
      clearInterval(timer)
    }
  }, [])

  const value = useMemo<AuthContextValue>(() => {
    const isAuthenticated = Boolean(session)
    return {
      session,
      isAuthenticated,
      invalidReason,
      signIn: (accountId: string) => {
        const normalizedAccountId = accountId.trim()
        const nextSession: AuthSession = {
          accountId: normalizedAccountId,
          expiresAt: Date.now() + DEFAULT_SESSION_TTL_MS,
        }
        localStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(nextSession))
        setSession(nextSession)
        setInvalidReason('')
      },
      signOut: (reason?: string) => {
        localStorage.removeItem(SESSION_STORAGE_KEY)
        setSession(null)
        setInvalidReason(reason ?? '')
      },
      clearInvalidReason: () => {
        setInvalidReason('')
      },
    }
  }, [invalidReason, session])

  return <authContext.Provider value={value}>{children}</authContext.Provider>
}
