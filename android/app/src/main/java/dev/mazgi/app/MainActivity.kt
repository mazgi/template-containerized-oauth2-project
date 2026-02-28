package dev.mazgi.app

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.lifecycle.ViewModelProvider
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import dev.mazgi.app.ui.theme.AppTheme

class MainActivity : ComponentActivity() {

    private lateinit var authViewModel: AuthViewModel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        authViewModel = ViewModelProvider(this)[AuthViewModel::class.java]

        // Handle OAuth callback when launched via deep link
        intent?.data?.let { uri ->
            if (uri.scheme == "oauth2app") {
                authViewModel.handleOAuthCallback(uri)
            }
        }

        setContent {
            AppTheme {
                val uiState by authViewModel.uiState.collectAsState()

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
                                        label = { Text("Dashboard") },
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
                                        label = { Text("Items") },
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
                                        label = { Text("Settings") },
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
                                    onNavigateToSignUp = {
                                        authViewModel.clearError()
                                        navController.navigate("signup")
                                    },
                                )
                            }
                            composable("signup") {
                                SignUpScreen(
                                    uiState = uiState,
                                    onSignUp = { email, password ->
                                        authViewModel.signUp(email, password)
                                    },
                                    onNavigateToSignIn = {
                                        authViewModel.clearError()
                                        navController.popBackStack()
                                    },
                                )
                            }
                        }
                    }
                }
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
