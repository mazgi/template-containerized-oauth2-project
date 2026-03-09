import { FormEvent, useEffect, useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/router'
import { useTranslations } from 'next-intl'
import { signup, resendVerification } from '../lib/api'
import { useAuth } from '../contexts/AuthContext'
import { LanguageSwitcher } from '../components/LanguageSwitcher'

export default function SignUpPage() {
  const t = useTranslations('SignUp')
  const { user, loading } = useAuth()
  const router = useRouter()

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [verificationSent, setVerificationSent] = useState(false)
  const [resending, setResending] = useState(false)

  useEffect(() => {
    if (!loading && user) router.replace('/dashboard')
  }, [user, loading, router])

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setError('')

    if (password !== confirm) {
      setError(t('passwordMismatch'))
      return
    }

    setSubmitting(true)
    try {
      await signup(email, password)
      setVerificationSent(true)
    } catch (err) {
      setError(err instanceof Error ? err.message : t('errorFallback'))
    } finally {
      setSubmitting(false)
    }
  }

  async function handleResend() {
    setResending(true)
    try {
      await resendVerification(email)
    } catch {
      // Ignore errors — the API always returns success to prevent enumeration
    } finally {
      setResending(false)
    }
  }

  if (loading) return null

  if (verificationSent) {
    return (
      <div className="page-center">
        <div className="card">
          <h1 className="card-title">{t('verificationSentTitle')}</h1>
          <p>{t('verificationSentMessage')}</p>
          <button
            className="btn-primary"
            onClick={handleResend}
            disabled={resending}
            style={{ marginTop: '1rem' }}
          >
            {resending ? t('resending') : t('resendVerification')}
          </button>
          <p className="form-footer">
            <Link href="/signin">{t('signInLink')}</Link>
          </p>
          <LanguageSwitcher />
        </div>
      </div>
    )
  }

  return (
    <div className="page-center">
      <div className="card">
        <h1 className="card-title">{t('title')}</h1>

        {error && <div className="error-msg">{error}</div>}

        <form className="form" onSubmit={handleSubmit}>
          <div className="form-field">
            <label htmlFor="email">{t('email')}</label>
            <input
              id="email"
              type="email"
              autoComplete="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>

          <div className="form-field">
            <label htmlFor="password">{t('password')}</label>
            <input
              id="password"
              type="password"
              autoComplete="new-password"
              required
              minLength={8}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </div>

          <div className="form-field">
            <label htmlFor="confirm">{t('confirmPassword')}</label>
            <input
              id="confirm"
              type="password"
              autoComplete="new-password"
              required
              minLength={8}
              value={confirm}
              onChange={(e) => setConfirm(e.target.value)}
            />
          </div>

          <button type="submit" className="btn-primary" disabled={submitting}>
            {submitting ? t('submitting') : t('submit')}
          </button>
        </form>

        <p className="form-footer">
          {t('hasAccount')} <Link href="/signin">{t('signInLink')}</Link>
        </p>

        <LanguageSwitcher />
      </div>
    </div>
  )
}
