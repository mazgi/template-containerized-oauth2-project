package dev.mazgi.app

import android.content.Context
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.filterToOne
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONObject
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.ExternalResource
import org.junit.rules.RuleChain
import org.junit.runner.RunWith
import java.net.HttpURLConnection
import java.net.URL

/**
 * E2E tests for the Items screen (create, list, delete) and bottom navigation.
 *
 * Mirrors web/e2e-tests/tests/items.spec.ts scenarios:
 *   - access control (unauthenticated → stays on Sign In)
 *   - empty state
 *   - Add button disabled when input is blank
 *   - create item (appears in list, input cleared)
 *   - delete item (disappears, empty state restored)
 *   - multiple items
 *   - bottom navigation tabs (Dashboard / Items)
 *
 * Each test starts with cleared SharedPreferences. The @Before helper creates
 * a verified user via API and signs in via UI so every test begins authenticated.
 *
 * Prerequisites: the backend must be reachable at http://10.0.2.2:4000
 * and Mailpit at http://10.0.2.2:8025.
 * Run the stack with `docker compose up backend mailpit` before executing these tests.
 */
@RunWith(AndroidJUnit4::class)
class ItemsE2ETest {

    private val composeRule = createAndroidComposeRule<MainActivity>()

    // Outer rule: clear stored tokens BEFORE the Activity is launched.
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
        "e2e_items_${System.currentTimeMillis()}_${testCount++}@example.com"

    // -------------------------------------------------------------------------
    // @Before: create a verified user via API and sign in via UI
    // -------------------------------------------------------------------------

    @Before
    fun signUpAndReachDashboard() {
        val email = uniqueEmail()
        val password = "Password1!"

        // Create verified user via backend API + Mailpit
        createVerifiedUser(email, password)

        // Wait for session restore to finish → Sign In screen
        composeRule.waitUntil(15_000L) {
            composeRule.onAllNodesWithText("Don't have an account? Sign Up")
                .fetchSemanticsNodes().isNotEmpty()
        }

        // Sign in via UI
        composeRule.onNodeWithText("Email").performTextInput(email)
        composeRule.onNodeWithText("Password").performTextInput(password)
        composeRule.onAllNodesWithText("Sign In").filterToOne(hasClickAction()).performClick()

        // Wait for Dashboard
        composeRule.waitUntil(15_000L) {
            composeRule.onAllNodesWithText("Sign Out").fetchSemanticsNodes().isNotEmpty()
        }
    }

    private fun createVerifiedUser(email: String, password: String) {
        postJson("$BACKEND_URL/auth/signup", """{"email":"$email","password":"$password"}""")
        val token = getVerificationToken(email)
        postJson("$BACKEND_URL/auth/verify-email", """{"token":"$token"}""")
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
    // Helpers
    // -------------------------------------------------------------------------

    /** Navigate to the Items tab and wait for the screen to be ready. */
    private fun navigateToItems() {
        composeRule.onAllNodesWithText("Items").filterToOne(hasClickAction()).performClick()
        composeRule.waitUntil(10_000L) {
            composeRule.onAllNodesWithText("Item name").fetchSemanticsNodes().isNotEmpty()
        }
    }

    /**
     * Wait until the loading spinner is gone — i.e., either the empty state
     * ("No items yet.") or at least one Delete button is visible.
     */
    private fun waitForItemsLoaded() {
        composeRule.waitUntil(10_000L) {
            composeRule.onAllNodesWithText("No items yet.").fetchSemanticsNodes().isNotEmpty() ||
                composeRule.onAllNodesWithContentDescription("Delete")
                    .fetchSemanticsNodes().isNotEmpty()
        }
    }

    /**
     * Type [name] into the "Item name" field, click Add, and wait until the
     * item appears in the list and the input is cleared (Add button disabled).
     */
    private fun addItem(name: String) {
        composeRule.onNodeWithText("Item name").performTextInput(name)
        composeRule.onNodeWithText("Add").assertIsEnabled()
        composeRule.onNodeWithText("Add").performClick()

        // Item should appear in the list
        composeRule.waitUntil(10_000L) {
            composeRule.onAllNodesWithText(name).fetchSemanticsNodes().isNotEmpty()
        }

        // Input should be cleared (newName = "" → Add button disabled)
        composeRule.waitUntil(5_000L) {
            try {
                composeRule.onNodeWithText("Add").assertIsNotEnabled()
                true
            } catch (e: AssertionError) {
                false
            }
        }
    }

    // -------------------------------------------------------------------------
    // Items tests
    // -------------------------------------------------------------------------

    @Test
    fun items_emptyState_shownForNewUser() {
        navigateToItems()
        composeRule.waitUntil(10_000L) {
            composeRule.onAllNodesWithText("No items yet.").fetchSemanticsNodes().isNotEmpty()
        }
        composeRule.onNodeWithText("No items yet.").assertIsDisplayed()
    }

    @Test
    fun items_addButton_disabledWhenInputIsBlank() {
        navigateToItems()
        // The "Item name" field is empty on load → Add must be disabled
        composeRule.onNodeWithText("Add").assertIsNotEnabled()
    }

    @Test
    fun items_createItem_appearsInList_andInputIsCleared() {
        navigateToItems()
        waitForItemsLoaded()

        val itemName = "Test Item ${System.currentTimeMillis()}"
        composeRule.onNodeWithText("Item name").performTextInput(itemName)
        composeRule.onNodeWithText("Add").assertIsEnabled()
        composeRule.onNodeWithText("Add").performClick()

        // Item must appear in the list
        composeRule.waitUntil(10_000L) {
            composeRule.onAllNodesWithText(itemName).fetchSemanticsNodes().isNotEmpty()
        }
        composeRule.onNodeWithText(itemName).assertIsDisplayed()

        // Input must be cleared: Add button becomes disabled again
        composeRule.waitUntil(5_000L) {
            try {
                composeRule.onNodeWithText("Add").assertIsNotEnabled()
                true
            } catch (e: AssertionError) {
                false
            }
        }
        composeRule.onNodeWithText("Add").assertIsNotEnabled()
    }

    @Test
    fun items_deleteItem_disappears_andEmptyStateRestored() {
        navigateToItems()
        waitForItemsLoaded()

        val itemName = "Item to Delete ${System.currentTimeMillis()}"
        addItem(itemName)
        composeRule.onNodeWithText(itemName).assertIsDisplayed()

        // Delete the item
        composeRule.onNodeWithContentDescription("Delete").performClick()

        // Empty state must be restored
        composeRule.waitUntil(10_000L) {
            composeRule.onAllNodesWithText("No items yet.").fetchSemanticsNodes().isNotEmpty()
        }
        composeRule.onNodeWithText("No items yet.").assertIsDisplayed()
    }

    @Test
    fun items_multipleItems_allShown() {
        navigateToItems()
        waitForItemsLoaded()

        val ts = System.currentTimeMillis()
        val item1 = "Alpha $ts"
        val item2 = "Beta $ts"
        val item3 = "Gamma $ts"

        addItem(item1)
        addItem(item2)
        addItem(item3)

        composeRule.onNodeWithText(item1).assertIsDisplayed()
        composeRule.onNodeWithText(item2).assertIsDisplayed()
        composeRule.onNodeWithText(item3).assertIsDisplayed()
    }

    // -------------------------------------------------------------------------
    // Navigation tests
    // -------------------------------------------------------------------------

    @Test
    fun navigation_bottomTabs_switchBetweenDashboardAndItems() {
        // @Before lands us on Dashboard — Sign Out button is visible
        composeRule.onNodeWithText("Sign Out").assertIsDisplayed()

        // Navigate to Items via bottom tab
        composeRule.onAllNodesWithText("Items").filterToOne(hasClickAction()).performClick()
        composeRule.waitUntil(10_000L) {
            composeRule.onAllNodesWithText("Item name").fetchSemanticsNodes().isNotEmpty()
        }
        // "Item name" input visible → we are on the Items screen, not Dashboard
        composeRule.onNodeWithText("Item name").assertIsDisplayed()

        // Navigate back to Dashboard via bottom tab
        composeRule.onAllNodesWithText("Dashboard").filterToOne(hasClickAction()).performClick()
        composeRule.waitUntil(5_000L) {
            composeRule.onAllNodesWithText("Sign Out").fetchSemanticsNodes().isNotEmpty()
        }
        composeRule.onNodeWithText("Sign Out").assertIsDisplayed()
    }
}
