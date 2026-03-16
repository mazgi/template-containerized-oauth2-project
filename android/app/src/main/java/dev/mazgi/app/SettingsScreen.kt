package dev.mazgi.app

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.BorderStroke
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.unit.dp

@Composable
fun SettingsScreen(
    uiState: AuthUiState,
    onLinkProvider: (String) -> Unit,
    onUnlinkProvider: (String) -> Unit,
    onDeleteAccount: () -> Unit,
    onUpdateEmail: (String) -> Unit = {},
    onResendVerification: () -> Unit = {},
    onRequestPasswordReset: () -> Unit = {},
    onSetTheme: (ThemeMode) -> Unit = {},
) {
    var showDeleteDialog by remember { mutableStateOf(false) }
    var emailInput by remember { mutableStateOf("") }
    var showEmailDropdown by remember { mutableStateOf(false) }
    var passwordResetSent by remember { mutableStateOf(false) }
    val providers = listOf(
        "apple" to "Apple",
        "discord" to "Discord",
        "github" to "GitHub",
        "google" to "Google",
        "twitter" to "X (Twitter)",
    )

    val user = uiState.user
    val isInvalidEmail = user?.email?.endsWith(".invalid") == true
    val selectableEmails = (user?.socialEmails ?: emptyList()).filter { it != user?.email }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp)
            .verticalScroll(rememberScrollState()),
    ) {
        Text(text = "Settings", style = MaterialTheme.typography.headlineMedium)

        // Email section
        Spacer(modifier = Modifier.height(24.dp))
        Text(text = "Email", style = MaterialTheme.typography.titleMedium)
        Spacer(modifier = Modifier.height(8.dp))

        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(16.dp)) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    if (isInvalidEmail) {
                        Text(
                            text = "Not set",
                            style = MaterialTheme.typography.bodyLarge,
                            fontStyle = FontStyle.Italic,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    } else {
                        Text(
                            text = user?.email ?: "",
                            style = MaterialTheme.typography.bodyLarge,
                        )
                        val badgeColor = if (user?.emailVerified == true) {
                            Color(0xFF16A34A)
                        } else {
                            Color(0xFFCA8A04)
                        }
                        val badgeBg = if (user?.emailVerified == true) {
                            Color(0xFF22C55E).copy(alpha = 0.1f)
                        } else {
                            Color(0xFFEAB308).copy(alpha = 0.1f)
                        }
                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(12.dp))
                                .background(badgeBg)
                                .padding(horizontal = 8.dp, vertical = 2.dp),
                        ) {
                            Text(
                                text = if (user?.emailVerified == true) "Verified" else "Unverified",
                                style = MaterialTheme.typography.labelSmall,
                                color = badgeColor,
                            )
                        }
                    }
                }

                if (!isInvalidEmail && user?.emailVerified == false) {
                    Spacer(modifier = Modifier.height(8.dp))
                    TextButton(
                        onClick = onResendVerification,
                        enabled = !uiState.isLoading,
                    ) {
                        Text("Resend verification email")
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Box(modifier = Modifier.weight(1f)) {
                        OutlinedTextField(
                            value = emailInput,
                            onValueChange = { emailInput = it },
                            placeholder = { Text("Enter new email address") },
                            singleLine = true,
                            modifier = Modifier
                                .fillMaxWidth()
                                .testTag("settings_emailInput"),
                        )
                    }
                    if (selectableEmails.isNotEmpty()) {
                        Spacer(modifier = Modifier.width(8.dp))
                        Box {
                            OutlinedButton(onClick = { showEmailDropdown = true }) {
                                Text("▼")
                            }
                            DropdownMenu(
                                expanded = showEmailDropdown,
                                onDismissRequest = { showEmailDropdown = false },
                            ) {
                                selectableEmails.forEach { email ->
                                    DropdownMenuItem(
                                        text = { Text(email) },
                                        onClick = {
                                            emailInput = email
                                            showEmailDropdown = false
                                        },
                                    )
                                }
                            }
                        }
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    Button(
                        onClick = { onUpdateEmail(emailInput.trim()) },
                        enabled = !uiState.isLoading && emailInput.trim().isNotEmpty() && emailInput.trim() != user?.email,
                        modifier = Modifier.testTag("settings_saveEmail"),
                    ) {
                        Text("Save")
                    }
                }
            }
        }

        // Password section
        Spacer(modifier = Modifier.height(24.dp))
        Text(text = "Password", style = MaterialTheme.typography.titleMedium)
        Spacer(modifier = Modifier.height(8.dp))

        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = if (user?.emailVerified != true) {
                        "To use this feature, please verify your email address first."
                    } else if (user.hasPassword == true) {
                        "Send a password reset link to your email address."
                    } else {
                        "Set a password so you can also sign in with email and password."
                    },
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )

                if (passwordResetSent) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Password reset link sent. Please check your inbox.",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color(0xFF16A34A),
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))
                OutlinedButton(
                    onClick = {
                        onRequestPasswordReset()
                        passwordResetSent = true
                    },
                    enabled = !uiState.isLoading && user?.emailVerified == true,
                    modifier = Modifier.testTag("settings_passwordResetButton"),
                ) {
                    Text(
                        if (user?.hasPassword == true) "Send reset link" else "Send setup link"
                    )
                }
            }
        }

        // Linked Accounts section
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
