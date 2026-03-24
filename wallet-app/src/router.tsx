import { createBrowserRouter } from 'react-router-dom'
import App from './App'
import { RequireAuth } from './auth/RequireAuth'
import { EventDetailPage } from './pages/EventDetailPage'
import { EventsPage } from './pages/EventsPage'
import { HomePage } from './pages/HomePage'
import { LoginPage } from './pages/LoginPage'
import { NotificationsPage } from './pages/NotificationsPage'
import { StatePage } from './pages/StatePage'
import { WebsiteDownloadPage } from './pages/WebsiteDownloadPage'
import { WebsiteHomePage } from './pages/WebsiteHomePage'
import { WebsiteInfoPage } from './pages/WebsiteInfoPage'
import { WebsiteLayout } from './pages/WebsiteLayout'

export const appRouter = createBrowserRouter([
  {
    path: '/site',
    element: <WebsiteLayout />,
    children: [
      {
        index: true,
        element: <WebsiteHomePage />,
      },
      {
        path: 'download',
        element: <WebsiteDownloadPage />,
      },
      {
        path: 'info',
        element: <WebsiteInfoPage />,
      },
    ],
  },
  {
    path: '/login',
    element: <LoginPage />,
  },
  {
    element: <RequireAuth />,
    children: [
      {
        path: '/',
        element: <App />,
        children: [
          {
            index: true,
            element: <HomePage />,
          },
          {
            path: 'state',
            element: <StatePage />,
          },
          {
            path: 'events',
            element: <EventsPage />,
          },
          {
            path: 'notifications',
            element: <NotificationsPage />,
          },
          {
            path: 'events/:eventId',
            element: <EventDetailPage />,
          },
        ],
      },
    ],
  },
])
