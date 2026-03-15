import { useEffect, useState } from 'react'
import { useRouter } from 'next/router'
import { useTranslations } from 'next-intl'
import { useAuth } from '../contexts/AuthContext'
import { useTheme, Theme } from '../contexts/ThemeContext'
import { AppHeader } from '../components/AppHeader'
import { unlinkProvider, deleteAccount, updateEmail, resendVerification } from '../lib/api'

const THEME_OPTIONS: { value: Theme; labelKey: string }[] = [
  { value: 'system', labelKey: 'themeSystem' },
  { value: 'light', labelKey: 'themeLight' },
  { value: 'dark', labelKey: 'themeDark' },
]

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
  const { theme, changeTheme } = useTheme()
  const router = useRouter()
  const [error, setError] = useState<string | null>(null)
  const [emailInput, setEmailInput] = useState('')
  const [emailSaving, setEmailSaving] = useState(false)
  const [emailResending, setEmailResending] = useState(false)
  const [emailSuccess, setEmailSuccess] = useState<string | null>(null)

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

  async function handleEmailSave() {
    if (!accessToken || !emailInput.trim()) return
    setEmailSaving(true)
    setError(null)
    setEmailSuccess(null)
    try {
      await updateEmail(accessToken, emailInput.trim())
      await refreshUser()
      setEmailSuccess(t('emailUpdated'))
    } catch (err) {
      setError(err instanceof Error ? err.message : t('errorFallback'))
    } finally {
      setEmailSaving(false)
    }
  }

  async function handleResendVerification() {
    if (!user) return
    setEmailResending(true)
    setError(null)
    setEmailSuccess(null)
    try {
      await resendVerification(user.email)
      setEmailSuccess(t('emailVerificationSent'))
    } catch (err) {
      setError(err instanceof Error ? err.message : t('errorFallback'))
    } finally {
      setEmailResending(false)
    }
  }

  function handleEmailSelect(e: React.ChangeEvent<HTMLSelectElement>) {
    setEmailInput(e.target.value)
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
          {error && <p className="error-msg">{error}</p>}
          {emailSuccess && <p className="success-msg">{emailSuccess}</p>}

          <h3 className="settings-section-title">{t('email')}</h3>
          <div className="email-section">
            {(() => {
              const isInvalidEmail = user.email.endsWith('.invalid')
              const selectableEmails = (user.socialEmails ?? []).filter((e) => e !== user.email)
              return (
                <>
                  <div className="email-status-row">
                    <span className={`email-current${isInvalidEmail ? ' email-not-set' : ''}`}>
                      {isInvalidEmail ? t('emailNotSet') : user.email}
                    </span>
                    {!isInvalidEmail && (
                      <span className={`email-badge ${user.emailVerified ? 'email-badge-verified' : 'email-badge-unverified'}`}>
                        {user.emailVerified ? t('emailVerified') : t('emailUnverified')}
                      </span>
                    )}
                  </div>

                  {!isInvalidEmail && !user.emailVerified && (
                    <button
                      className="btn-ghost email-resend-btn"
                      onClick={handleResendVerification}
                      disabled={emailResending}
                    >
                      {emailResending ? t('emailResending') : t('emailResendVerification')}
                    </button>
                  )}

                  <div className="email-edit-row">
                    <div className="email-combo">
                      <input
                        type="email"
                        className="email-combo-input"
                        placeholder={t('emailInputPlaceholder')}
                        value={emailInput}
                        onChange={(e) => setEmailInput(e.target.value)}
                      />
                      {selectableEmails.length > 0 && (
                        <select
                          className="email-combo-select"
                          value=""
                          onChange={handleEmailSelect}
                          aria-label={t('emailSelectLabel')}
                        >
                          <option value="" disabled></option>
                          {selectableEmails.map((e) => (
                            <option key={e} value={e}>{e}</option>
                          ))}
                        </select>
                      )}
                    </div>
                    <button
                      className="btn-primary email-save-btn"
                      onClick={handleEmailSave}
                      disabled={emailSaving || !emailInput.trim() || emailInput.trim() === user.email}
                    >
                      {emailSaving ? t('emailSaving') : t('emailSave')}
                    </button>
                  </div>
                </>
              )
            })()}
          </div>
        </div>

        <div className="user-card" style={{ marginTop: '1.5rem' }}>
          <h3 className="settings-section-title">{t('linkedAccounts')}</h3>
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
          <h3 className="settings-section-title">{t('theme')}</h3>
          <div className="theme-selector">
            {THEME_OPTIONS.map(({ value, labelKey }) => (
              <button
                key={value}
                className={`theme-btn${theme === value ? ' theme-btn-active' : ''}`}
                onClick={() => changeTheme(value)}
              >
                {t(labelKey)}
              </button>
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
