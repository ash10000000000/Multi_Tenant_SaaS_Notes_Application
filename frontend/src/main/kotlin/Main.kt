import kotlinx.browser.document
import kotlinx.browser.window
import kotlinx.html.*
import kotlinx.html.dom.append
import kotlinx.html.js.onClickFunction
import kotlinx.html.js.onSubmitFunction
import kotlinx.coroutines.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlin.js.Promise

@Serializable
data class User(
    val id: Int,
    val email: String,
    val role: String,
    val tenant: Tenant
)

@Serializable
data class Tenant(
    val id: Int,
    val slug: String,
    val name: String,
    val plan: String
)

@Serializable
data class Note(
    val id: Int,
    val title: String,
    val content: String,
    val tenantId: Int,
    val userId: Int,
    val createdAt: String,
    val updatedAt: String,
    val authorEmail: String? = null
)

@Serializable
data class LoginRequest(
    val email: String,
    val password: String
)

@Serializable
data class LoginResponse(
    val token: String,
    val user: User
)

@Serializable
data class CreateNoteRequest(
    val title: String,
    val content: String
)

class NotesApp {
    private var currentUser: User? = null
    private var authToken: String? = null
    private val apiBaseUrl = "https://your-backend-url.vercel.app" // Replace with actual Vercel URL

    fun start() {
        document.addEventListener("DOMContentLoaded", {
            showLoginForm()
        })
    }

    private fun showLoginForm() {
        document.body?.let { body ->
            body.innerHTML = ""
            body.append {
                div {
                    id = "app"
                    style = "max-width: 800px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;"
                    
                    h1 {
                        textAlign = TextAlign.center
                        +"Multi-Tenant SaaS Notes"
                        style = "color: #333; margin-bottom: 30px;"
                    }
                    
                    div {
                        id = "login-form"
                        style = "background: #f5f5f5; padding: 30px; border-radius: 8px; margin-bottom: 20px;"
                        
                        h2 {
                            +"Login"
                            style = "margin-bottom: 20px; color: #333;"
                        }
                        
                        form {
                            onSubmitFunction = { event ->
                                event.preventDefault()
                                handleLogin()
                            }
                            
                            div {
                                style = "margin-bottom: 15px;"
                                label {
                                    htmlFor = "email"
                                    +"Email:"
                                    style = "display: block; margin-bottom: 5px; font-weight: bold;"
                                }
                                input {
                                    type = InputType.email
                                    id = "email"
                                    name = "email"
                                    required = true
                                    style = "width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; box-sizing: border-box;"
                                }
                            }
                            
                            div {
                                style = "margin-bottom: 20px;"
                                label {
                                    htmlFor = "password"
                                    +"Password:"
                                    style = "display: block; margin-bottom: 5px; font-weight: bold;"
                                }
                                input {
                                    type = InputType.password
                                    id = "password"
                                    name = "password"
                                    required = true
                                    style = "width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; box-sizing: border-box;"
                                }
                            }
                            
                            button {
                                type = ButtonType.submit
                                +"Login"
                                style = "width: 100%; padding: 12px; background: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 16px;"
                            }
                        }
                        
                        div {
                            style = "margin-top: 20px; padding: 15px; background: #e9ecef; border-radius: 4px;"
                            h3 {
                                +"Test Accounts (password: password)"
                                style = "margin-bottom: 10px; color: #333;"
                            }
                            ul {
                                style = "margin: 0; padding-left: 20px;"
                                li { +"admin@acme.test (Admin, Acme)" }
                                li { +"user@acme.test (Member, Acme)" }
                                li { +"admin@globex.test (Admin, Globex)" }
                                li { +"user@globex.test (Member, Globex)" }
                            }
                        }
                    }
                    
                    div {
                        id = "error-message"
                        style = "display: none; background: #f8d7da; color: #721c24; padding: 15px; border-radius: 4px; margin-bottom: 20px;"
                    }
                }
            }
        }
    }

    private fun handleLogin() {
        val email = (document.getElementById("email") as? org.w3c.dom.HTMLInputElement)?.value ?: ""
        val password = (document.getElementById("password") as? org.w3c.dom.HTMLInputElement)?.value ?: ""

        if (email.isEmpty() || password.isEmpty()) {
            showError("Please enter both email and password")
            return
        }

        GlobalScope.launch {
            try {
                val response = fetch("$apiBaseUrl/auth/login", object {
                    val method = "POST"
                    val headers = js("{}")
                    val body = Json.encodeToString(LoginRequest.serializer(), LoginRequest(email, password))
                }.asDynamic())

                if (response.ok) {
                    val responseText = response.text().await()
                    val loginResponse = Json.decodeFromString<LoginResponse>(responseText)
                    currentUser = loginResponse.user
                    authToken = loginResponse.token
                    showNotesApp()
                } else {
                    val error = response.text().await()
                    showError("Login failed: $error")
                }
            } catch (e: Exception) {
                showError("Login error: ${e.message}")
            }
        }
    }

    private fun showNotesApp() {
        document.body?.let { body ->
            body.innerHTML = ""
            body.append {
                div {
                    id = "app"
                    style = "max-width: 1000px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;"
                    
                    div {
                        style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px; padding: 15px; background: #f8f9fa; border-radius: 8px;"
                        
                        div {
                            h1 {
                                +"Notes App"
                                style = "margin: 0; color: #333;"
                            }
                            p {
                                style = "margin: 5px 0 0 0; color: #666;"
                                +"Welcome, ${currentUser?.email} (${currentUser?.role}) - ${currentUser?.tenant?.name} (${currentUser?.tenant?.plan})"
                            }
                        }
                        
                        div {
                            button {
                                +"Logout"
                                onClickFunction = { showLoginForm() }
                                style = "padding: 8px 16px; background: #dc3545; color: white; border: none; border-radius: 4px; cursor: pointer;"
                            }
                        }
                    }
                    
                    div {
                        id = "notes-container"
                        style = "display: grid; grid-template-columns: 1fr 1fr; gap: 20px;"
                        
                        div {
                            style = "background: #f8f9fa; padding: 20px; border-radius: 8px;"
                            
                            h2 {
                                +"Create New Note"
                                style = "margin-bottom: 15px; color: #333;"
                            }
                            
                            form {
                                id = "create-note-form"
                                onSubmitFunction = { event ->
                                    event.preventDefault()
                                    createNote()
                                }
                                
                                div {
                                    style = "margin-bottom: 15px;"
                                    label {
                                        htmlFor = "note-title"
                                        +"Title:"
                                        style = "display: block; margin-bottom: 5px; font-weight: bold;"
                                    }
                                    input {
                                        type = InputType.text
                                        id = "note-title"
                                        required = true
                                        style = "width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; box-sizing: border-box;"
                                    }
                                }
                                
                                div {
                                    style = "margin-bottom: 15px;"
                                    label {
                                        htmlFor = "note-content"
                                        +"Content:"
                                        style = "display: block; margin-bottom: 5px; font-weight: bold;"
                                    }
                                    textArea {
                                        id = "note-content"
                                        rows = "4"
                                        style = "width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; box-sizing: border-box; resize: vertical;"
                                    }
                                }
                                
                                button {
                                    type = ButtonType.submit
                                    +"Create Note"
                                    style = "width: 100%; padding: 12px; background: #28a745; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 16px;"
                                }
                            }
                            
                            // Upgrade button for admins on free plan
                            if (currentUser?.role == "admin" && currentUser?.tenant?.plan == "free") {
                                div {
                                    style = "margin-top: 20px; padding: 15px; background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 4px;"
                                    h3 {
                                        +"Upgrade to Pro"
                                        style = "margin-bottom: 10px; color: #856404;"
                                    }
                                    p {
                                        +"Unlock unlimited notes for your organization"
                                        style = "margin-bottom: 10px; color: #856404;"
                                    }
                                    button {
                                        +"Upgrade Now"
                                        onClickFunction = { upgradeTenant() }
                                        style = "width: 100%; padding: 10px; background: #ffc107; color: #212529; border: none; border-radius: 4px; cursor: pointer; font-weight: bold;"
                                    }
                                }
                            }
                        }
                        
                        div {
                            style = "background: #f8f9fa; padding: 20px; border-radius: 8px;"
                            
                            h2 {
                                +"Your Notes"
                                style = "margin-bottom: 15px; color: #333;"
                            }
                            
                            div {
                                id = "notes-list"
                                style = "max-height: 500px; overflow-y: auto;"
                            }
                        }
                    }
                    
                    div {
                        id = "error-message"
                        style = "display: none; background: #f8d7da; color: #721c24; padding: 15px; border-radius: 4px; margin-top: 20px;"
                    }
                }
            }
        }
        
        loadNotes()
    }

    private fun createNote() {
        val title = (document.getElementById("note-title") as? org.w3c.dom.HTMLInputElement)?.value ?: ""
        val content = (document.getElementById("note-content") as? org.w3c.dom.HTMLTextAreaElement)?.value ?: ""

        if (title.isEmpty()) {
            showError("Title is required")
            return
        }

        GlobalScope.launch {
            try {
                val response = fetch("$apiBaseUrl/notes", object {
                    val method = "POST"
                    val headers = js("{}")
                    val body = Json.encodeToString(CreateNoteRequest.serializer(), CreateNoteRequest(title, content))
                }.asDynamic())

                if (response.ok) {
                    (document.getElementById("note-title") as? org.w3c.dom.HTMLInputElement)?.value = ""
                    (document.getElementById("note-content") as? org.w3c.dom.HTMLTextAreaElement)?.value = ""
                    loadNotes()
                } else {
                    val error = response.text().await()
                    showError("Failed to create note: $error")
                }
            } catch (e: Exception) {
                showError("Error creating note: ${e.message}")
            }
        }
    }

    private fun loadNotes() {
        GlobalScope.launch {
            try {
                val response = fetch("$apiBaseUrl/notes", object {
                    val method = "GET"
                    val headers = js("{}")
                }.asDynamic())

                if (response.ok) {
                    val responseText = response.text().await()
                    val notes = Json.decodeFromString<List<Note>>(responseText)
                    displayNotes(notes)
                } else {
                    val error = response.text().await()
                    showError("Failed to load notes: $error")
                }
            } catch (e: Exception) {
                showError("Error loading notes: ${e.message}")
            }
        }
    }

    private fun displayNotes(notes: List<Note>) {
        val notesList = document.getElementById("notes-list")
        notesList?.let { list ->
            list.innerHTML = ""
            
            if (notes.isEmpty()) {
                list.append {
                    p {
                        +"No notes yet. Create your first note!"
                        style = "text-align: center; color: #666; padding: 20px;"
                    }
                }
            } else {
                notes.forEach { note ->
                    list.append {
                        div {
                            style = "background: white; padding: 15px; margin-bottom: 10px; border-radius: 4px; border: 1px solid #ddd;"
                            
                            h3 {
                                +note.title
                                style = "margin: 0 0 10px 0; color: #333;"
                            }
                            
                            p {
                                +note.content
                                style = "margin: 0 0 10px 0; color: #666; white-space: pre-wrap;"
                            }
                            
                            div {
                                style = "display: flex; justify-content: space-between; align-items: center; font-size: 12px; color: #999;"
                                
                                span {
                                    +"By ${note.authorEmail ?: "Unknown"} • ${note.createdAt.substring(0, 10)}"
                                }
                                
                                button {
                                    +"Delete"
                                    onClickFunction = { deleteNote(note.id) }
                                    style = "padding: 4px 8px; background: #dc3545; color: white; border: none; border-radius: 3px; cursor: pointer; font-size: 12px;"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private fun deleteNote(noteId: Int) {
        if (!window.confirm("Are you sure you want to delete this note?")) {
            return
        }

        GlobalScope.launch {
            try {
                val response = fetch("$apiBaseUrl/notes/$noteId", object {
                    val method = "DELETE"
                    val headers = js("{}")
                }.asDynamic())

                if (response.ok) {
                    loadNotes()
                } else {
                    val error = response.text().await()
                    showError("Failed to delete note: $error")
                }
            } catch (e: Exception) {
                showError("Error deleting note: ${e.message}")
            }
        }
    }

    private fun upgradeTenant() {
        val tenantSlug = currentUser?.tenant?.slug ?: return

        GlobalScope.launch {
            try {
                val response = fetch("$apiBaseUrl/tenants/$tenantSlug/upgrade", object {
                    val method = "POST"
                    val headers = js("{}")
                }.asDynamic())

                if (response.ok) {
                    currentUser = currentUser?.copy(tenant = currentUser?.tenant?.copy(plan = "pro"))
                    showNotesApp() // Refresh the app to show updated plan
                } else {
                    val error = response.text().await()
                    showError("Failed to upgrade tenant: $error")
                }
            } catch (e: Exception) {
                showError("Error upgrading tenant: ${e.message}")
            }
        }
    }

    private fun showError(message: String) {
        val errorDiv = document.getElementById("error-message")
        errorDiv?.let { div ->
            div.innerHTML = message
            div.style.display = "block"
            
            // Hide error after 5 seconds
            window.setTimeout({
                div.style.display = "none"
            }, 5000)
        }
    }
}

fun main() {
    NotesApp().start()
}
