import { Navigate, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from './useAuth'

type LoginLocationState = {
  from?: string
  reason?: string
}

export function RequireAuth() {
  const location = useLocation()
  const { isAuthenticated, invalidReason } = useAuth()
  if (!isAuthenticated) {
    const nextState: LoginLocationState = {
      from: `${location.pathname}${location.search}`,
      reason: invalidReason || undefined,
    }
    return <Navigate to="/login" replace state={nextState} />
  }
  return <Outlet />
}
