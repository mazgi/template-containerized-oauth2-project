package dev.mazgi.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import dev.mazgi.app.data.local.TokenDataStore
import dev.mazgi.app.data.repository.AuthRepository
import dev.mazgi.app.ui.screen.DashboardScreen
import dev.mazgi.app.ui.screen.SignInScreen
import dev.mazgi.app.ui.screen.SignUpScreen
import dev.mazgi.app.ui.theme.AppTheme
import dev.mazgi.app.ui.viewmodel.AuthViewModel
import dev.mazgi.app.ui.viewmodel.AuthViewModelFactory

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val tokenDataStore = TokenDataStore(applicationContext)
        val repository = AuthRepository(tokenDataStore)
        val viewModel: AuthViewModel by viewModels { AuthViewModelFactory(repository) }

        enableEdgeToEdge()
        setContent {
            AppTheme {
                val isAuthenticated by viewModel.isAuthenticated.collectAsState()

                // null = loading initial auth state from storage
                when (isAuthenticated) {
                    null -> Box(modifier = Modifier.fillMaxSize())
                    true -> DashboardScreen(viewModel = viewModel)
                    false -> {
                        val navController = rememberNavController()
                        NavHost(navController = navController, startDestination = "sign_in") {
                            composable("sign_in") {
                                SignInScreen(
                                    viewModel = viewModel,
                                    onNavigateToSignUp = { navController.navigate("sign_up") },
                                )
                            }
                            composable("sign_up") {
                                SignUpScreen(
                                    viewModel = viewModel,
                                    onNavigateBack = { navController.popBackStack() },
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}