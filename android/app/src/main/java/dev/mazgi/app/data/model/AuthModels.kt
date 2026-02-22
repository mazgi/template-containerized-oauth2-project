package dev.mazgi.app.data.model

data class SignInRequest(
    val email: String,
    val password: String,
)

data class SignUpRequest(
    val name: String,
    val email: String,
    val password: String,
)

data class AuthUser(
    val id: String,
    val email: String,
    val name: String?,
)

data class AuthResponse(
    val token: String,
    val user: AuthUser,
)

data class ApiError(
    val error: String,
)
