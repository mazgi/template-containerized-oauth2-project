package dev.mazgi.app.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import dev.mazgi.app.data.repository.AuthRepository
import dev.mazgi.app.data.repository.AuthResult
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

sealed class AuthUiState {
    object Idle : AuthUiState()
    object Loading : AuthUiState()
    data class Error(val message: String) : AuthUiState()
}

class AuthViewModel(private val repository: AuthRepository) : ViewModel() {

    // null = still loading from storage, true = authenticated, false = not authenticated
    val isAuthenticated: StateFlow<Boolean?> = repository.token
        .map { it != null }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    val userName: StateFlow<String?> = repository.userName
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    val userEmail: StateFlow<String?> = repository.userEmail
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    private val _signInState = MutableStateFlow<AuthUiState>(AuthUiState.Idle)
    val signInState: StateFlow<AuthUiState> = _signInState

    private val _signUpState = MutableStateFlow<AuthUiState>(AuthUiState.Idle)
    val signUpState: StateFlow<AuthUiState> = _signUpState

    fun signIn(email: String, password: String) {
        viewModelScope.launch {
            _signInState.value = AuthUiState.Loading
            _signInState.value = when (val result = repository.signIn(email, password)) {
                is AuthResult.Success -> AuthUiState.Idle
                is AuthResult.Error -> AuthUiState.Error(result.message)
            }
        }
    }

    fun signUp(name: String, email: String, password: String) {
        viewModelScope.launch {
            _signUpState.value = AuthUiState.Loading
            _signUpState.value = when (val result = repository.signUp(name, email, password)) {
                is AuthResult.Success -> AuthUiState.Idle
                is AuthResult.Error -> AuthUiState.Error(result.message)
            }
        }
    }

    fun signOut() {
        viewModelScope.launch { repository.signOut() }
    }

    fun resetSignInState() { _signInState.value = AuthUiState.Idle }
    fun resetSignUpState() { _signUpState.value = AuthUiState.Idle }
}

class AuthViewModelFactory(private val repository: AuthRepository) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        @Suppress("UNCHECKED_CAST")
        return AuthViewModel(repository) as T
    }
}
