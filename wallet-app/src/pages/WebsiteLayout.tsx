import { NavLink, Outlet, useLocation } from 'react-router-dom'

export function WebsiteLayout() {
  const location = useLocation()

  return (
    <div className="site-shell backpack-site-shell">
      <div className="backpack-site-container">
        <header className="site-header backpack-site-header">
          <div className="site-brand backpack-site-brand">
            <img src="https://raw.githubusercontent.com/coral-xyz/backpack/master/web/public/backpack.svg" alt="Backpack" className="backpack-logo" />
          </div>
          <nav className="site-nav backpack-site-nav">
            <a href="https://backpack.exchange" target="_blank" rel="noopener noreferrer">
              Exchange
            </a>
            <NavLink to="/site/download">Downloads</NavLink>
            <NavLink to="/site" end>
              News
            </NavLink>
          </nav>
        </header>
        <main className="site-main backpack-site-main">
          <div key={location.pathname} className="site-page-transition backpack-site-page-transition" data-route-key={location.pathname}>
            <Outlet />
          </div>
        </main>
        <footer className="backpack-site-footer">© Backpack UI Replica</footer>
      </div>
    </div>
  )
}
