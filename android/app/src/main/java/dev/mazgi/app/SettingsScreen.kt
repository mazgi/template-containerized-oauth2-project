package dev.mazgi.app

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.BorderStroke
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp

@Composable
fun SettingsScreen(
    uiState: AuthUiState,
    onLinkProvider: (String) -> Unit,
    onUnlinkProvider: (String) -> Unit,
    onDeleteAccount: () -> Unit,
    onSetTheme: (ThemeMode) -> Unit = {},
) {
    var showDeleteDialog by remember { mutableStateOf(false) }
    val providers = listOf(
        "apple" to "Apple",
        "discord" to "Discord",
        "github" to "GitHub",
        "google" to "Google",
        "twitter" to "X (Twitter)",
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
    ) {
        Text(text = "Settings", style = MaterialTheme.typography.headlineMedium)
        Spacer(modifier = Modifier.height(24.dp))
        Text(text = "Linked Accounts", style = MaterialTheme.typography.titleMedium)
        Spacer(modifier = Modifier.height(16.dp))

        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(16.dp)) {
                providers.forEach { (key, label) ->
                    val isLinked = when (key) {
                        "apple" -> uiState.user?.appleId != null
                        "discord" -> uiState.user?.discordId != null
                        "github" -> uiState.user?.githubId != null
                        "google" -> uiState.user?.googleId != null
                        "twitter" -> uiState.user?.twitterId != null
                        else -> false
                    }
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(text = label)
                        if (isLinked) {
                            OutlinedButton(onClick = { onUnlinkProvider(key) }) {
                                Text("Unlink")
                            }
                        } else {
                            Button(onClick = { onLinkProvider(key) }) {
                                Text("Link")
                            }
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))
        Text(text = "Theme", style = MaterialTheme.typography.titleMedium)
        Spacer(modifier = Modifier.height(8.dp))
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier.testTag("settings_themePicker"),
        ) {
            ThemeMode.entries.forEach { mode ->
                FilterChip(
                    selected = uiState.themeMode == mode,
                    onClick = { onSetTheme(mode) },
                    label = { Text(mode.label) },
                    modifier = Modifier.testTag("theme_${mode.apiValue}"),
                )
            }
        }

        uiState.errorMessage?.let { error ->
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = error,
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodySmall,
            )
        }

        Spacer(modifier = Modifier.height(24.dp))
        Text(text = "Delete Account", style = MaterialTheme.typography.titleMedium)
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Permanently delete your account and all associated data. This action cannot be undone.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(modifier = Modifier.height(12.dp))
        OutlinedButton(
            onClick = { showDeleteDialog = true },
            colors = ButtonDefaults.outlinedButtonColors(
                contentColor = MaterialTheme.colorScheme.error,
            ),
            border = BorderStroke(1.dp, MaterialTheme.colorScheme.error),
        ) {
            Text("Delete Account")
        }

        if (showDeleteDialog) {
            AlertDialog(
                onDismissRequest = { showDeleteDialog = false },
                title = { Text("Delete Account") },
                text = { Text("Are you sure you want to delete your account? This cannot be undone.") },
                confirmButton = {
                    TextButton(
                        onClick = {
                            showDeleteDialog = false
                            onDeleteAccount()
                        },
                        colors = ButtonDefaults.textButtonColors(
                            contentColor = MaterialTheme.colorScheme.error,
                        ),
                    ) {
                        Text("Delete")
                    }
                },
                dismissButton = {
                    TextButton(onClick = { showDeleteDialog = false }) {
                        Text("Cancel")
                    }
                },
            )
        }
    }
}
