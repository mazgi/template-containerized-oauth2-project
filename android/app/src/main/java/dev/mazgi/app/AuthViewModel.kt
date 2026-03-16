package dev.mazgi.app

import android.app.Application
import android.content.Context
import android.net.Uri
import androidx.browser.customtabs.CustomTabsIntent
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import org.json.JSONObject

enum class ThemeMode(val label: String) {
    SYSTEM("System"),
    LIGHT("Light"),
    DARK("Dark");

    val apiValue: String get() = name.lowercase()

    companion object {
        fun fromApi(value: String?): ThemeMode = when (value) {
            "light" -> LIGHT
            "dark" -> DARK
            else -> SYSTEM
        }
    }
}

data class AuthUiState(
    val user: UserProfile? = null,
    val accessToken: String? = null,
    val isAuthenticated: Boolean = false,
    val isLoading: Boolean = false,
    val isRestoringSession: Boolean = true,
    val errorMessage: String? = null,
    val themeMode: ThemeMode = ThemeMode.SYSTEM,
    val verificationSentEmail: String? = null,
)

class AuthViewModel(application: Application) : AndroidViewModel(application) {

    private val _uiState = MutableStateFlow(AuthUiState())
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()

    private val api = APIClient.shared
    private val prefs = application.getSharedPreferences("auth", Context.MODE_PRIVATE)

    init {
        viewModelScope.launch {
            restoreSession()
            _uiState.value = _uiState.value.copy(isRestoringSession = false)
        }
    }

    fun signIn(email: String, password: String) {
        viewModelScope.launch {
            perform {
                val res = api.signIn(email, password)
                storeTokens(res.accessToken, res.refreshToken)
                _uiState.value = _uiState.value.copy(user = res.user, accessToken = res.accessToken, isAuthenticated = true)
                syncTheme(res.user)
            }
        }
    }

    fun signUp(email: String, password: String) {
        viewModelScope.launch {
            perform {
                api.signUp(email, password)
                _uiState.value = _uiState.value.copy(verificationSentEmail = email)
            }
        }
    }

    fun resendVerification(email: String) {
        viewModelScope.launch {
            perform {
                api.resendVerification(email)
            }
        }
    }

    fun clearVerificationSent() {
        _uiState.value = _uiState.value.copy(verificationSentEmail = null)
    }

    fun signInWithApple(context: Context) {
        val uri = Uri.parse("${api.baseUrl}/auth/apple/native")
        try {
            CustomTabsIntent.Builder().build().launchUrl(context, uri)
        } catch (e: Exception) {
            _uiState.value = _uiState.value.copy(errorMessage = e.message ?: "Failed to open browser")
        }
    }

    fun signInWithGithub(context: Context) {
        val uri = Uri.parse("${api.baseUrl}/auth/github/native")
        try {
            CustomTabsIntent.Builder().build().launchUrl(context, uri)
        } catch (e: Exception) {
            _uiState.value = _uiState.value.copy(errorMessage = e.message ?: "Failed to open browser")
        }
    }

    fun signInWithGoogle(context: Context) {
        val uri = Uri.parse("${api.baseUrl}/auth/google/native")
        try {
            CustomTabsIntent.Builder().build().launchUrl(context, uri)
        } catch (e: Exception) {
            _uiState.value = _uiState.value.copy(errorMessage = e.message ?: "Failed to open browser")
        }
    }

    fun signInWithTwitter(context: Context) {
        // Use TWITTER_AUTH_BASE_URL (defaults to localhost via `adb reverse tcp:4000 tcp:4000`)
        // so the session cookie domain matches the TWITTER_NATIVE_CALLBACK_URL.
        // If 10.0.2.2 were used here, the PKCE code_verifier stored in express-session would be
        // lost at the callback step because the browser won't send a 10.0.2.2 cookie to localhost.
        val uri = Uri.parse("${api.twitterAuthBaseUrl}/auth/twitter/native")
        try {
            CustomTabsIntent.Builder().build().launchUrl(context, uri)
        } catch (e: Exception) {
            _uiState.value = _uiState.value.copy(errorMessage = e.message ?: "Failed to open browser")
        }
    }

    fun signInWithDiscord(context: Context) {
        val uri = Uri.parse("${api.baseUrl}/auth/discord/native")
        try {
            CustomTabsIntent.Builder().build().launchUrl(context, uri)
        } catch (e: Exception) {
            _uiState.value = _uiState.value.copy(errorMessage = e.message ?: "Failed to open browser")
        }
    }

    fun linkProvider(context: Context, provider: String) {
        val token = _uiState.value.accessToken ?: return
        // For Twitter, must use TWITTER_AUTH_BASE_URL (session cookie domain consistency for PKCE)
        val baseUrl = if (provider == "twitter") api.twitterAuthBaseUrl else api.baseUrl
        val uri = Uri.parse("$baseUrl/auth/link/$provider/native?token=$token")
        try {
            CustomTabsIntent.Builder().build().launchUrl(context, uri)
        } catch (e: Exception) {
            _uiState.value = _uiState.value.copy(errorMessage = e.message ?: "Failed to open browser")
        }
    }

    fun unlinkProvider(provider: String) {
        viewModelScope.launch {
            val token = _uiState.value.accessToken ?: return@launch
            _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
            try {
                val updatedUser = api.unlinkProvider(token, provider)
                _uiState.value = _uiState.value.copy(user = updatedUser, isLoading = false)
            } catch (e: APIException) {
                _uiState.value = _uiState.value.copy(errorMessage = e.message, isLoading = false)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(errorMessage = e.message ?: "Unknown error", isLoading = false)
            }
        }
    }

    fun updateEmail(newEmail: String) {
        viewModelScope.launch {
            val token = _uiState.value.accessToken ?: return@launch
            _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
            try {
                val updatedUser = api.updateEmail(token, newEmail)
                _uiState.value = _uiState.value.copy(user = updatedUser, isLoading = false)
            } catch (e: APIException) {
                _uiState.value = _uiState.value.copy(errorMessage = e.message, isLoading = false)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(errorMessage = e.message ?: "Unknown error", isLoading = false)
            }
        }
    }

    fun resendVerificationFromSettings() {
        viewModelScope.launch {
            val email = _uiState.value.user?.email ?: return@launch
            _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
            try {
                api.resendVerification(email)
                _uiState.value = _uiState.value.copy(isLoading = false)
            } catch (e: APIException) {
                _uiState.value = _uiState.value.copy(errorMessage = e.message, isLoading = false)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(errorMessage = e.message ?: "Unknown error", isLoading = false)
            }
        }
    }

    fun requestPasswordReset() {
        viewModelScope.launch {
            val email = _uiState.value.user?.email ?: return@launch
            _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
            try {
                api.forgotPassword(email)
                _uiState.value = _uiState.value.copy(isLoading = false)
            } catch (e: APIException) {
                _uiState.value = _uiState.value.copy(errorMessage = e.message, isLoading = false)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(errorMessage = e.message ?: "Unknown error", isLoading = false)
            }
        }
    }

    fun deleteAccount() {
        viewModelScope.launch {
            val token = _uiState.value.accessToken ?: return@launch
            _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
            try {
                api.deleteAccount(token)
                signOut()
            } catch (e: APIException) {
                _uiState.value = _uiState.value.copy(errorMessage = e.message, isLoading = false)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(errorMessage = e.message ?: "Unknown error", isLoading = false)
            }
        }
    }

    fun handleOAuthCallback(uri: Uri) {
        // Account linking callback — refresh user profile
        val linked = uri.getQueryParameter("linked")
        if (linked != null) {
            viewModelScope.launch {
                val token = _uiState.value.accessToken ?: return@launch
                try {
                    val profile = api.me(token)
                    _uiState.value = _uiState.value.copy(user = profile)
                } catch (_: Exception) { }
            }
            return
        }

        val accessToken = uri.getQueryParameter("accessToken") ?: return
        val refreshToken = uri.getQueryParameter("refreshToken") ?: return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
            try {
                val profile = api.me(accessToken)
                storeTokens(accessToken, refreshToken)
                _uiState.value = _uiState.value.copy(
                    user = profile,
                    accessToken = accessToken,
                    isAuthenticated = true,
                    isLoading = false,
                )
                syncTheme(profile)
            } catch (e: APIException) {
                _uiState.value = _uiState.value.copy(errorMessage = e.message, isLoading = false)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    errorMessage = e.message ?: "Unknown error",
                    isLoading = false,
                )
            }
        }
    }

    fun setTheme(mode: ThemeMode) {
        _uiState.value = _uiState.value.copy(themeMode = mode)
        viewModelScope.launch {
            val token = _uiState.value.accessToken ?: return@launch
            try {
                val body = JSONObject().apply { put("theme", mode.apiValue) }
                val updated = api.updatePreferences(token, body)
                _uiState.value = _uiState.value.copy(user = updated)
            } catch (_: Exception) {
                // Theme already applied locally; ignore network errors
            }
        }
    }

    fun signOut() {
        prefs.edit().remove("access_token").remove("refresh_token").apply()
        _uiState.value = AuthUiState(isRestoringSession = false)
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(errorMessage = null)
    }

    // MARK: - Session restore

    private suspend fun restoreSession() {
        val accessToken = prefs.getString("access_token", null) ?: return
        val refreshToken = prefs.getString("refresh_token", null) ?: return
        try {
            val profile = api.me(accessToken)
            _uiState.value = _uiState.value.copy(user = profile, accessToken = accessToken, isAuthenticated = true)
            syncTheme(profile)
        } catch (e: Exception) {
            // Access token expired — try refresh
            try {
                val res = api.refresh(refreshToken)
                storeTokens(res.accessToken, res.refreshToken)
                _uiState.value = _uiState.value.copy(user = res.user, accessToken = res.accessToken, isAuthenticated = true)
                syncTheme(res.user)
            } catch (e2: Exception) {
                signOut()
            }
        }
    }

    // MARK: - Helpers

    private suspend fun perform(action: suspend () -> Unit) {
        _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
        try {
            action()
        } catch (e: APIException) {
            _uiState.value = _uiState.value.copy(errorMessage = e.message)
        } catch (e: Exception) {
            _uiState.value = _uiState.value.copy(errorMessage = e.message ?: "Unknown error")
        } finally {
            _uiState.value = _uiState.value.copy(isLoading = false)
        }
    }

    private fun storeTokens(accessToken: String, refreshToken: String) {
        prefs.edit()
            .putString("access_token", accessToken)
            .putString("refresh_token", refreshToken)
            .apply()
    }

    private fun syncTheme(profile: UserProfile) {
        val mode = ThemeMode.fromApi(profile.preferences?.theme)
        _uiState.value = _uiState.value.copy(themeMode = mode)
    }
}
