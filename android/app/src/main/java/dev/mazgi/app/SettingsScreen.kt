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
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalLayoutApi::class)
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
    onSetupTotp: () -> Unit = {},
    onEnableTotp: (String) -> Unit = {},
    onDisableTotp: (String) -> Unit = {},
    onRegenerateRecoveryCodes: (String) -> Unit = {},
    onClearMfaStep: () -> Unit = {},
    onStartDisableTotp: () -> Unit = {},
    onStartRegenerateRecoveryCodes: () -> Unit = {},
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
        Text(text = stringResource(R.string.settings), style = MaterialTheme.typography.headlineMedium)

        // Email section
        Spacer(modifier = Modifier.height(24.dp))
        Text(text = stringResource(R.string.label_email), style = MaterialTheme.typography.titleMedium)
        Spacer(modifier = Modifier.height(8.dp))

        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(16.dp)) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    if (isInvalidEmail) {
                        Text(
                            text = stringResource(R.string.not_set),
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
                                text = if (user?.emailVerified == true) stringResource(R.string.verified) else stringResource(R.string.unverified),
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
                        Text(stringResource(R.string.resend_verification_email))
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
                            placeholder = { Text(stringResource(R.string.enter_new_email)) },
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
                        Text(stringResource(R.string.save))
                    }
                }
            }
        }

        // Password section
        Spacer(modifier = Modifier.height(24.dp))
        Text(text = stringResource(R.string.section_password), style = MaterialTheme.typography.titleMedium)
        Spacer(modifier = Modifier.height(8.dp))

        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = if (user?.emailVerified != true) {
                        stringResource(R.string.password_requires_verification)
                    } else if (user.hasPassword == true) {
                        stringResource(R.string.password_reset_description)
                    } else {
                        stringResource(R.string.password_set_description)
                    },
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )

                if (passwordResetSent) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = stringResource(R.string.password_reset_sent),
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
                        if (user?.hasPassword == true) stringResource(R.string.send_reset_link) else stringResource(R.string.send_setup_link)
                    )
                }
            }
        }

        // Two-factor authentication section
        Spacer(modifier = Modifier.height(24.dp))
        Text(text = stringResource(R.string.mfa_title), style = MaterialTheme.typography.titleMedium)
        Spacer(modifier = Modifier.height(8.dp))

        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(16.dp)) {
                var totpCode by remember(uiState.mfaStep) { mutableStateOf("") }

                when (uiState.mfaStep) {
                    MfaStep.IDLE -> {
                        if (user?.totpEnabled == true) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                            ) {
                                Text(
                                    text = stringResource(R.string.mfa_status),
                                    style = MaterialTheme.typography.bodyMedium,
                                )
                                Box(
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(12.dp))
                                        .background(Color(0xFF22C55E).copy(alpha = 0.1f))
                                        .padding(horizontal = 8.dp, vertical = 2.dp),
                                ) {
                                    Text(
                                        text = stringResource(R.string.enabled),
                                        style = MaterialTheme.typography.labelSmall,
                                        color = Color(0xFF16A34A),
                                    )
                                }
                            }
                            Spacer(modifier = Modifier.height(12.dp))
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                OutlinedButton(
                                    onClick = onStartDisableTotp,
                                    enabled = !uiState.isLoading,
                                ) {
                                    Text(stringResource(R.string.disable))
                                }
                                OutlinedButton(
                                    onClick = onStartRegenerateRecoveryCodes,
                                    enabled = !uiState.isLoading,
                                ) {
                                    Text(stringResource(R.string.regenerate_recovery_codes))
                                }
                            }
                        } else {
                            Text(
                                text = stringResource(R.string.mfa_setup_description),
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                            Button(
                                onClick = onSetupTotp,
                                enabled = !uiState.isLoading,
                            ) {
                                Text(stringResource(R.string.enable))
                            }
                        }
                    }

                    MfaStep.SETUP -> {
                        uiState.totpSetupSecret?.let { secret ->
                            Text(
                                text = stringResource(R.string.mfa_scan_secret),
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = secret,
                                style = MaterialTheme.typography.bodyLarge.copy(fontFamily = FontFamily.Monospace),
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            uiState.totpSetupUri?.let { uri ->
                                Text(
                                    text = uri,
                                    style = MaterialTheme.typography.bodySmall.copy(fontFamily = FontFamily.Monospace),
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                )
                            }
                            Spacer(modifier = Modifier.height(16.dp))
                            OutlinedTextField(
                                value = totpCode,
                                onValueChange = { if (it.length <= 6) totpCode = it },
                                label = { Text(stringResource(R.string.verification_code)) },
                                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                                modifier = Modifier.fillMaxWidth(),
                                singleLine = true,
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                Button(
                                    onClick = { onEnableTotp(totpCode) },
                                    enabled = !uiState.isLoading && totpCode.length == 6,
                                ) {
                                    Text(stringResource(R.string.verify_and_enable))
                                }
                                OutlinedButton(onClick = onClearMfaStep) {
                                    Text(stringResource(R.string.cancel))
                                }
                            }
                        }
                    }

                    MfaStep.RECOVERY -> {
                        Text(
                            text = stringResource(R.string.mfa_recovery_save),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        uiState.recoveryCodes?.let { codes ->
                            FlowRow(
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                                verticalArrangement = Arrangement.spacedBy(4.dp),
                            ) {
                                codes.forEach { code ->
                                    Text(
                                        text = code,
                                        style = MaterialTheme.typography.bodyMedium.copy(fontFamily = FontFamily.Monospace),
                                    )
                                }
                            }
                        }
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(onClick = onClearMfaStep) {
                            Text(stringResource(R.string.saved_codes))
                        }
                    }

                    MfaStep.DISABLE -> {
                        Text(
                            text = stringResource(R.string.mfa_disable_prompt),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        OutlinedTextField(
                            value = totpCode,
                            onValueChange = { if (it.length <= 6) totpCode = it },
                            label = { Text(stringResource(R.string.mfa_code)) },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Button(
                                onClick = { onDisableTotp(totpCode) },
                                enabled = !uiState.isLoading && totpCode.length == 6,
                            ) {
                                Text(stringResource(R.string.disable_mfa))
                            }
                            OutlinedButton(onClick = onClearMfaStep) {
                                Text(stringResource(R.string.cancel))
                            }
                        }
                    }

                    MfaStep.REGENERATE -> {
                        Text(
                            text = stringResource(R.string.mfa_regenerate_prompt),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        OutlinedTextField(
                            value = totpCode,
                            onValueChange = { if (it.length <= 6) totpCode = it },
                            label = { Text(stringResource(R.string.mfa_code)) },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Button(
                                onClick = { onRegenerateRecoveryCodes(totpCode) },
                                enabled = !uiState.isLoading && totpCode.length == 6,
                            ) {
                                Text(stringResource(R.string.regenerate))
                            }
                            OutlinedButton(onClick = onClearMfaStep) {
                                Text(stringResource(R.string.cancel))
                            }
                        }
                    }
                }
            }
        }

        // Linked Accounts section
        Spacer(modifier = Modifier.height(24.dp))
        Text(text = stringResource(R.string.linked_accounts), style = MaterialTheme.typography.titleMedium)
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
                                Text(stringResource(R.string.unlink))
                            }
                        } else {
                            Button(onClick = { onLinkProvider(key) }) {
                                Text(stringResource(R.string.link))
                            }
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))
        Text(text = stringResource(R.string.theme), style = MaterialTheme.typography.titleMedium)
        Spacer(modifier = Modifier.height(8.dp))
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier.testTag("settings_themePicker"),
        ) {
            ThemeMode.entries.forEach { mode ->
                FilterChip(
                    selected = uiState.themeMode == mode,
                    onClick = { onSetTheme(mode) },
                    label = { Text(stringResource(mode.labelResId)) },
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
        Text(text = stringResource(R.string.delete_account), style = MaterialTheme.typography.titleMedium)
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = stringResource(R.string.delete_account_description),
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
            Text(stringResource(R.string.delete_account))
        }

        if (showDeleteDialog) {
            AlertDialog(
                onDismissRequest = { showDeleteDialog = false },
                title = { Text(stringResource(R.string.delete_account)) },
                text = { Text(stringResource(R.string.delete_account_confirm)) },
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
                        Text(stringResource(R.string.delete))
                    }
                },
                dismissButton = {
                    TextButton(onClick = { showDeleteDialog = false }) {
                        Text(stringResource(R.string.cancel))
                    }
                },
            )
        }
    }
}
