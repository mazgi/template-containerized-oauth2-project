package dev.mazgi.app

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

// MARK: - Response models

data class UserProfile(
    val id: String,
    val email: String,
    val name: String?,
    val appleId: String?,
    val githubId: String?,
    val googleId: String?,
    val twitterId: String?,
    val discordId: String?,
    val hasPassword: Boolean?,
    val createdAt: String,
    val updatedAt: String,
)

data class AuthResponse(
    val accessToken: String,
    val refreshToken: String,
    val user: UserProfile,
)

data class ItemResponse(
    val id: String,
    val name: String,
    val userId: String,
    val createdAt: String,
    val updatedAt: String,
)

// MARK: - Error

class APIException(val statusCode: Int, message: String) : Exception(message)

// MARK: - Client

class APIClient(val baseUrl: String = BuildConfig.API_BASE_URL) {

    companion object {
        val shared = APIClient()
    }

    suspend fun signIn(email: String, password: String): AuthResponse = withContext(Dispatchers.IO) {
        val body = JSONObject().apply {
            put("email", email)
            put("password", password)
        }
        parseAuthResponse(JSONObject(post("/auth/signin", body)))
    }

    suspend fun signUp(email: String, password: String): AuthResponse = withContext(Dispatchers.IO) {
        val body = JSONObject().apply {
            put("email", email)
            put("password", password)
        }
        parseAuthResponse(JSONObject(post("/auth/signup", body)))
    }

    suspend fun refresh(refreshToken: String): AuthResponse = withContext(Dispatchers.IO) {
        val body = JSONObject().apply {
            put("refreshToken", refreshToken)
        }
        parseAuthResponse(JSONObject(post("/auth/refresh", body)))
    }

    suspend fun me(accessToken: String): UserProfile = withContext(Dispatchers.IO) {
        parseUserProfile(JSONObject(get("/auth/me", accessToken)))
    }

    suspend fun getItems(accessToken: String): List<ItemResponse> = withContext(Dispatchers.IO) {
        val array = JSONArray(get("/items", accessToken))
        (0 until array.length()).map { parseItemResponse(array.getJSONObject(it)) }
    }

    suspend fun createItem(accessToken: String, name: String): ItemResponse = withContext(Dispatchers.IO) {
        val body = JSONObject().apply { put("name", name) }
        parseItemResponse(JSONObject(post("/items", body, accessToken)))
    }

    suspend fun deleteItem(accessToken: String, id: String) = withContext(Dispatchers.IO) {
        delete("/items/$id", accessToken)
    }

    suspend fun unlinkProvider(accessToken: String, provider: String): UserProfile = withContext(Dispatchers.IO) {
        parseUserProfile(JSONObject(deleteWithResponse("/auth/link/$provider", accessToken)))
    }

    suspend fun deleteAccount(accessToken: String) = withContext(Dispatchers.IO) {
        delete("/auth/account", accessToken)
    }

    // MARK: - Helpers

    private fun post(path: String, body: JSONObject): String {
        val conn = openConnection(path, "POST")
        conn.setRequestProperty("Content-Type", "application/json")
        conn.doOutput = true
        conn.outputStream.bufferedWriter().use { it.write(body.toString()) }
        return readResponseText(conn)
    }

    private fun post(path: String, body: JSONObject, token: String): String {
        val conn = openConnection(path, "POST")
        conn.setRequestProperty("Content-Type", "application/json")
        conn.setRequestProperty("Authorization", "Bearer $token")
        conn.doOutput = true
        conn.outputStream.bufferedWriter().use { it.write(body.toString()) }
        return readResponseText(conn)
    }

    private fun get(path: String, token: String): String {
        val conn = openConnection(path, "GET")
        conn.setRequestProperty("Authorization", "Bearer $token")
        return readResponseText(conn)
    }

    private fun deleteWithResponse(path: String, token: String): String {
        val conn = openConnection(path, "DELETE")
        conn.setRequestProperty("Authorization", "Bearer $token")
        return readResponseText(conn)
    }

    private fun delete(path: String, token: String) {
        val conn = openConnection(path, "DELETE")
        conn.setRequestProperty("Authorization", "Bearer $token")
        readResponseText(conn)
    }

    private fun openConnection(path: String, method: String): HttpURLConnection {
        val conn = URL(baseUrl + path).openConnection() as HttpURLConnection
        conn.requestMethod = method
        conn.connectTimeout = 30_000
        conn.readTimeout = 30_000
        return conn
    }

    private fun readResponseText(conn: HttpURLConnection): String {
        val statusCode = conn.responseCode
        val responseText = if (statusCode in 200..299) {
            conn.inputStream.bufferedReader().readText()
        } else {
            conn.errorStream?.bufferedReader()?.readText() ?: ""
        }
        conn.disconnect()

        if (statusCode !in 200..299) {
            val json = runCatching { JSONObject(responseText) }.getOrNull()
            val msgValue = json?.opt("message")
            val msg = when (msgValue) {
                is String -> msgValue
                is JSONArray -> (0 until msgValue.length()).joinToString("\n") { msgValue.getString(it) }
                else -> "HTTP $statusCode"
            }
            throw APIException(statusCode, msg)
        }
        return responseText
    }

    private fun parseUserProfile(json: JSONObject) = UserProfile(
        id = json.getString("id"),
        email = json.getString("email"),
        name = json.optString("name").takeIf { it.isNotEmpty() },
        appleId = json.optString("appleId").takeIf { it.isNotEmpty() && it != "null" },
        githubId = json.optString("githubId").takeIf { it.isNotEmpty() && it != "null" },
        googleId = json.optString("googleId").takeIf { it.isNotEmpty() && it != "null" },
        twitterId = json.optString("twitterId").takeIf { it.isNotEmpty() && it != "null" },
        discordId = json.optString("discordId").takeIf { it.isNotEmpty() && it != "null" },
        hasPassword = if (json.has("hasPassword")) json.getBoolean("hasPassword") else null,
        createdAt = json.getString("createdAt"),
        updatedAt = json.getString("updatedAt"),
    )

    private fun parseAuthResponse(json: JSONObject) = AuthResponse(
        accessToken = json.getString("accessToken"),
        refreshToken = json.getString("refreshToken"),
        user = parseUserProfile(json.getJSONObject("user")),
    )

    private fun parseItemResponse(json: JSONObject) = ItemResponse(
        id = json.getString("id"),
        name = json.getString("name"),
        userId = json.getString("userId"),
        createdAt = json.getString("createdAt"),
        updatedAt = json.getString("updatedAt"),
    )
}
