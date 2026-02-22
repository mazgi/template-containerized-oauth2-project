package dev.mazgi.app.data.api

import dev.mazgi.app.data.model.AuthResponse
import dev.mazgi.app.data.model.SignInRequest
import dev.mazgi.app.data.model.SignUpRequest
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.POST

interface AuthApiService {
    @POST("api/mobile/signin")
    suspend fun signIn(@Body request: SignInRequest): Response<AuthResponse>

    @POST("api/mobile/signup")
    suspend fun signUp(@Body request: SignUpRequest): Response<AuthResponse>
}
