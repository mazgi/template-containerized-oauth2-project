import { test, expect } from '@playwright/test'

let counter = 0
function uniqueEmail(prefix = 'user') {
  counter++
  return `${prefix}.${Date.now()}.${counter}@example.com`
}

const DEFAULT_PASSWORD = 'password123'

async function signUp(page: import('@playwright/test').Page, email: string) {
  await page.goto('/signup')
  await page.locator('#email').fill(email)
  await page.locator('#password').fill(DEFAULT_PASSWORD)
  await page.locator('#confirm').fill(DEFAULT_PASSWORD)
  await page.locator('button[type="submit"]').click()
  await expect(page).toHaveURL(/\/dashboard/)
}

// ---------------------------------------------------------------------------
// Theme settings
// ---------------------------------------------------------------------------
test.describe('Theme settings', () => {
  const sharedEmail = uniqueEmail('theme')

  test.beforeAll(async ({ browser }) => {
    const page = await browser.newPage()
    await signUp(page, sharedEmail)
    await page.close()
  })

  test.beforeEach(async ({ page }) => {
    await page.goto('/signin')
    await page.locator('#email').fill(sharedEmail)
    await page.locator('#password').fill(DEFAULT_PASSWORD)
    await page.locator('button[type="submit"]').click()
    await expect(page).toHaveURL(/\/dashboard/)

    await page.getByRole('link', { name: 'Settings' }).click()
    await expect(page).toHaveURL(/\/settings/)
    await page.waitForLoadState('networkidle')
  })

  test('shows theme selector with System, Light, and Dark options', async ({ page }) => {
    const themeSelector = page.locator('.theme-selector')
    await expect(themeSelector).toBeVisible()

    const buttons = themeSelector.locator('.theme-btn')
    await expect(buttons).toHaveCount(3)
  })

  test('System is the default active theme', async ({ page }) => {
    const systemBtn = page.locator('.theme-btn-active')
    await expect(systemBtn).toHaveCount(1)

    // data-theme attribute should not be set for system mode
    const dataTheme = await page.locator('html').getAttribute('data-theme')
    expect(dataTheme).toBeNull()
  })

  test('can switch to Dark theme', async ({ page }) => {
    const darkBtn = page.locator('.theme-btn', { hasText: 'Dark' })
    await darkBtn.click()

    await expect(darkBtn).toHaveClass(/theme-btn-active/)
    await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark')
  })

  test('can switch to Light theme', async ({ page }) => {
    const lightBtn = page.locator('.theme-btn', { hasText: 'Light' })
    await lightBtn.click()

    await expect(lightBtn).toHaveClass(/theme-btn-active/)
    await expect(page.locator('html')).toHaveAttribute('data-theme', 'light')
  })

  test('can switch back to System theme', async ({ page }) => {
    // First switch to dark
    await page.locator('.theme-btn', { hasText: 'Dark' }).click()
    await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark')

    // Then switch back to system
    const systemBtn = page.locator('.theme-btn', { hasText: 'System' })
    await systemBtn.click()

    await expect(systemBtn).toHaveClass(/theme-btn-active/)
    const dataTheme = await page.locator('html').getAttribute('data-theme')
    expect(dataTheme).toBeNull()
  })

  test('theme persists after page reload', async ({ page }) => {
    // Switch to dark
    await page.locator('.theme-btn', { hasText: 'Dark' }).click()
    await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark')

    // Wait for the preference to be saved
    await page.waitForLoadState('networkidle')

    // Reload and check persistence
    await page.reload()
    await page.waitForLoadState('networkidle')

    await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark')
    await expect(page.locator('.theme-btn', { hasText: 'Dark' })).toHaveClass(/theme-btn-active/)
  })

  test('only one theme button is active at a time', async ({ page }) => {
    // Click Dark
    await page.locator('.theme-btn', { hasText: 'Dark' }).click()
    await expect(page.locator('.theme-btn-active')).toHaveCount(1)
    await expect(page.locator('.theme-btn', { hasText: 'Dark' })).toHaveClass(/theme-btn-active/)

    // Click Light
    await page.locator('.theme-btn', { hasText: 'Light' }).click()
    await expect(page.locator('.theme-btn-active')).toHaveCount(1)
    await expect(page.locator('.theme-btn', { hasText: 'Light' })).toHaveClass(/theme-btn-active/)

    // Click System
    await page.locator('.theme-btn', { hasText: 'System' }).click()
    await expect(page.locator('.theme-btn-active')).toHaveCount(1)
    await expect(page.locator('.theme-btn', { hasText: 'System' })).toHaveClass(/theme-btn-active/)
  })
})
