package dev.mazgi.app

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModelProvider
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import dev.mazgi.app.ui.theme.AppTheme
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject

class MainActivity : ComponentActivity() {

    private lateinit var authViewModel: AuthViewModel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        DebugSettings.init(this)
        authViewModel = ViewModelProvider(this)[AuthViewModel::class.java]

        // Handle OAuth callback when launched via deep link
        intent?.data?.let { uri ->
            if (uri.scheme == "oauth2app") {
                authViewModel.handleOAuthCallback(uri)
            }
        }

        setContent {
            val uiState by authViewModel.uiState.collectAsState()
            val themeOverride: Boolean? = when (uiState.themeMode) {
                ThemeMode.LIGHT -> false
                ThemeMode.DARK -> true
                ThemeMode.SYSTEM -> null
            }
            AppTheme(themeOverride = themeOverride) {

                Box(modifier = Modifier.fillMaxSize()) {
                when {
                    uiState.isRestoringSession -> {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center,
                        ) {
                            CircularProgressIndicator()
                        }
                    }
                    uiState.isAuthenticated -> {
                        uiState.accessToken?.let { accessToken ->
                        val navController = rememberNavController()
                        val navBackStackEntry by navController.currentBackStackEntryAsState()
                        val currentRoute = navBackStackEntry?.destination?.route

                        Scaffold(
                            bottomBar = {
                                NavigationBar {
                                    NavigationBarItem(
                                        selected = currentRoute == "dashboard",
                                        onClick = {
                                            navController.navigate("dashboard") {
                                                popUpTo("dashboard") { inclusive = true }
                                                launchSingleTop = true
                                            }
                                        },
                                        icon = {
                                            Icon(Icons.Filled.Person, contentDescription = null)
                                        },
                                        label = { Text(stringResource(R.string.nav_dashboard)) },
                                    )
                                    NavigationBarItem(
                                        selected = currentRoute == "items",
                                        onClick = {
                                            navController.navigate("items") {
                                                popUpTo("dashboard")
                                                launchSingleTop = true
                                            }
                                        },
                                        icon = {
                                            Icon(Icons.Filled.Menu, contentDescription = null)
                                        },
                                        label = { Text(stringResource(R.string.nav_items)) },
                                    )
                                    NavigationBarItem(
                                        selected = currentRoute == "settings",
                                        onClick = {
                                            navController.navigate("settings") {
                                                popUpTo("dashboard")
                                                launchSingleTop = true
                                            }
                                        },
                                        icon = {
                                            Icon(Icons.Filled.Settings, contentDescription = null)
                                        },
                                        label = { Text(stringResource(R.string.nav_settings)) },
                                    )
                                }
                            },
                        ) { innerPadding ->
                            NavHost(
                                navController = navController,
                                startDestination = "dashboard",
                                modifier = Modifier.padding(innerPadding),
                            ) {
                                composable("dashboard") {
                                    DashboardScreen(
                                        uiState = uiState,
                                        onSignOut = { authViewModel.signOut() },
                                    )
                                }
                                composable("items") {
                                    ItemsScreen(accessToken = accessToken)
                                }
                                composable("settings") {
                                    SettingsScreen(
                                        uiState = uiState,
                                        onLinkProvider = { provider ->
                                            authViewModel.linkProvider(this@MainActivity, provider)
                                        },
                                        onUnlinkProvider = { provider ->
                                            authViewModel.unlinkProvider(provider)
                                        },
                                        onDeleteAccount = {
                                            authViewModel.deleteAccount()
                                        },
                                        onUpdateEmail = { email ->
                                            authViewModel.updateEmail(email)
                                        },
                                        onResendVerification = {
                                            authViewModel.resendVerificationFromSettings()
                                        },
                                        onRequestPasswordReset = {
                                            authViewModel.requestPasswordReset()
                                        },
                                        onSetTheme = { mode ->
                                            authViewModel.setTheme(mode)
                                        },
                                        onSetupTotp = {
                                            authViewModel.setupTotp()
                                        },
                                        onEnableTotp = { code ->
                                            authViewModel.enableTotp(code)
                                        },
                                        onDisableTotp = { code ->
                                            authViewModel.disableTotp(code)
                                        },
                                        onRegenerateRecoveryCodes = { code ->
                                            authViewModel.regenerateRecoveryCodes(code)
                                        },
                                        onClearMfaStep = {
                                            authViewModel.clearMfaStep()
                                        },
                                        onStartDisableTotp = {
                                            authViewModel.startDisableTotp()
                                        },
                                        onStartRegenerateRecoveryCodes = {
                                            authViewModel.startRegenerateRecoveryCodes()
                                        },
                                    )
                                }
                            }
                        }
                        } // accessToken?.let
                    }
                    else -> {
                        val navController = rememberNavController()
                        NavHost(navController = navController, startDestination = "signin") {
                            composable("signin") {
                                SignInScreen(
                                    uiState = uiState,
                                    onSignIn = { email, password ->
                                        authViewModel.signIn(email, password)
                                    },
                                    onSignInWithApple = {
                                        authViewModel.signInWithApple(this@MainActivity)
                                    },
                                    onSignInWithDiscord = {
                                        authViewModel.signInWithDiscord(this@MainActivity)
                                    },
                                    onSignInWithGithub = {
                                        authViewModel.signInWithGithub(this@MainActivity)
                                    },
                                    onSignInWithGoogle = {
                                        authViewModel.signInWithGoogle(this@MainActivity)
                                    },
                                    onSignInWithX = {
                                        authViewModel.signInWithTwitter(this@MainActivity)
                                    },
                                    onForgotPassword = { email ->
                                        authViewModel.forgotPasswordFromSignIn(email)
                                    },
                                    onNavigateToSignUp = {
                                        authViewModel.clearError()
                                        navController.navigate("signup")
                                    },
                                    onVerifyMfa = { code ->
                                        authViewModel.verifyMfa(code)
                                    },
                                )
                            }
                            composable("signup") {
                                SignUpScreen(
                                    uiState = uiState,
                                    onSignUp = { email, password ->
                                        authViewModel.signUp(email, password)
                                    },
                                    onResendVerification = { email ->
                                        authViewModel.resendVerification(email)
                                    },
                                    onNavigateToSignIn = {
                                        authViewModel.clearError()
                                        authViewModel.clearVerificationSent()
                                        navController.popBackStack()
                                    },
                                )
                            }
                        }
                    }
                }
                if (BuildConfig.DEBUG) {
                    var showDebugSettings by remember { mutableStateOf(false) }
                    Button(
                        onClick = { showDebugSettings = true },
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .padding(end = 8.dp, top = 48.dp)
                            .size(width = 64.dp, height = 32.dp),
                        contentPadding = ButtonDefaults.TextButtonContentPadding,
                    ) {
                        Text(stringResource(R.string.nav_debug), style = MaterialTheme.typography.labelSmall)
                    }
                    if (showDebugSettings) {
                        DebugSettingsDialog(onDismiss = { showDebugSettings = false })
                    }
                }
                val frontSha = BuildConfig.GIT_SHA
                var shaLabel by remember { mutableStateOf(frontSha) }
                LaunchedEffect(Unit) {
                    val backSha = try {
                        withContext(Dispatchers.IO) {
                            val conn = java.net.URL("${APIClient.shared.baseUrl}/health")
                                .openConnection() as java.net.HttpURLConnection
                            conn.connectTimeout = 3000
                            conn.readTimeout = 3000
                            if (conn.responseCode == 200) {
                                JSONObject(conn.inputStream.bufferedReader().readText())
                                    .optString("gitSha", "")
                            } else ""
                        }
                    } catch (_: Exception) { "" }
                    if (backSha.isNotEmpty()) {
                        shaLabel = if (frontSha == backSha) "f/b: $frontSha"
                            else "f: $frontSha, b: $backSha"
                    }
                }
                Text(
                    text = shaLabel,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f),
                    modifier = Modifier
                        .align(Alignment.BottomEnd)
                        .padding(end = 8.dp, bottom = 4.dp)
                        .testTag("gitShaLabel"),
                )
                } // Box
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        intent.data?.let { uri ->
            if (uri.scheme == "oauth2app") {
                authViewModel.handleOAuthCallback(uri)
            }
        }
    }
}
