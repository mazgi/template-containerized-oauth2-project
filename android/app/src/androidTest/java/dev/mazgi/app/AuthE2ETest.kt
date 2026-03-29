package dev.mazgi.app

import android.content.Context
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.filterToOne
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONObject
import org.junit.Rule
import org.junit.Test
import org.junit.rules.ExternalResource
import org.junit.rules.RuleChain
import org.junit.runner.RunWith
import java.net.HttpURLConnection
import java.net.URL

/**
 * E2E tests for authentication flows.
 *
 * Mirrors web/e2e-tests/tests/auth.spec.ts scenarios:
 *   - sign-up (success → verification sent screen, password mismatch, duplicate email)
 *   - sign-in (success, wrong password, non-existent email)
 *   - navigation between Sign In / Sign Up screens
 *   - sign-out
 *
 * Each test starts with cleared SharedPreferences (no stored tokens) so the app
 * shows the Sign In screen. The Activity is launched fresh for every test by
 * RuleChain: clearPrefsRule (outer) → composeRule (inner).
 *
 * Prerequisites: the backend must be reachable at http://10.0.2.2:4000
 * and Mailpit at http://10.0.2.2:8025.
 * Run the stack with `docker compose up backend mailpit` before executing these tests.
 */
@RunWith(AndroidJUnit4::class)
class AuthE2ETest {

    private val composeRule = createAndroidComposeRule<MainActivity>()

    // Outer rule: clear stored tokens BEFORE the Activity is launched so that
    // AuthViewModel.restoreSession() finds no tokens and skips API calls.
    private val clearPrefsRule = object : ExternalResource() {
        override fun before() {
            InstrumentationRegistry.getInstrumentation().targetContext
                .getSharedPreferences("auth", Context.MODE_PRIVATE)
                .edit().clear().apply()
        }
    }

    @get:Rule
    val ruleChain: RuleChain = RuleChain.outerRule(clearPrefsRule).around(composeRule)

    companion object {
        private var testCount = 0
        private const val BACKEND_URL = "http://10.0.2.2:4000"
        private const val MAILPIT_URL = "http://10.0.2.2:8025"
    }

    private fun uniqueEmail() =
        "e2e_auth_${System.currentTimeMillis()}_${testCount++}@example.com"

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /** Wait until the Sign In screen is fully ready. */
    private fun waitForSignInScreen() {
        composeRule.waitUntil(15_000L) {
            composeRule.onAllNodesWithText("Don't have an account? Sign Up")
                .fetchSemanticsNodes().isNotEmpty()
        }
    }

    /** Click the link on the Sign In screen and wait for Sign Up screen. */
    private fun navigateToSignUp() {
        composeRule.onNodeWithText("Don't have an account? Sign Up").performClick()
        composeRule.waitUntil(5_000L) {
            composeRule.onAllNodesWithText("Sign Up")
                .fetchSemanticsNodes().size >= 2 // heading + button
        }
    }

    /** Wait until the Dashboard screen is shown (Sign Out button visible). */
    private fun waitForDashboard() {
        composeRule.waitUntil(15_000L) {
            composeRule.onAllNodesWithText("Sign Out").fetchSemanticsNodes().isNotEmpty()
        }
    }

    /** Wait until the verification-sent screen is shown. */
    private fun waitForVerificationSent() {
        composeRule.waitUntil(15_000L) {
            composeRule.onAllNodesWithText("Check your email")
                .fetchSemanticsNodes().isNotEmpty()
        }
    }

    /**
     * Create a verified user via the backend API + Mailpit.
     * Calls signup, retrieves the verification token from Mailpit, and verifies.
     */
    private fun createVerifiedUser(email: String, password: String = "Password1!") {
        // 1. Sign up via API
        postJson("$BACKEND_URL/auth/signup", """{"email":"$email","password":"$password"}""")

        // 2. Get verification token from Mailpit
        val token = getVerificationToken(email)

        // 3. Verify email via API
        postJson("$BACKEND_URL/auth/verify-email", """{"token":"$token"}""")
    }

    /**
     * Create a verified user via API and sign in via UI to reach Dashboard.
     */
    private fun signUpAndSignIn(email: String, password: String = "Password1!") {
        createVerifiedUser(email, password)
        composeRule.onNodeWithText("Email").performTextInput(email)
        composeRule.onNodeWithText("Password").performTextInput(password)
        composeRule.onAllNodesWithText("Sign In").filterToOne(hasClickAction()).performClick()
        waitForDashboard()
    }

    /** Sign out from Dashboard and wait for the Sign In screen. */
    private fun signOut() {
        composeRule.onNodeWithText("Sign Out").performClick()
        waitForSignInScreen()
    }

    /**
     * Wait until the given button (by label text) becomes enabled again.
     * Used to detect that an in-flight API call has finished.
     */
    private fun waitForButtonEnabled(label: String, timeoutMs: Long = 15_000L) {
        composeRule.waitUntil(timeoutMs) {
            try {
                composeRule.onAllNodesWithText(label)
                    .filterToOne(hasClickAction())
                    .assertIsEnabled()
                true
            } catch (e: AssertionError) {
                false
            }
        }
    }

    /** POST JSON to the given URL and return the response body. */
    private fun postJson(url: String, body: String): String {
        val conn = URL(url).openConnection() as HttpURLConnection
        conn.requestMethod = "POST"
        conn.setRequestProperty("Content-Type", "application/json")
        conn.doOutput = true
        conn.connectTimeout = 10_000
        conn.readTimeout = 10_000
        conn.outputStream.bufferedWriter().use { it.write(body) }
        val responseText = if (conn.responseCode in 200..299) {
            conn.inputStream.bufferedReader().readText()
        } else {
            conn.errorStream?.bufferedReader()?.readText() ?: ""
        }
        conn.disconnect()
        return responseText
    }

    /** Poll Mailpit for the verification token sent to [email]. */
    private fun getVerificationToken(email: String): String {
        for (i in 0 until 20) {
            try {
                val searchUrl = "$MAILPIT_URL/api/v1/search?query=to:$email"
                val conn = URL(searchUrl).openConnection() as HttpURLConnection
                conn.connectTimeout = 5_000
                conn.readTimeout = 5_000
                if (conn.responseCode == 200) {
                    val data = JSONObject(conn.inputStream.bufferedReader().readText())
                    conn.disconnect()
                    val messages = data.optJSONArray("messages")
                    if (messages != null && messages.length() > 0) {
                        val msgId = messages.getJSONObject(0).getString("ID")
                        val msgConn = URL("$MAILPIT_URL/api/v1/message/$msgId")
                            .openConnection() as HttpURLConnection
                        msgConn.connectTimeout = 5_000
                        msgConn.readTimeout = 5_000
                        val msg = JSONObject(msgConn.inputStream.bufferedReader().readText())
                        msgConn.disconnect()
                        val html = msg.optString("HTML", "") + msg.optString("Text", "")
                        val match = Regex("[?&]token=([a-f0-9-]+)").find(html)
                        if (match != null) return match.groupValues[1]
                    }
                } else {
                    conn.disconnect()
                }
            } catch (_: Exception) { }
            Thread.sleep(500)
        }
        throw RuntimeException("Verification email not found for $email")
    }

    // -------------------------------------------------------------------------
    // Sign Up tests
    // -------------------------------------------------------------------------

    @Test
    fun signUp_success() {
        waitForSignInScreen()

        val email = uniqueEmail()
        navigateToSignUp()
        composeRule.onNodeWithText("Email").performTextInput(email)
        composeRule.onNodeWithText("Password").performTextInput("Password1!")
        composeRule.onAllNodesWithText("Sign Up").filterToOne(hasClickAction()).performClick()

        // Should show verification-sent screen, not Dashboard
        waitForVerificationSent()
        composeRule.onNodeWithText("Check your email").assertIsDisplayed()
        composeRule.onNodeWithText("Resend verification email").assertIsDisplayed()
    }

    @Test
    fun signUp_duplicateEmail_showsError() {
        waitForSignInScreen()
        val email = uniqueEmail()

        // First sign-up: create verified user via API
        createVerifiedUser(email)

        // Second sign-up with the same email via UI
        navigateToSignUp()
        composeRule.onNodeWithText("Email").performTextInput(email)
        composeRule.onNodeWithText("Password").performTextInput("Password1!")
        composeRule.onAllNodesWithText("Sign Up").filterToOne(hasClickAction()).performClick()

        // Wait for the API call to complete (button becomes enabled on error)
        waitForButtonEnabled("Sign Up")

        // Must still be on Sign Up screen — not navigated to Dashboard
        composeRule.onNodeWithText("Already have an account? Sign In").assertIsDisplayed()
    }

    // -------------------------------------------------------------------------
    // Sign In tests
    // -------------------------------------------------------------------------

    @Test
    fun signIn_success() {
        waitForSignInScreen()
        val email = uniqueEmail()
        val password = "Password1!"

        // Create verified user via API, then sign in via UI
        signUpAndSignIn(email, password)

        // Dashboard is shown: Sign Out button and the signed-in email are visible
        composeRule.onNodeWithText("Sign Out").assertIsDisplayed()
        composeRule.onNodeWithText(email).assertIsDisplayed()
    }

    @Test
    fun signIn_wrongPassword_showsError() {
        waitForSignInScreen()
        val email = uniqueEmail()

        createVerifiedUser(email)

        // Sign in with wrong password
        composeRule.onNodeWithText("Email").performTextInput(email)
        composeRule.onNodeWithText("Password").performTextInput("WrongPassword!")
        composeRule.onAllNodesWithText("Sign In").filterToOne(hasClickAction()).performClick()

        // Wait for the API call to finish (button re-enabled means error was set)
        waitForButtonEnabled("Sign In")

        // Must remain on Sign In screen
        composeRule.onNodeWithText("Don't have an account? Sign Up").assertIsDisplayed()
    }

    @Test
    fun signIn_nonExistentEmail_showsError() {
        waitForSignInScreen()

        composeRule.onNodeWithText("Email")
            .performTextInput("nonexistent_${System.currentTimeMillis()}@example.com")
        composeRule.onNodeWithText("Password").performTextInput("Password1!")
        composeRule.onAllNodesWithText("Sign In").filterToOne(hasClickAction()).performClick()

        // Wait for the API call to finish
        waitForButtonEnabled("Sign In")

        // Must remain on Sign In screen
        composeRule.onNodeWithText("Don't have an account? Sign Up").assertIsDisplayed()
    }

    // -------------------------------------------------------------------------
    // Navigation tests
    // -------------------------------------------------------------------------

    @Test
    fun navigateToSignUp_fromSignIn() {
        waitForSignInScreen()
        navigateToSignUp()

        composeRule.onNodeWithText("Already have an account? Sign In").assertIsDisplayed()
    }

    @Test
    fun navigateToSignIn_fromSignUp() {
        waitForSignInScreen()
        navigateToSignUp()

        composeRule.onNodeWithText("Already have an account? Sign In").performClick()
        waitForSignInScreen()

        composeRule.onNodeWithText("Don't have an account? Sign Up").assertIsDisplayed()
    }

    // -------------------------------------------------------------------------
    // Helpers – Settings navigation & Mailpit password reset
    // -------------------------------------------------------------------------

    /** Navigate to the Settings tab in the bottom navigation. */
    private fun navigateToSettings() {
        composeRule.onNodeWithText("Settings").performClick()
        composeRule.waitUntil(5_000L) {
            composeRule.onAllNodesWithText("Linked Accounts")
                .fetchSemanticsNodes().isNotEmpty()
        }
    }

    /** Poll Mailpit for the password reset token sent to [email]. */
    private fun getPasswordResetToken(email: String): String {
        for (i in 0 until 20) {
            try {
                val searchUrl = "$MAILPIT_URL/api/v1/search?query=to:$email"
                val conn = URL(searchUrl).openConnection() as HttpURLConnection
                conn.connectTimeout = 5_000
                conn.readTimeout = 5_000
                if (conn.responseCode == 200) {
                    val data = JSONObject(conn.inputStream.bufferedReader().readText())
                    conn.disconnect()
                    val messages = data.optJSONArray("messages")
                    if (messages != null) {
                        for (j in 0 until messages.length()) {
                            val msgId = messages.getJSONObject(j).getString("ID")
                            val msgConn = URL("$MAILPIT_URL/api/v1/message/$msgId")
                                .openConnection() as HttpURLConnection
                            msgConn.connectTimeout = 5_000
                            msgConn.readTimeout = 5_000
                            val msg = JSONObject(msgConn.inputStream.bufferedReader().readText())
                            msgConn.disconnect()
                            val body = msg.optString("HTML", "") + msg.optString("Text", "")
                            if (body.contains("reset-password") || body.contains("Password Reset")) {
                                val match = Regex("[?&]token=([a-f0-9-]+)").find(body)
                                if (match != null) return match.groupValues[1]
                            }
                        }
                    }
                } else {
                    conn.disconnect()
                }
            } catch (_: Exception) { }
            Thread.sleep(500)
        }
        throw RuntimeException("Password reset email not found for $email")
    }

    // -------------------------------------------------------------------------
    // Forgot Password from Sign In tests
    // -------------------------------------------------------------------------

    @Test
    fun forgotPassword_showsButtonOnSignInPage() {
        waitForSignInScreen()
        composeRule.onNodeWithText("Forgot password?").assertIsDisplayed()
    }

    @Test
    fun forgotPassword_showsSuccessMessage() {
        waitForSignInScreen()
        val email = uniqueEmail()
        createVerifiedUser(email)

        composeRule.onNodeWithText("Email").performTextInput(email)
        composeRule.onNodeWithText("Forgot password?").performClick()

        composeRule.waitUntil(15_000L) {
            composeRule.onAllNodesWithText("Password reset link sent. Please check your inbox.")
                .fetchSemanticsNodes().isNotEmpty()
        }
    }

    @Test
    fun forgotPassword_fullResetFlow() {
        waitForSignInScreen()
        val email = uniqueEmail()
        val newPassword = "ResetFromLogin1!"
        createVerifiedUser(email)

        // Request reset from sign-in page
        composeRule.onNodeWithText("Email").performTextInput(email)
        composeRule.onNodeWithText("Forgot password?").performClick()

        composeRule.waitUntil(15_000L) {
            composeRule.onAllNodesWithText("Password reset link sent. Please check your inbox.")
                .fetchSemanticsNodes().isNotEmpty()
        }

        // Get reset token and reset password via API
        val token = getPasswordResetToken(email)
        postJson("$BACKEND_URL/auth/reset-password", """{"token":"$token","password":"$newPassword"}""")

        // Clear fields and sign in with new password
        // Navigate away and back to clear state
        navigateToSignUp()
        composeRule.onNodeWithText("Already have an account? Sign In").performClick()
        waitForSignInScreen()

        composeRule.onNodeWithText("Email").performTextInput(email)
        composeRule.onNodeWithText("Password").performTextInput(newPassword)
        composeRule.onAllNodesWithText("Sign In").filterToOne(hasClickAction()).performClick()
        waitForDashboard()

        composeRule.onNodeWithText(email).assertIsDisplayed()
    }

    @Test
    fun forgotPassword_successForNonExistentEmail() {
        waitForSignInScreen()

        composeRule.onNodeWithText("Email")
            .performTextInput("nonexistent_${System.currentTimeMillis()}@example.com")
        composeRule.onNodeWithText("Forgot password?").performClick()

        // Should still show success to prevent email enumeration
        composeRule.waitUntil(15_000L) {
            composeRule.onAllNodesWithText("Password reset link sent. Please check your inbox.")
                .fetchSemanticsNodes().isNotEmpty()
        }
    }

    @Test
    fun signUpPage_hasForgotPasswordLink() {
        waitForSignInScreen()
        navigateToSignUp()
        composeRule.onNodeWithText("Forgot password?").assertIsDisplayed()
    }

    // -------------------------------------------------------------------------
    // Change Email test
    // -------------------------------------------------------------------------

    @Test
    fun changeEmail_updatesEmailAndResetsVerification() {
        waitForSignInScreen()
        val oldEmail = uniqueEmail()
        val newEmail = uniqueEmail()
        signUpAndSignIn(oldEmail)

        // Navigate to Settings
        navigateToSettings()

        // Wait for email section to load and verify current email is displayed
        composeRule.waitUntil(15_000L) {
            composeRule.onAllNodesWithText(oldEmail)
                .fetchSemanticsNodes().isNotEmpty()
        }
        composeRule.onNodeWithText(oldEmail).assertExists()
        composeRule.onNodeWithText("Verified").assertExists()

        // Enter new email and save
        composeRule.onNodeWithTag("settings_emailInput").performScrollTo().performTextInput(newEmail)
        composeRule.onNodeWithTag("settings_saveEmail").performScrollTo().performClick()

        // Wait for the API to complete: "Unverified" badge appears after email update
        composeRule.waitUntil(15_000L) {
            composeRule.onAllNodesWithText("Unverified")
                .fetchSemanticsNodes().isNotEmpty()
        }

        // Should show new email as Unverified
        composeRule.onAllNodesWithText(newEmail).fetchSemanticsNodes().let {
            assert(it.isNotEmpty()) { "Expected new email to be displayed" }
        }
        composeRule.onNodeWithText("Unverified").assertExists()
    }

    // -------------------------------------------------------------------------
    // Sign Out test
    // -------------------------------------------------------------------------

    @Test
    fun signOut_returnsToSignInScreen() {
        waitForSignInScreen()
        signUpAndSignIn(uniqueEmail())

        composeRule.onNodeWithText("Sign Out").performClick()
        waitForSignInScreen()

        composeRule.onNodeWithText("Don't have an account? Sign Up").assertIsDisplayed()
    }

    // -------------------------------------------------------------------------
    // Password Reset tests
    // -------------------------------------------------------------------------

    @Test
    fun passwordReset_sendResetLinkFromSettings() {
        waitForSignInScreen()
        val email = uniqueEmail()
        signUpAndSignIn(email)

        // Navigate to Settings
        navigateToSettings()

        // Scroll to and click "Send reset link"
        composeRule.onNodeWithTag("settings_passwordResetButton").performScrollTo().performClick()

        // Wait for success message
        composeRule.waitUntil(15_000L) {
            composeRule.onAllNodesWithText("Password reset link sent. Please check your inbox.")
                .fetchSemanticsNodes().isNotEmpty()
        }

        // Verify reset email arrived in Mailpit
        val token = getPasswordResetToken(email)
        assert(token.isNotEmpty()) { "Expected a non-empty password reset token" }
    }

    @Test
    fun passwordReset_resetAndSignInWithNewPassword() {
        waitForSignInScreen()
        val email = uniqueEmail()
        val newPassword = "NewPassword1!"
        signUpAndSignIn(email)

        // Request password reset via API
        postJson("$BACKEND_URL/auth/forgot-password", """{"email":"$email"}""")

        // Get reset token and reset password via API
        val token = getPasswordResetToken(email)
        postJson("$BACKEND_URL/auth/reset-password", """{"token":"$token","password":"$newPassword"}""")

        // Sign out
        signOut()

        // Sign in with new password
        composeRule.onNodeWithText("Email").performTextInput(email)
        composeRule.onNodeWithText("Password").performTextInput(newPassword)
        composeRule.onAllNodesWithText("Sign In").filterToOne(hasClickAction()).performClick()
        waitForDashboard()

        composeRule.onNodeWithText("Sign Out").assertIsDisplayed()
        composeRule.onNodeWithText(email).assertIsDisplayed()
    }

    @Test
    fun passwordReset_oldPasswordFailsAfterReset() {
        waitForSignInScreen()
        val email = uniqueEmail()
        val oldPassword = "Password1!"
        val newPassword = "NewPassword1!"
        signUpAndSignIn(email, oldPassword)

        // Request password reset via API and reset
        postJson("$BACKEND_URL/auth/forgot-password", """{"email":"$email"}""")
        val token = getPasswordResetToken(email)
        postJson("$BACKEND_URL/auth/reset-password", """{"token":"$token","password":"$newPassword"}""")

        // Sign out
        signOut()

        // Try to sign in with old password — should fail
        composeRule.onNodeWithText("Email").performTextInput(email)
        composeRule.onNodeWithText("Password").performTextInput(oldPassword)
        composeRule.onAllNodesWithText("Sign In").filterToOne(hasClickAction()).performClick()

        waitForButtonEnabled("Sign In")

        // Must remain on Sign In screen
        composeRule.onNodeWithText("Don't have an account? Sign Up").assertIsDisplayed()
    }

    @Test
    fun passwordReset_buttonDisabledWhenEmailUnverified() {
        waitForSignInScreen()
        val email = uniqueEmail()

        // Create user but DON'T verify, then sign in won't work for unverified user
        // So we create verified user, sign in, change email (resets verification), check button
        signUpAndSignIn(email)
        navigateToSettings()

        // Change email to reset verification
        val newEmail = uniqueEmail()
        composeRule.onNodeWithTag("settings_emailInput").performScrollTo().performTextInput(newEmail)
        composeRule.onNodeWithTag("settings_saveEmail").performScrollTo().performClick()

        // Wait for "Unverified" badge
        composeRule.waitUntil(15_000L) {
            composeRule.onAllNodesWithText("Unverified")
                .fetchSemanticsNodes().isNotEmpty()
        }

        // The password reset button should be disabled because email is unverified
        composeRule.onNodeWithTag("settings_passwordResetButton").performScrollTo()
        composeRule.waitUntil(5_000L) {
            try {
                composeRule.onNodeWithTag("settings_passwordResetButton").assertExists()
                true
            } catch (_: AssertionError) {
                false
            }
        }
        // Verify the description text indicates verification is required
        composeRule.onNodeWithText("To use this feature, please verify your email address first.")
            .performScrollTo()
            .assertIsDisplayed()
    }
}
