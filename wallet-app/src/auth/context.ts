import { createContext } from 'react'

export type AuthSession = {
  accountId: string
  expiresAt: number
}

export type AuthContextValue = {
  session: AuthSession | null
  isAuthenticated: boolean
  invalidReason: string
  signIn: (accountId: string) => void
  signOut: (reason?: string) => void
  clearInvalidReason: () => void
}

export const authContext = createContext<AuthContextValue | undefined>(undefined)
