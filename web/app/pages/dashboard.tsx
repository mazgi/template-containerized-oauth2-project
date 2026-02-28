import { useEffect } from 'react'
import { useRouter } from 'next/router'
import { useTranslations } from 'next-intl'
import { useAuth } from '../contexts/AuthContext'
import { useLocale } from '../contexts/LocaleContext'
import { AppHeader } from '../components/AppHeader'

export default function DashboardPage() {
  const t = useTranslations('Dashboard')
  const { user, loading } = useAuth()
  const { locale } = useLocale()
  const router = useRouter()

  useEffect(() => {
    if (!loading && !user) router.replace('/signin')
  }, [user, loading, router])

  if (loading || !user) return null

  return (
    <div className="dashboard">
      <AppHeader />

      <main className="dashboard-body">
        <div className="user-card">
          <h2>{t('yourAccount')}</h2>
          <div className="user-field">
            <span className="user-field-label">{t('id')}</span>
            <span>{user.id}</span>
          </div>
          <div className="user-field">
            <span className="user-field-label">{t('email')}</span>
            <span>{user.email}</span>
          </div>
          <div className="user-field">
            <span className="user-field-label">{t('created')}</span>
            <span>{new Date(user.createdAt).toLocaleString(locale)}</span>
          </div>
        </div>
      </main>
    </div>
  )
}
