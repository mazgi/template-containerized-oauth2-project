package dev.mazgi.app.data.repository

import dev.mazgi.app.data.api.ApiClient
import dev.mazgi.app.data.local.TokenDataStore
import dev.mazgi.app.data.model.AuthResponse
import dev.mazgi.app.data.model.SignInRequest
import dev.mazgi.app.data.model.SignUpRequest

sealed class AuthResult {
    data class Success(val response: AuthResponse) : AuthResult()
    data class Error(val code: String, val message: String) : AuthResult()
}

class AuthRepository(private val tokenDataStore: TokenDataStore) {
    private val api = ApiClient.authApiService

    suspend fun signIn(email: String, password: String): AuthResult {
        return try {
            val response = api.signIn(SignInRequest(email, password))
            if (response.isSuccessful) {
                val body = response.body()!!
                tokenDataStore.saveAuth(body.token, body.user.id, body.user.email, body.user.name)
                AuthResult.Success(body)
            } else {
                when (response.code()) {
                    401 -> AuthResult.Error("invalid_credentials", "Invalid email or password.")
                    else -> AuthResult.Error("server_error", "Authentication failed. Please try again.")
                }
            }
        } catch (e: Exception) {
            AuthResult.Error("network_error", "A network error occurred: ${e.message}")
        }
    }

    suspend fun signUp(name: String, email: String, password: String): AuthResult {
        return try {
            val response = api.signUp(SignUpRequest(name, email, password))
            if (response.isSuccessful) {
                val body = response.body()!!
                tokenDataStore.saveAuth(body.token, body.user.id, body.user.email, body.user.name)
                AuthResult.Success(body)
            } else {
                when (response.code()) {
                    400 -> AuthResult.Error("invalid_input", "Please check your input and try again.")
                    409 -> AuthResult.Error("email_exists", "An account with this email already exists.")
                    else -> AuthResult.Error("server_error", "Registration failed. Please try again.")
                }
            }
        } catch (e: Exception) {
            AuthResult.Error("network_error", "A network error occurred: ${e.message}")
        }
    }

    suspend fun signOut() {
        tokenDataStore.clearAuth()
    }

    val token = tokenDataStore.token
    val userName = tokenDataStore.userName
    val userEmail = tokenDataStore.userEmail
}
