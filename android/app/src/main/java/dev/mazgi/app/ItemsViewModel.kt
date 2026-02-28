package dev.mazgi.app

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class ItemsUiState(
    val items: List<ItemResponse> = emptyList(),
    val isLoading: Boolean = false,
    val isSubmitting: Boolean = false,
    val newName: String = "",
    val errorMessage: String? = null,
)

class ItemsViewModel : ViewModel() {

    private val _uiState = MutableStateFlow(ItemsUiState())
    val uiState: StateFlow<ItemsUiState> = _uiState.asStateFlow()

    private val api = APIClient.shared

    fun updateNewName(name: String) {
        _uiState.value = _uiState.value.copy(newName = name)
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(errorMessage = null)
    }

    fun loadItems(accessToken: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
            try {
                val items = api.getItems(accessToken)
                _uiState.value = _uiState.value.copy(items = items)
            } catch (e: APIException) {
                _uiState.value = _uiState.value.copy(errorMessage = e.message)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(errorMessage = e.message ?: "Unknown error")
            } finally {
                _uiState.value = _uiState.value.copy(isLoading = false)
            }
        }
    }

    fun addItem(accessToken: String) {
        val name = _uiState.value.newName.trim()
        if (name.isEmpty()) return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isSubmitting = true, errorMessage = null)
            try {
                val item = api.createItem(accessToken, name)
                _uiState.value = _uiState.value.copy(
                    items = listOf(item) + _uiState.value.items,
                    newName = "",
                )
            } catch (e: APIException) {
                _uiState.value = _uiState.value.copy(errorMessage = e.message)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(errorMessage = e.message ?: "Unknown error")
            } finally {
                _uiState.value = _uiState.value.copy(isSubmitting = false)
            }
        }
    }

    fun deleteItem(accessToken: String, id: String) {
        viewModelScope.launch {
            try {
                api.deleteItem(accessToken, id)
                _uiState.value = _uiState.value.copy(
                    items = _uiState.value.items.filter { it.id != id },
                )
            } catch (e: APIException) {
                _uiState.value = _uiState.value.copy(errorMessage = e.message)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(errorMessage = e.message ?: "Unknown error")
            }
        }
    }
}
