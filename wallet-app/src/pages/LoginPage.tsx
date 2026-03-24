import { useEffect, useMemo, useRef, useState } from 'react'
import type { FormEvent } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { ApiClientError, isSessionInvalidError } from '../api/errors'
import { walletApi } from '../api/walletApi'
import type { SignatureAuthorizeResponse, SignatureChallengeResponse } from '../api/walletApi'
import { useAuth } from '../auth/useAuth'

type LoginLocationState = {
  from?: string
  reason?: string
}

export function LoginPage() {
  const navigate = useNavigate()
  const location = useLocation()
  const locationState = location.state as LoginLocationState | null
  const { signIn, clearInvalidReason, invalidReason, isAuthenticated } = useAuth()
  const [accountId, setAccountId] = useState<string>('demo-user')
  const [formError, setFormError] = useState<string>('')
  const [requestingChallenge, setRequestingChallenge] = useState<boolean>(false)
  const [confirmingSignature, setConfirmingSignature] = useState<boolean>(false)
  const [challenge, setChallenge] = useState<SignatureChallengeResponse | null>(null)
  const [authorizationResult, setAuthorizationResult] = useState<SignatureAuthorizeResponse | null>(null)
  const redirectTimerRef = useRef<number | null>(null)
  const redirectPath = useMemo(() => {
    return locationState?.from && locationState.from !== '/login' ? locationState.from : '/'
  }, [locationState?.from])

  useEffect(() => {
    if (isAuthenticated && !authorizationResult?.success) {
      navigate(redirectPath, { replace: true })
    }
  }, [authorizationResult?.success, isAuthenticated, navigate, redirectPath])

  useEffect(() => {
    return () => {
      if (redirectTimerRef.current !== null) {
        window.clearTimeout(redirectTimerRef.current)
      }
    }
  }, [])

  const sessionMessage = locationState?.reason || invalidReason

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    const normalizedAccountId = accountId.trim()
    if (!normalizedAccountId) {
      setFormError('请输入登录账号。')
      return
    }
    setRequestingChallenge(true)
    try {
      const challengeResponse = await walletApi.createSignatureChallenge(normalizedAccountId)
      setChallenge(challengeResponse)
      setAuthorizationResult(null)
      setFormError('')
    } catch (requestError) {
      if (isSessionInvalidError(requestError)) {
        setFormError('会话已失效，请刷新页面后重试。')
      } else if (requestError instanceof ApiClientError) {
        setFormError(`code=${requestError.code} status=${requestError.status ?? '-'} msg=${requestError.message}`)
      } else {
        setFormError(requestError instanceof Error ? requestError.message : '授权请求失败')
      }
    } finally {
      setRequestingChallenge(false)
    }
  }

  const handleConfirmSignature = async () => {
    if (!challenge) {
      setFormError('请先发起授权请求。')
      return
    }
    const normalizedAccountId = accountId.trim()
    if (!normalizedAccountId) {
      setFormError('请输入登录账号。')
      return
    }
    setConfirmingSignature(true)
    try {
      const signature = `${challenge.requestId}.${normalizedAccountId}.${Date.now().toString(16)}`
      const result = await walletApi.confirmSignatureAuthorization({
        accountId: normalizedAccountId,
        requestId: challenge.requestId,
        signature,
      })
      setAuthorizationResult(result)
      if (!result.success) {
        setFormError('签名授权未通过，请重试。')
        return
      }
      signIn(normalizedAccountId)
      clearInvalidReason()
      setFormError('')
      redirectTimerRef.current = window.setTimeout(() => {
        navigate(redirectPath, { replace: true })
      }, 800)
    } catch (requestError) {
      if (isSessionInvalidError(requestError)) {
        setFormError('会话已失效，请刷新页面后重试。')
      } else if (requestError instanceof ApiClientError) {
        setFormError(`code=${requestError.code} status=${requestError.status ?? '-'} msg=${requestError.message}`)
      } else {
        setFormError(requestError instanceof Error ? requestError.message : '签名确认失败')
      }
    } finally {
      setConfirmingSignature(false)
    }
  }

  return (
    <section className="login-page">
      <div className="login-hero">
        <p className="page-kicker">Spot Access</p>
        <h2>交易终端登录</h2>
        <p className="page-description">输入账号并完成两步签名授权，即可进入钱包交易台。</p>
      </div>
      {sessionMessage ? <p className="error-text">{sessionMessage}</p> : null}
      <form className="login-form" onSubmit={handleSubmit}>
        <label htmlFor="accountId">账号标识</label>
        <input
          id="accountId"
          name="accountId"
          value={accountId}
          onChange={(event) => setAccountId(event.target.value)}
          autoComplete="off"
          placeholder="例如：demo-user"
        />
        <div className="login-actions">
          <button type="submit" disabled={requestingChallenge || confirmingSignature}>
            {requestingChallenge ? '请求授权中...' : '1. 发起授权请求'}
          </button>
          <button
            type="button"
            className="ghost-button"
            onClick={handleConfirmSignature}
            disabled={confirmingSignature || requestingChallenge || !challenge}
          >
            {confirmingSignature ? '签名确认中...' : '2. 确认签名并登录'}
          </button>
        </div>
      </form>
      {challenge ? (
        <div className="auth-result-card">
          <p className="card-title">授权挑战</p>
          <p>requestId: {challenge.requestId}</p>
          <p>expiresAt: {new Date(challenge.expiresAt).toLocaleString('zh-CN')}</p>
          <pre>{challenge.challengeMessage}</pre>
        </div>
      ) : null}
      {authorizationResult ? (
        <div className="auth-result-card">
          <p className="card-title">授权结果</p>
          <p>状态: {authorizationResult.success ? '成功' : '失败'}</p>
          <p>requestId: {authorizationResult.requestId}</p>
          <p>account: {authorizationResult.accountId}</p>
          <p>authorizedAt: {new Date(authorizationResult.authorizedAt).toLocaleString('zh-CN')}</p>
          <p>signature: {authorizationResult.signature}</p>
        </div>
      ) : null}
      {formError ? <p className="error-text">{formError}</p> : null}
    </section>
  )
}
