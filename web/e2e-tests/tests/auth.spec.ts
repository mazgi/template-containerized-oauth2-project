import { test, expect } from "@playwright/test";

// Use a unique email per test run to avoid conflicts across runs
const uniqueSuffix = Date.now();
const testEmail = `e2e-user-${uniqueSuffix}@example.com`;
const testPassword = "TestPassword123!";
const testName = `E2E User ${uniqueSuffix}`;

test.describe("Navigation", () => {
  test("root redirects to default locale", async ({ page }) => {
    await page.goto("/");
    await expect(page).toHaveURL(/\/en($|\/)/);
  });
});

test.describe("Unauthenticated access", () => {
  test("sign-in page is accessible", async ({ page }) => {
    await page.goto("/en/sign-in");
    await expect(page.locator("#email")).toBeVisible();
    await expect(page.locator("#password")).toBeVisible();
    await expect(page.getByRole("button", { name: "Sign In" })).toBeVisible();
  });

  test("sign-up page is accessible", async ({ page }) => {
    await page.goto("/en/sign-up");
    await expect(page.locator("#name")).toBeVisible();
    await expect(page.locator("#email")).toBeVisible();
    await expect(page.locator("#password")).toBeVisible();
    await expect(page.locator("#confirmPassword")).toBeVisible();
    await expect(page.getByRole("button", { name: "Sign Up" })).toBeVisible();
  });

  test("dashboard redirects to sign-in when unauthenticated", async ({
    page,
  }) => {
    await page.goto("/en/dashboard");
    await expect(page).toHaveURL(/\/en\/sign-in/);
  });
});

// These tests depend on each other and must run in order:
// sign-up → duplicate check → sign-in → sign-out
test.describe.serial("Authentication flows", () => {
  test("can sign up and land on dashboard", async ({ page }) => {
    await page.goto("/en/sign-up");

    await page.locator("#name").fill(testName);
    await page.locator("#email").fill(testEmail);
    await page.locator("#password").fill(testPassword);
    await page.locator("#confirmPassword").fill(testPassword);
    await page.getByRole("button", { name: "Sign Up" }).click();

    await expect(page).toHaveURL(/\/en\/dashboard/, { timeout: 30000 });
    await expect(page.locator('main p').getByText(testName)).toBeVisible();
  });

  test("duplicate email shows error", async ({ page }) => {
    await page.goto("/en/sign-up");

    await page.locator("#name").fill(testName);
    await page.locator("#email").fill(testEmail);
    await page.locator("#password").fill(testPassword);
    await page.locator("#confirmPassword").fill(testPassword);
    await page.getByRole("button", { name: "Sign Up" }).click();

    await expect(
      page.getByText(/already registered/i),
    ).toBeVisible({ timeout: 10000 });
  });

  test("already signed-in user on sign-in page is redirected to dashboard", async ({
    page,
  }) => {
    // Sign in
    await page.goto("/en/sign-in");
    await page.locator("#email").fill(testEmail);
    await page.locator("#password").fill(testPassword);
    await page.getByRole("button", { name: "Sign In" }).click();
    await expect(page).toHaveURL(/\/en\/dashboard/, { timeout: 30000 });

    // Visiting sign-in again should redirect to dashboard
    await page.goto("/en/sign-in");
    await expect(page).toHaveURL(/\/en\/dashboard/);
  });

  test("wrong credentials show error", async ({ page }) => {
    await page.goto("/en/sign-in");

    await page.locator("#email").fill(testEmail);
    await page.locator("#password").fill("WrongPassword999!");
    await page.getByRole("button", { name: "Sign In" }).click();

    await expect(
      page.getByText(/Invalid email or password/i),
    ).toBeVisible({ timeout: 10000 });
  });

  test("can sign in and sign out", async ({ page }) => {
    // Sign in
    await page.goto("/en/sign-in");
    await page.locator("#email").fill(testEmail);
    await page.locator("#password").fill(testPassword);
    await page.getByRole("button", { name: "Sign In" }).click();
    await expect(page).toHaveURL(/\/en\/dashboard/, { timeout: 30000 });

    // Sign out
    await page.getByRole("button", { name: "Sign Out" }).click();
    await expect(page).toHaveURL(/\/en($|\/)/, { timeout: 10000 });
    await expect(page.getByRole('main').getByRole("link", { name: "Sign In" })).toBeVisible();

    // Dashboard should now redirect to sign-in
    await page.goto("/en/dashboard");
    await expect(page).toHaveURL(/\/en\/sign-in/);
  });
});
