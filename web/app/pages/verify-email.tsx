import { useEffect, useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/router'
import { useTranslations } from 'next-intl'
import { verifyEmail } from '../lib/api'
import { LanguageSwitcher } from '../components/LanguageSwitcher'

export default function VerifyEmailPage() {
  const t = useTranslations('VerifyEmail')
  const router = useRouter()
  const { token } = router.query

  const [status, setStatus] = useState<'loading' | 'success' | 'error'>('loading')
  const [error, setError] = useState('')

  useEffect(() => {
    if (!router.isReady) return
    if (!token || typeof token !== 'string') {
      setStatus('error')
      setError(t('invalidToken'))
      return
    }

    verifyEmail(token)
      .then(() => setStatus('success'))
      .catch((err) => {
        setStatus('error')
        setError(err instanceof Error ? err.message : t('errorFallback'))
      })
  }, [router.isReady, token, t])

  return (
    <div className="page-center">
      <div className="card">
        <h1 className="card-title">{t('title')}</h1>

        {status === 'loading' && <p>{t('verifying')}</p>}

        {status === 'success' && (
          <>
            <p>{t('successMessage')}</p>
            <p className="form-footer">
              <Link href="/signin">{t('signInLink')}</Link>
            </p>
          </>
        )}

        {status === 'error' && (
          <>
            <div className="error-msg">{error}</div>
            <p className="form-footer">
              <Link href="/signup">{t('signUpLink')}</Link>
            </p>
          </>
        )}

        <LanguageSwitcher />
      </div>
    </div>
  )
}
