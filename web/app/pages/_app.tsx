import '../styles/globals.css'
import type { AppProps } from 'next/app'
import { useState, useEffect } from 'react'
import { NextIntlClientProvider } from 'next-intl'
import { AuthProvider } from '../contexts/AuthContext'
import { LocaleContext, Locale } from '../contexts/LocaleContext'
import en from '../messages/en.json'
import ja from '../messages/ja.json'

const messages = { en, ja }

export default function MyApp({ Component, pageProps }: AppProps) {
  const [locale, setLocale] = useState<Locale>('en')

  useEffect(() => {
    const stored = localStorage.getItem('locale') as Locale | null
    if (stored === 'en' || stored === 'ja') {
      setLocale(stored)
    } else if (navigator.language.startsWith('ja')) {
      setLocale('ja')
    }
  }, [])

  function changeLocale(newLocale: Locale) {
    setLocale(newLocale)
    localStorage.setItem('locale', newLocale)
  }

  return (
    <NextIntlClientProvider locale={locale} messages={messages[locale]}>
      <LocaleContext.Provider value={{ locale, changeLocale }}>
        <AuthProvider>
          <Component {...pageProps} />
        </AuthProvider>
      </LocaleContext.Provider>
    </NextIntlClientProvider>
  )
}
