package dev.mazgi.app

import android.content.Context
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.filterToOne
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Rule
import org.junit.Test
import org.junit.rules.ExternalResource
import org.junit.rules.RuleChain
import org.junit.runner.RunWith

/**
 * E2E tests for authentication flows.
 *
 * Mirrors web/e2e-tests/tests/auth.spec.ts scenarios:
 *   - sign-up (success, password mismatch, duplicate email)
 *   - sign-in (success, wrong password, non-existent email)
 *   - navigation between Sign In / Sign Up screens
 *   - sign-out
 *
 * Each test starts with cleared SharedPreferences (no stored tokens) so the app
 * shows the Sign In screen. The Activity is launched fresh for every test by
 * RuleChain: clearPrefsRule (outer) → composeRule (inner).
 *
 * Prerequisites: the backend must be reachable at http://10.0.2.2:4000.
 * Run the stack with `docker compose up` before executing these tests.
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
            composeRule.onAllNodesWithText("Confirm Password")
                .fetchSemanticsNodes().isNotEmpty()
        }
    }

    /** Wait until the Dashboard screen is shown (Sign Out button visible). */
    private fun waitForDashboard() {
        composeRule.waitUntil(15_000L) {
            composeRule.onAllNodesWithText("Sign Out").fetchSemanticsNodes().isNotEmpty()
        }
    }

    /**
     * Complete the Sign Up flow via the UI and land on Dashboard.
     * Navigates from the Sign In screen → Sign Up → fills the form → submits → waits.
     */
    private fun signUpViaUi(email: String, password: String = "Password1!") {
        navigateToSignUp()
        composeRule.onNodeWithText("Email").performTextInput(email)
        composeRule.onNodeWithText("Password").performTextInput(password)
        composeRule.onNodeWithText("Confirm Password").performTextInput(password)
        composeRule.onAllNodesWithText("Sign Up").filterToOne(hasClickAction()).performClick()
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
        composeRule.onNodeWithText("Confirm Password").performTextInput("Password1!")
        composeRule.onAllNodesWithText("Sign Up").filterToOne(hasClickAction()).performClick()

        waitForDashboard()
        // Dashboard is shown: Sign Out button and the registered email are visible
        composeRule.onNodeWithText("Sign Out").assertIsDisplayed()
        composeRule.onNodeWithText(email).assertIsDisplayed()
    }

    @Test
    fun signUp_passwordMismatch_showsError_andDisablesButton() {
        waitForSignInScreen()
        navigateToSignUp()

        composeRule.onNodeWithText("Email").performTextInput(uniqueEmail())
        composeRule.onNodeWithText("Password").performTextInput("Password1!")
        composeRule.onNodeWithText("Confirm Password").performTextInput("Different1!")

        // Inline error message from SignUpScreen
        composeRule.onNodeWithText("Passwords do not match").assertIsDisplayed()
        // Sign Up button must be disabled (client-side guard, no API call)
        composeRule.onAllNodesWithText("Sign Up")
            .filterToOne(hasClickAction())
            .assertIsNotEnabled()
    }

    @Test
    fun signUp_duplicateEmail_showsError() {
        waitForSignInScreen()
        val email = uniqueEmail()

        // First sign-up succeeds
        signUpViaUi(email)
        signOut()

        // Second sign-up with the same email
        navigateToSignUp()
        composeRule.onNodeWithText("Email").performTextInput(email)
        composeRule.onNodeWithText("Password").performTextInput("Password1!")
        composeRule.onNodeWithText("Confirm Password").performTextInput("Password1!")
        composeRule.onAllNodesWithText("Sign Up").filterToOne(hasClickAction()).performClick()

        // Wait for the API call to complete (button becomes enabled on error)
        waitForButtonEnabled("Sign Up")

        // Must still be on Sign Up screen — not navigated to Dashboard
        composeRule.onNodeWithText("Confirm Password").assertIsDisplayed()
    }

    // -------------------------------------------------------------------------
    // Sign In tests
    // -------------------------------------------------------------------------

    @Test
    fun signIn_success() {
        waitForSignInScreen()
        val email = uniqueEmail()
        val password = "Password1!"

        signUpViaUi(email, password)
        signOut()

        // Sign in with correct credentials
        composeRule.onNodeWithText("Email").performTextInput(email)
        composeRule.onNodeWithText("Password").performTextInput(password)
        composeRule.onAllNodesWithText("Sign In").filterToOne(hasClickAction()).performClick()

        waitForDashboard()
        // Dashboard is shown: Sign Out button and the signed-in email are visible
        composeRule.onNodeWithText("Sign Out").assertIsDisplayed()
        composeRule.onNodeWithText(email).assertIsDisplayed()
    }

    @Test
    fun signIn_wrongPassword_showsError() {
        waitForSignInScreen()
        val email = uniqueEmail()

        signUpViaUi(email)
        signOut()

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
        composeRule.onNodeWithText("Don't have an account? Sign Up").performClick()

        composeRule.waitUntil(5_000L) {
            composeRule.onAllNodesWithText("Confirm Password").fetchSemanticsNodes().isNotEmpty()
        }

        composeRule.onNodeWithText("Confirm Password").assertIsDisplayed()
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
    // Sign Out test
    // -------------------------------------------------------------------------

    @Test
    fun signOut_returnsToSignInScreen() {
        waitForSignInScreen()
        signUpViaUi(uniqueEmail())

        composeRule.onNodeWithText("Sign Out").performClick()
        waitForSignInScreen()

        composeRule.onNodeWithText("Don't have an account? Sign Up").assertIsDisplayed()
    }
}
