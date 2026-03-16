package dev.mazgi.app

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun DebugSettingsDialog(onDismiss: () -> Unit) {
    var apiBaseUrl by remember { mutableStateOf(DebugSettings.apiBaseUrl ?: "") }
    var twitterAuthBaseUrl by remember { mutableStateOf(DebugSettings.twitterAuthBaseUrl ?: "") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Debug Settings") },
        text = {
            Column {
                Text("API Base URL", style = MaterialTheme.typography.labelMedium)
                OutlinedTextField(
                    value = apiBaseUrl,
                    onValueChange = { apiBaseUrl = it },
                    placeholder = { Text(BuildConfig.API_BASE_URL) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text("Twitter Auth Base URL", style = MaterialTheme.typography.labelMedium)
                OutlinedTextField(
                    value = twitterAuthBaseUrl,
                    onValueChange = { twitterAuthBaseUrl = it },
                    placeholder = { Text(BuildConfig.TWITTER_AUTH_BASE_URL) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        },
        confirmButton = {
            TextButton(onClick = {
                DebugSettings.apiBaseUrl = apiBaseUrl.takeIf { it.isNotBlank() }
                DebugSettings.twitterAuthBaseUrl = twitterAuthBaseUrl.takeIf { it.isNotBlank() }
                onDismiss()
            }) { Text("Save") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        },
    )
}
