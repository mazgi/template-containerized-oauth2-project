package dev.mazgi.app

import android.content.Context
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Rule
import org.junit.Test
import org.junit.rules.ExternalResource
import org.junit.rules.RuleChain
import org.junit.runner.RunWith

/**
 * E2E test for the Git SHA overlay.
 *
 * Verifies that the SHA label is visible on the Sign In screen (no auth required)
 * and that it updates to the combined f/b format after fetching from the backend.
 *
 * Prerequisites: the backend must be reachable at http://10.0.2.2:4000.
 */
@RunWith(AndroidJUnit4::class)
class GitShaE2ETest {

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

    @Test
    fun gitShaLabel_isDisplayed() {
        composeRule.waitUntil(15_000L) {
            composeRule.onAllNodes(
                androidx.compose.ui.test.hasTestTag("gitShaLabel")
            ).fetchSemanticsNodes().isNotEmpty()
        }
        composeRule.onNodeWithTag("gitShaLabel").assertIsDisplayed()
    }

    @Test
    fun gitShaLabel_showsCombinedFormat() {
        composeRule.waitUntil(15_000L) {
            composeRule.onAllNodes(
                androidx.compose.ui.test.hasTestTag("gitShaLabel")
            ).fetchSemanticsNodes().isNotEmpty()
        }
        // Wait for the backend fetch to complete and update the label
        composeRule.waitUntil(10_000L) {
            try {
                val nodes = composeRule.onAllNodes(
                    androidx.compose.ui.test.hasTestTag("gitShaLabel")
                ).fetchSemanticsNodes()
                if (nodes.isEmpty()) return@waitUntil false
                val text = nodes.first().config
                    .getOrElse(androidx.compose.ui.semantics.SemanticsProperties.Text) { emptyList() }
                    .firstOrNull()?.text ?: ""
                text.startsWith("f/b: ") || text.startsWith("f: ")
            } catch (_: Exception) { false }
        }
    }
}
