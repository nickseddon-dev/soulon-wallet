import { useCallback, useEffect, useState } from 'react'
import { useAuth } from '../auth/useAuth'
import { ApiClientError, isSessionInvalidError } from '../api/errors'
import { walletApi } from '../api/walletApi'
import type { IndexerStateResponse } from '../api/walletApi'

export function StatePage() {
  const { signOut } = useAuth()
  const [stateData, setStateData] = useState<IndexerStateResponse | null>(null)
  const [loading, setLoading] = useState<boolean>(true)
  const [error, setError] = useState<string>('')

  const loadState = useCallback(async () => {
    setLoading(true)
    try {
      const response = await walletApi.getIndexerState()
      setStateData(response)
      setError('')
    } catch (requestError) {
      if (isSessionInvalidError(requestError)) {
        signOut('会话已失效，请重新登录。')
        return
      }
      if (requestError instanceof ApiClientError) {
        setError(`code=${requestError.code} status=${requestError.status ?? '-'} msg=${requestError.message}`)
      } else {
        setError(requestError instanceof Error ? requestError.message : '未知错误')
      }
    } finally {
      setLoading(false)
    }
  }, [signOut])

  useEffect(() => {
    void loadState()
  }, [loadState])

  return (
    <section className="panel-page">
      <div className="panel-overview">
        <p className="page-kicker">Spot Chain Monitor</p>
        <h2>链状态</h2>
        <p className="page-description">聚合索引器核心状态指标，帮助你快速掌握当前链路健康度。</p>
      </div>
      <div className="page-actions">
        <button type="button" onClick={() => void loadState()} disabled={loading}>
          {loading ? '加载中...' : '刷新状态'}
        </button>
      </div>
      {error ? <p className="error-text">{error}</p> : null}
      {stateData ? (
        <div className="state-grid state-grid-compact">
          <article className="state-card">
            <span>Tip Height</span>
            <strong>{stateData.tipHeight}</strong>
          </article>
          <article className="state-card">
            <span>Tip Hash</span>
            <strong>{stateData.tipHash || '-'}</strong>
          </article>
          <article className="state-card">
            <span>总区块数</span>
            <strong>{stateData.total}</strong>
          </article>
          <article className="state-card">
            <span>重组次数</span>
            <strong>{stateData.reorgs}</strong>
          </article>
        </div>
      ) : (
        <p>{loading ? '正在加载链状态...' : '暂无状态数据。'}</p>
      )}
    </section>
  )
}
