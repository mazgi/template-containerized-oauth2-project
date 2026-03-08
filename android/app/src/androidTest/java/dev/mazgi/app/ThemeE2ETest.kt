package dev.mazgi.app

import android.content.Context
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsSelected
import androidx.compose.ui.test.assertIsNotSelected
import androidx.compose.ui.test.filterToOne
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithTag
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
 * E2E tests for theme settings.
 *
 * Tests the theme picker (System/Light/Dark) on the Settings screen.
 * Each test starts with cleared SharedPreferences and a fresh sign-up.
 *
 * Prerequisites: the backend must be reachable at http://10.0.2.2:4000.
 */
@RunWith(AndroidJUnit4::class)
class ThemeE2ETest {

    private val composeRule = createAndroidComposeRule<MainActivity>()

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
        "e2e_theme_${System.currentTimeMillis()}_${testCount++}@example.com"

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private fun waitForSignInScreen() {
        composeRule.waitUntil(15_000L) {
            composeRule.onAllNodesWithText("Don't have an account? Sign Up")
                .fetchSemanticsNodes().isNotEmpty()
        }
    }

    private fun navigateToSignUp() {
        composeRule.onNodeWithText("Don't have an account? Sign Up").performClick()
        composeRule.waitUntil(5_000L) {
            composeRule.onAllNodesWithText("Confirm Password")
                .fetchSemanticsNodes().isNotEmpty()
        }
    }

    private fun waitForDashboard() {
        composeRule.waitUntil(15_000L) {
            composeRule.onAllNodesWithText("Sign Out").fetchSemanticsNodes().isNotEmpty()
        }
    }

    private fun signUpAndNavigateToSettings(email: String = uniqueEmail()) {
        waitForSignInScreen()
        navigateToSignUp()
        composeRule.onNodeWithText("Email").performTextInput(email)
        composeRule.onNodeWithText("Password").performTextInput("Password1!")
        composeRule.onNodeWithText("Confirm Password").performTextInput("Password1!")
        composeRule.onAllNodesWithText("Sign Up").filterToOne(hasClickAction()).performClick()
        waitForDashboard()
        // Navigate to Settings tab
        composeRule.onNodeWithText("Settings").performClick()
        composeRule.waitUntil(5_000L) {
            composeRule.onAllNodesWithText("Theme").fetchSemanticsNodes().isNotEmpty()
        }
    }

    // -------------------------------------------------------------------------
    // Tests
    // -------------------------------------------------------------------------

    @Test
    fun themePicker_isVisible() {
        signUpAndNavigateToSettings()
        composeRule.onNodeWithText("Theme").assertIsDisplayed()
        composeRule.onNodeWithTag("settings_themePicker").assertIsDisplayed()
    }

    @Test
    fun themePicker_showsAllOptions() {
        signUpAndNavigateToSettings()
        composeRule.onNodeWithTag("theme_system").assertIsDisplayed()
        composeRule.onNodeWithTag("theme_light").assertIsDisplayed()
        composeRule.onNodeWithTag("theme_dark").assertIsDisplayed()
    }

    @Test
    fun themePicker_defaultIsSystem() {
        signUpAndNavigateToSettings()
        composeRule.onNodeWithTag("theme_system").assertIsSelected()
        composeRule.onNodeWithTag("theme_light").assertIsNotSelected()
        composeRule.onNodeWithTag("theme_dark").assertIsNotSelected()
    }

    @Test
    fun themePicker_switchToDark() {
        signUpAndNavigateToSettings()
        composeRule.onNodeWithTag("theme_dark").performClick()
        composeRule.waitForIdle()
        composeRule.onNodeWithTag("theme_dark").assertIsSelected()
        composeRule.onNodeWithTag("theme_system").assertIsNotSelected()
    }

    @Test
    fun themePicker_switchToLight() {
        signUpAndNavigateToSettings()
        composeRule.onNodeWithTag("theme_light").performClick()
        composeRule.waitForIdle()
        composeRule.onNodeWithTag("theme_light").assertIsSelected()
        composeRule.onNodeWithTag("theme_system").assertIsNotSelected()
    }

    @Test
    fun themePicker_cycleAllModes() {
        signUpAndNavigateToSettings()

        // Default: System
        composeRule.onNodeWithTag("theme_system").assertIsSelected()

        // Switch to Dark
        composeRule.onNodeWithTag("theme_dark").performClick()
        composeRule.waitForIdle()
        composeRule.onNodeWithTag("theme_dark").assertIsSelected()

        // Switch to Light
        composeRule.onNodeWithTag("theme_light").performClick()
        composeRule.waitForIdle()
        composeRule.onNodeWithTag("theme_light").assertIsSelected()

        // Back to System
        composeRule.onNodeWithTag("theme_system").performClick()
        composeRule.waitForIdle()
        composeRule.onNodeWithTag("theme_system").assertIsSelected()
    }
}
