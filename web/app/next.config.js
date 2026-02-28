/** @type {import('next').NextConfig} */
module.exports = {
  reactStrictMode: true,
  // Static export-friendly; suitable for SPA static hosting
  output: 'export',
  // Proxy API requests through the dev server so both browsers (host) and
  // Playwright containers (Docker internal network) can reach the backend.
  // BACKEND_URL is a server-side env var set in compose.yaml; it never
  // reaches the browser bundle.
  // Note: rewrites() is only active in dev mode (next dev). It has no effect
  // on the static export produced by next build.
  async rewrites() {
    const backendUrl = process.env.BACKEND_URL ?? 'http://localhost:4000'
    return [
      {
        source: '/backend/:path*',
        destination: `${backendUrl}/:path*`,
      },
    ]
  },
}
