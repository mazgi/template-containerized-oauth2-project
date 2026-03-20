package dev.mazgi.app

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp

@Composable
fun DashboardScreen(
    uiState: AuthUiState,
    onSignOut: () -> Unit,
) {
    val user = uiState.user

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            text = stringResource(R.string.dashboard),
            style = MaterialTheme.typography.headlineMedium,
        )
        Spacer(modifier = Modifier.height(32.dp))

        if (user != null) {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    ProfileRow(label = stringResource(R.string.label_email), value = user.email)
                    user.name?.let { ProfileRow(label = stringResource(R.string.label_name), value = it) }
                    ProfileRow(label = stringResource(R.string.label_id), value = user.id)
                    ProfileRow(label = stringResource(R.string.label_created), value = user.createdAt)
                }
            }
        }
        Spacer(modifier = Modifier.height(32.dp))

        Button(
            onClick = onSignOut,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text(stringResource(R.string.sign_out))
        }
    }
}

@Composable
private fun ProfileRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(text = label, style = MaterialTheme.typography.labelLarge)
        Text(text = value, style = MaterialTheme.typography.bodyMedium)
    }
}
