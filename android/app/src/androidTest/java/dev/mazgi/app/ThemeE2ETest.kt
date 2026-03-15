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
 * E2E tests for theme settings.
 *
 * Tests the theme picker (System/Light/Dark) on the Settings screen.
 * Each test starts with cleared SharedPreferences. A verified user is
 * created via API and signed in via UI.
 *
 * Prerequisites: the backend must be reachable at http://10.0.2.2:4000
 * and Mailpit at http://10.0.2.2:8025.
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
        private const val BACKEND_URL = "http://10.0.2.2:4000"
        private const val MAILPIT_URL = "http://10.0.2.2:8025"
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

    private fun waitForDashboard() {
        composeRule.waitUntil(15_000L) {
            composeRule.onAllNodesWithText("Sign Out").fetchSemanticsNodes().isNotEmpty()
        }
    }

    private fun createVerifiedUser(email: String, password: String = "Password1!") {
        postJson("$BACKEND_URL/auth/signup", """{"email":"$email","password":"$password"}""")
        val token = getVerificationToken(email)
        postJson("$BACKEND_URL/auth/verify-email", """{"token":"$token"}""")
    }

    private fun signUpAndNavigateToSettings(email: String = uniqueEmail()) {
        val password = "Password1!"
        createVerifiedUser(email, password)

        waitForSignInScreen()
        composeRule.onNodeWithText("Email").performTextInput(email)
        composeRule.onNodeWithText("Password").performTextInput(password)
        composeRule.onAllNodesWithText("Sign In").filterToOne(hasClickAction()).performClick()
        waitForDashboard()

        // Navigate to Settings tab
        composeRule.onNodeWithText("Settings").performClick()
        composeRule.waitUntil(5_000L) {
            composeRule.onAllNodesWithText("Theme").fetchSemanticsNodes().isNotEmpty()
        }

        // Scroll the theme picker into view (Email section may push it off-screen)
        composeRule.onNodeWithTag("settings_themePicker").performScrollTo()
    }

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
