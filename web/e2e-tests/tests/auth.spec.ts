import { test, expect } from '@playwright/test'

// Counter to guarantee unique emails even within the same millisecond
let counter = 0
function uniqueEmail(prefix = 'user') {
  counter++
  return `${prefix}.${Date.now()}.${counter}@example.com`
}

const DEFAULT_PASSWORD = 'password123'

// ---------------------------------------------------------------------------
// Sign up
// ---------------------------------------------------------------------------
test.describe('Sign up', () => {
  test('creates account and redirects to dashboard', async ({ page }) => {
    const email = uniqueEmail('signup')

    await page.goto('/signup')
    await page.locator('#email').fill(email)
    await page.locator('#password').fill(DEFAULT_PASSWORD)
    await page.locator('#confirm').fill(DEFAULT_PASSWORD)
    await page.locator('button[type="submit"]').click()

    await expect(page).toHaveURL(/\/dashboard/)
    await expect(page.getByText(email)).toBeVisible()
  })

  test('shows error when passwords do not match', async ({ page }) => {
    await page.goto('/signup')
    await page.locator('#email').fill(uniqueEmail('mismatch'))
    await page.locator('#password').fill(DEFAULT_PASSWORD)
    await page.locator('#confirm').fill('different_password')
    await page.locator('button[type="submit"]').click()

    await expect(page.locator('.error-msg')).toContainText('Passwords do not match')
    await expect(page).toHaveURL(/\/signup/)
  })

  test('shows error for duplicate email', async ({ page }) => {
    const email = uniqueEmail('dup')

    // First registration
    await page.goto('/signup')
    await page.locator('#email').fill(email)
    await page.locator('#password').fill(DEFAULT_PASSWORD)
    await page.locator('#confirm').fill(DEFAULT_PASSWORD)
    await page.locator('button[type="submit"]').click()
    await expect(page).toHaveURL(/\/dashboard/)

    // Sign out so we can try again
    await page.getByRole('button', { name: 'Sign out' }).click()
    await expect(page).toHaveURL(/\/signin/)

    // Attempt registration with the same email
    await page.goto('/signup')
    await page.locator('#email').fill(email)
    await page.locator('#password').fill(DEFAULT_PASSWORD)
    await page.locator('#confirm').fill(DEFAULT_PASSWORD)
    await page.locator('button[type="submit"]').click()

    await expect(page.locator('.error-msg')).toBeVisible()
    await expect(page).toHaveURL(/\/signup/)
  })
})

// ---------------------------------------------------------------------------
// Sign in
// ---------------------------------------------------------------------------
test.describe('Sign in', () => {
  // One shared user created before all tests in this block
  const sharedEmail = uniqueEmail('signin')

  test.beforeAll(async ({ browser }) => {
    const page = await browser.newPage()
    await page.goto('/signup')
    await page.locator('#email').fill(sharedEmail)
    await page.locator('#password').fill(DEFAULT_PASSWORD)
    await page.locator('#confirm').fill(DEFAULT_PASSWORD)
    await page.locator('button[type="submit"]').click()
    await expect(page).toHaveURL(/\/dashboard/)
    await page.close()
  })

  test('signs in and redirects to dashboard', async ({ page }) => {
    await page.goto('/signin')
    await page.locator('#email').fill(sharedEmail)
    await page.locator('#password').fill(DEFAULT_PASSWORD)
    await page.locator('button[type="submit"]').click()

    await expect(page).toHaveURL(/\/dashboard/)
    await expect(page.getByText(sharedEmail)).toBeVisible()
  })

  test('shows error for wrong password', async ({ page }) => {
    await page.goto('/signin')
    await page.locator('#email').fill(sharedEmail)
    await page.locator('#password').fill('wrong_password')
    await page.locator('button[type="submit"]').click()

    await expect(page.locator('.error-msg')).toBeVisible()
    await expect(page).toHaveURL(/\/signin/)
  })

  test('shows error for non-existent email', async ({ page }) => {
    await page.goto('/signin')
    await page.locator('#email').fill(`nonexistent.${Date.now()}@example.com`)
    await page.locator('#password').fill(DEFAULT_PASSWORD)
    await page.locator('button[type="submit"]').click()

    await expect(page.locator('.error-msg')).toBeVisible()
    await expect(page).toHaveURL(/\/signin/)
  })
})

// ---------------------------------------------------------------------------
// Access control
// ---------------------------------------------------------------------------
test.describe('Access control', () => {
  test('unauthenticated access to /dashboard redirects to /signin', async ({ page }) => {
    await page.goto('/dashboard')
    await expect(page).toHaveURL(/\/signin/)
  })

  test('unauthenticated access to / redirects to /signin', async ({ page }) => {
    await page.goto('/')
    await expect(page).toHaveURL(/\/signin/)
  })

  test('authenticated access to / redirects to /dashboard', async ({ page }) => {
    const email = uniqueEmail('indexauth')

    await page.goto('/signup')
    await page.locator('#email').fill(email)
    await page.locator('#password').fill(DEFAULT_PASSWORD)
    await page.locator('#confirm').fill(DEFAULT_PASSWORD)
    await page.locator('button[type="submit"]').click()
    await expect(page).toHaveURL(/\/dashboard/)

    await page.goto('/')
    await expect(page).toHaveURL(/\/dashboard/)
  })
})

// ---------------------------------------------------------------------------
// Sign out
// ---------------------------------------------------------------------------
test.describe('Sign out', () => {
  test('signs out, redirects to /signin, and blocks dashboard access', async ({ page }) => {
    const email = uniqueEmail('signout')

    await page.goto('/signup')
    await page.locator('#email').fill(email)
    await page.locator('#password').fill(DEFAULT_PASSWORD)
    await page.locator('#confirm').fill(DEFAULT_PASSWORD)
    await page.locator('button[type="submit"]').click()
    await expect(page).toHaveURL(/\/dashboard/)

    await page.getByRole('button', { name: 'Sign out' }).click()
    await expect(page).toHaveURL(/\/signin/)

    // Dashboard must be inaccessible after sign-out
    await page.goto('/dashboard')
    await expect(page).toHaveURL(/\/signin/)
  })
})

// ---------------------------------------------------------------------------
// Delete account
// ---------------------------------------------------------------------------
test.describe('Delete account', () => {
  test('deletes account, redirects to /signin, and prevents sign-in', async ({ page }) => {
    const email = uniqueEmail('delete')

    // Sign up
    await page.goto('/signup')
    await page.locator('#email').fill(email)
    await page.locator('#password').fill(DEFAULT_PASSWORD)
    await page.locator('#confirm').fill(DEFAULT_PASSWORD)
    await page.locator('button[type="submit"]').click()
    await expect(page).toHaveURL(/\/dashboard/)

    // Navigate to settings
    await page.getByRole('link', { name: 'Settings' }).click()
    await expect(page).toHaveURL(/\/settings/)
    await page.waitForLoadState('networkidle')

    // Accept the browser confirmation dialog
    page.on('dialog', async (dialog) => {
      expect(dialog.type()).toBe('confirm')
      await dialog.accept()
    })

    // Click delete account button
    await page.getByRole('button', { name: 'Delete account' }).click()

    // Should redirect to sign-in
    await expect(page).toHaveURL(/\/signin/)

    // Attempting to sign in with the deleted email should fail
    await page.locator('#email').fill(email)
    await page.locator('#password').fill(DEFAULT_PASSWORD)
    await page.locator('button[type="submit"]').click()

    await expect(page.locator('.error-msg')).toBeVisible()
    await expect(page).toHaveURL(/\/signin/)
  })
})

// ---------------------------------------------------------------------------
// Page navigation
// ---------------------------------------------------------------------------
test.describe('Page navigation', () => {
  test('sign-in page has a link to sign-up', async ({ page }) => {
    await page.goto('/signin')
    await expect(page.locator('a[href="/signup"]')).toBeVisible()
  })

  test('sign-up page has a link to sign-in', async ({ page }) => {
    await page.goto('/signup')
    await expect(page.locator('a[href="/signin"]')).toBeVisible()
  })
})
