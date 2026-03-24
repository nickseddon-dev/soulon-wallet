import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useAuth } from '../auth/useAuth'
import { ApiClientError, isSessionInvalidError } from '../api/errors'
import { walletApi } from '../api/walletApi'
import { appEnv } from '../config/env'
import { createBip21PaymentUri, parseBip21Input, toUnifiedBip21Error } from '../lib/bip21'

export function HomePage() {
  const { signOut } = useAuth()
  const [health, setHealth] = useState<string>('未检查')
  const [error, setError] = useState<string>('')
  const [address, setAddress] = useState<string>('')
  const [amount, setAmount] = useState<string>('')
  const [memo, setMemo] = useState<string>('')
  const [bip21Input, setBip21Input] = useState<string>('')
  const [generatedUri, setGeneratedUri] = useState<string>('')
  const [bip21Error, setBip21Error] = useState<string>('')
  const [copyStatus, setCopyStatus] = useState<string>('')
  const healthTone = health.toLowerCase() === 'ok' ? 'success' : 'neutral'

  const handleCheckHealth = async () => {
    try {
      const response = await walletApi.getHealth()
      setHealth(response.status)
      setError('')
    } catch (requestError) {
      if (isSessionInvalidError(requestError)) {
        signOut('会话已失效，请重新登录。')
        return
      }
      if (requestError instanceof ApiClientError) {
        setError(`code=${requestError.code} status=${requestError.status ?? '-'} msg=${requestError.message}`)
        return
      }
      setError(requestError instanceof Error ? requestError.message : '未知错误')
    }
  }

  const handleGenerateBip21 = () => {
    try {
      const uri = createBip21PaymentUri({
        address,
        amount,
        memo,
      })
      setGeneratedUri(uri)
      setBip21Input(uri)
      setCopyStatus('')
      setBip21Error('')
    } catch (requestError) {
      setBip21Error(toUnifiedBip21Error(requestError))
    }
  }

  const handleParseBip21 = () => {
    try {
      const parsed = parseBip21Input(bip21Input)
      setAddress(parsed.address)
      setAmount(parsed.amount)
      setMemo(parsed.memo)
      setBip21Error('')
    } catch (requestError) {
      setBip21Error(toUnifiedBip21Error(requestError))
    }
  }

  const handleCopyUri = async () => {
    if (!generatedUri) {
      return
    }
    try {
      await navigator.clipboard.writeText(generatedUri)
      setCopyStatus('已复制')
      setBip21Error('')
    } catch (requestError) {
      setCopyStatus('')
      setBip21Error(toUnifiedBip21Error(requestError))
    }
  }

  return (
    <section className="home-page">
      <div className="home-overview">
        <p className="page-kicker">Spot Overview</p>
        <h2>交易首页</h2>
        <p className="page-description">聚合关键入口与服务状态，快速进入链状态和交易事件页面。</p>
      </div>
      <div className="home-grid">
        <div className="exchange-card">
          <p className="card-title">BIP-21 收款/支付</p>
          <div className="bip21-form">
            <label className="field-block">
              收款地址
              <input
                value={address}
                onChange={(event) => setAddress(event.target.value)}
                placeholder="soulon1..."
              />
            </label>
            <label className="field-block">
              金额（可选）
              <input
                value={amount}
                onChange={(event) => setAmount(event.target.value)}
                placeholder="1.25"
              />
            </label>
            <label className="field-block">
              备注（可选）
              <input
                value={memo}
                onChange={(event) => setMemo(event.target.value)}
                placeholder="for coffee"
              />
            </label>
            <div className="bip21-actions">
              <button type="button" onClick={handleGenerateBip21}>
                生成支付 URI
              </button>
            </div>
            <label className="field-block">
              URI 粘贴/扫码结果
              <input
                value={bip21Input}
                onChange={(event) => setBip21Input(event.target.value)}
                placeholder="bitcoin:soulon1...?amount=1.25&memo=..."
              />
            </label>
            <div className="bip21-actions">
              <button type="button" onClick={handleParseBip21}>
                解析并回填表单
              </button>
            </div>
            <label className="field-block">
              已生成 URI
              <input value={generatedUri} readOnly placeholder="点击“生成支付 URI”后展示" />
            </label>
            <div className="bip21-actions">
              <button type="button" className="ghost-button" onClick={handleCopyUri} disabled={!generatedUri}>
                复制 URI
              </button>
              {copyStatus ? <span className="status-badge success">{copyStatus}</span> : null}
            </div>
          </div>
        </div>
        <div className="exchange-card">
          <p className="card-title">快捷入口</p>
          <div className="quick-links">
            <Link to="/state">链状态面板</Link>
            <Link to="/events">交易事件流</Link>
          </div>
        </div>
        <div className="exchange-card">
          <p className="card-title">系统状态</p>
          <p className="meta-line">API Base URL: {appEnv.apiBaseUrl}</p>
          <div className="health-panel">
            <button type="button" onClick={handleCheckHealth}>
              检查后端健康状态
            </button>
            <span className={`status-badge ${healthTone}`}>health: {health}</span>
          </div>
        </div>
      </div>
      {error ? <p className="error-text">{error}</p> : null}
      {bip21Error ? <p className="error-text">{bip21Error}</p> : null}
    </section>
  )
}
