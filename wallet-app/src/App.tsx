import { NavLink, Outlet } from 'react-router-dom'
import { useAuth } from './auth/useAuth'

function App() {
  const { session, signOut } = useAuth()

  return (
    <div className="app-shell">
      <div className="app-frame">
        <header className="app-header">
          <div className="brand-block">
            <p className="brand-eyebrow">Spot Wallet Terminal</p>
            <h1>Soulon Wallet App</h1>
            <p className="session-text">当前登录：{session?.accountId ?? '-'}</p>
          </div>
          <button type="button" onClick={() => signOut()}>
            退出登录
          </button>
        </header>
        <nav className="app-nav">
          <NavLink to="/" end>
            首页
          </NavLink>
          <NavLink to="/state">链状态</NavLink>
          <NavLink to="/events">交易事件</NavLink>
          <NavLink to="/notifications">通知中心</NavLink>
        </nav>
        <main className="app-main">
          <Outlet />
        </main>
      </div>
    </div>
  )
}

export default App
