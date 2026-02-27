// Requests are proxied through the Next.js dev server via the /backend rewrite
// rule in next.config.js. Using a relative path means the same code works for
// browsers on the host (localhost:3000) and Playwright inside Docker (web-app:3000).
const API_BASE = '/backend'

export interface User {
  id: string
  email: string
  appleId?: string | null
  githubId?: string | null
  googleId?: string | null
  twitterId?: string | null
  discordId?: string | null
  hasPassword?: boolean
  createdAt: string
  updatedAt: string
}

export interface AuthResponse {
  accessToken: string
  refreshToken: string
  user: User
}

export interface Item {
  id: string
  name: string
  userId: string
  createdAt: string
  updatedAt: string
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: { 'Content-Type': 'application/json', ...options.headers },
  })
  if (!res.ok) {
    const body = await res.json().catch(() => ({}))
    throw new Error(body.message ?? res.statusText)
  }
  return res.json()
}

export function signup(email: string, password: string): Promise<AuthResponse> {
  return request('/auth/signup', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  })
}

export function signin(email: string, password: string): Promise<AuthResponse> {
  return request('/auth/signin', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  })
}

export function getMe(accessToken: string): Promise<User> {
  return request('/auth/me', {
    headers: { Authorization: `Bearer ${accessToken}` },
  })
}

export function refreshTokens(refreshToken: string): Promise<AuthResponse> {
  return request('/auth/refresh', {
    method: 'POST',
    body: JSON.stringify({ refreshToken }),
  })
}

export function unlinkProvider(accessToken: string, provider: string): Promise<User> {
  return request(`/auth/link/${provider}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${accessToken}` },
  })
}

export async function deleteAccount(accessToken: string): Promise<void> {
  const res = await fetch(`${API_BASE}/auth/account`, {
    method: 'DELETE',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${accessToken}`,
    },
  })
  if (!res.ok) {
    const body = await res.json().catch(() => ({}))
    throw new Error((body as { message?: string }).message ?? res.statusText)
  }
}

export function getItems(accessToken: string): Promise<Item[]> {
  return request('/items', {
    headers: { Authorization: `Bearer ${accessToken}` },
  })
}

export function createItem(accessToken: string, name: string): Promise<Item> {
  return request('/items', {
    method: 'POST',
    headers: { Authorization: `Bearer ${accessToken}` },
    body: JSON.stringify({ name }),
  })
}

export async function deleteItem(accessToken: string, id: string): Promise<void> {
  const res = await fetch(`${API_BASE}/items/${id}`, {
    method: 'DELETE',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${accessToken}`,
    },
  })
  if (!res.ok) {
    const body = await res.json().catch(() => ({}))
    throw new Error((body as { message?: string }).message ?? res.statusText)
  }
}
