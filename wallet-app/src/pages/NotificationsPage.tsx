import { useEffect, useState } from 'react'
import { ApiClientError, isSessionInvalidError } from '../api/errors'
import { walletApi } from '../api/walletApi'
import type { NotificationMessage } from '../api/walletApi'
import { useAuth } from '../auth/useAuth'

const formatTime = (value: string): string => {
  if (!value) {
    return '-'
  }
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) {
    return value
  }
  return date.toLocaleString('zh-CN')
}

export function NotificationsPage() {
  const { signOut } = useAuth()
  const [notifications, setNotifications] = useState<NotificationMessage[]>([])
  const [loading, setLoading] = useState<boolean>(true)
  const [error, setError] = useState<string>('')
  const [offset, setOffset] = useState<number>(0)
  const [hasMore, setHasMore] = useState<boolean>(false)
  const [streamStatus, setStreamStatus] = useState<'connecting' | 'open' | 'closed'>('connecting')
  const limit = 20

  useEffect(() => {
    const run = async () => {
      setLoading(true)
      try {
        const response = await walletApi.getNotifications({ limit, offset })
        setNotifications(response.notifications)
        setHasMore(response.hasMore)
        setError('')
      } catch (requestError) {
        if (isSessionInvalidError(requestError)) {
          signOut('会话已失效，请重新登录。')
          return
        }
        if (requestError instanceof ApiClientError) {
          setError(`code=${requestError.code} status=${requestError.status ?? '-'} msg=${requestError.message}`)
        } else {
          setError(requestError instanceof Error ? requestError.message : '通知查询失败')
        }
      } finally {
        setLoading(false)
      }
    }
    void run()
  }, [offset, signOut])

  useEffect(() => {
    setStreamStatus('connecting')
    const stream = new EventSource(walletApi.getNotificationsStreamUrl(limit))
    stream.onopen = () => {
      setStreamStatus('open')
    }
    stream.onerror = () => {
      setStreamStatus('closed')
    }
    stream.addEventListener('notification', (event) => {
      const message = event as MessageEvent<string>
      try {
        const parsed = JSON.parse(message.data) as NotificationMessage
        setNotifications((current) => {
          const next = [parsed, ...current]
          return next.slice(0, limit)
        })
      } catch {
        return
      }
    })
    return () => {
      stream.close()
      setStreamStatus('closed')
    }
  }, [])

  return (
    <section className="panel-page">
      <div className="panel-overview">
        <p className="page-kicker">Spot Notification Feed</p>
        <h2>通知中心</h2>
        <p className="page-description">接收并展示 Indexer 推送的链上通知消息。</p>
      </div>
      <div className="exchange-card">
        <div className="page-actions">
          <button type="button" onClick={() => setOffset(0)} disabled={loading}>
            刷新
          </button>
          <button type="button" onClick={() => setOffset((value) => Math.max(0, value - limit))} disabled={loading || offset === 0}>
            上一页
          </button>
          <button type="button" onClick={() => setOffset((value) => value + limit)} disabled={loading || !hasMore}>
            下一页
          </button>
        </div>
        <p className="events-meta">实时订阅: {streamStatus}</p>
      </div>
      {error ? <p className="error-text">{error}</p> : null}
      <div className="events-table-wrap">
        <table className="events-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>类型</th>
              <th>高度</th>
              <th>区块哈希</th>
              <th>接收时间</th>
              <th>Payload</th>
            </tr>
          </thead>
          <tbody>
            {notifications.map((notification) => (
              <tr key={`${notification.id}-${notification.receivedAt}`}>
                <td>{notification.id}</td>
                <td>{notification.type}</td>
                <td>{notification.height}</td>
                <td>{notification.blockHash || '-'}</td>
                <td>{formatTime(notification.receivedAt)}</td>
                <td>{notification.payload}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {!loading && !notifications.length ? <p>暂无通知数据。</p> : null}
      </div>
    </section>
  )
}
