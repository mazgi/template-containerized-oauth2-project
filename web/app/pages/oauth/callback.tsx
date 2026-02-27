import { useEffect } from 'react'
import { useRouter } from 'next/router'
import { getMe } from '../../lib/api'
import { useAuth } from '../../contexts/AuthContext'

export default function OAuthCallbackPage() {
  const router = useRouter()
  const { login, refreshUser } = useAuth()

  useEffect(() => {
    if (!router.isReady) return

    const { accessToken, refreshToken, linked } = router.query

    // Account linking callback — refresh user and redirect to settings
    if (typeof linked === 'string') {
      refreshUser().then(() => router.replace('/settings'))
      return
    }

    if (
      typeof accessToken !== 'string' ||
      typeof refreshToken !== 'string' ||
      !accessToken ||
      !refreshToken
    ) {
      router.replace('/signin')
      return
    }

    getMe(accessToken)
      .then((user) => {
        login({ accessToken, refreshToken, user })
        router.replace('/dashboard')
      })
      .catch(() => {
        router.replace('/signin')
      })
  }, [router.isReady, router.query])

  return null
}
