import { useEffect, useState } from 'react'
import { useRouter } from 'next/router'
import { useTranslations } from 'next-intl'
import { useAuth } from '../contexts/AuthContext'
import { AppHeader } from '../components/AppHeader'
import { unlinkProvider, deleteAccount } from '../lib/api'

const PROVIDERS = [
  { key: 'apple', label: 'Apple' },
  { key: 'discord', label: 'Discord' },
  { key: 'github', label: 'GitHub' },
  { key: 'google', label: 'Google' },
  { key: 'twitter', label: 'X (Twitter)' },
] as const

export default function SettingsPage() {
  const t = useTranslations('Settings')
  const { user, accessToken, loading, refreshUser, logout } = useAuth()
  const router = useRouter()
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!loading && !user) {
      router.push(`/signin?callbackUrl=${router.asPath}`)
    }
  }, [user, loading, router])

  // Refresh user on mount (picks up newly linked provider after OAuth redirect)
  useEffect(() => {
    if (!loading && user && accessToken) {
      refreshUser()
    }
  }, [loading])

  if (loading || !user) return null

  const linkedProviders: Record<string, boolean> = {
    apple: !!user.appleId,
    discord: !!user.discordId,
    github: !!user.githubId,
    google: !!user.googleId,
    twitter: !!user.twitterId,
  }

  async function handleUnlink(provider: string) {
    if (!accessToken) return
    setError(null)
    try {
      await unlinkProvider(accessToken, provider)
      await refreshUser()
    } catch (err) {
      setError(err instanceof Error ? err.message : t('errorFallback'))
    }
  }

  async function handleDeleteAccount() {
    if (!accessToken) return
    if (!window.confirm(t('deleteAccountConfirm'))) return
    setError(null)
    try {
      await deleteAccount(accessToken)
      logout()
      router.replace('/signin')
    } catch (err) {
      setError(err instanceof Error ? err.message : t('errorFallback'))
    }
  }

  function linkUrl(provider: string): string {
    return `/backend/auth/link/${provider}?token=${accessToken}`
  }

  return (
    <div className="dashboard">
      <AppHeader />

      <main className="dashboard-body">
        <div className="user-card">
          <h2>{t('title')}</h2>
          <h3 className="settings-section-title">{t('linkedAccounts')}</h3>
          {error && <p className="error-msg">{error}</p>}
          <div className="linked-accounts-list">
            {PROVIDERS.map(({ key, label }) => (
              <div key={key} className="linked-account-row">
                <span className="linked-account-provider">{label}</span>
                {linkedProviders[key] ? (
                  <button
                    className="btn-danger"
                    onClick={() => handleUnlink(key)}
                  >
                    {t('unlink')}
                  </button>
                ) : (
                  <a href={linkUrl(key)} className="btn-primary btn-link-provider">
                    {t('link')}
                  </a>
                )}
              </div>
            ))}
          </div>
        </div>

        <div className="user-card" style={{ marginTop: '1.5rem' }}>
          <h3 className="settings-section-title">{t('deleteAccount')}</h3>
          <p style={{ fontSize: '0.875rem', color: 'var(--color-text-muted)', margin: '0.5rem 0 1rem' }}>
            {t('deleteAccountDescription')}
          </p>
          <button className="btn-danger" onClick={handleDeleteAccount}>
            {t('deleteAccount')}
          </button>
        </div>
      </main>
    </div>
  )
}
