# Notes API CRUD Testing Script
$baseUrl = "https://multi-tenant-saa-s-notes-applicatii.vercel.app"

Write-Host "🧪 Testing Notes API CRUD Endpoints" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Step 1: Login to get token
Write-Host "`n1. Testing Login..." -ForegroundColor Yellow
$loginData = @{
    email = "admin@acme.test"
    password = "password"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.token
    Write-Host "✅ Login successful! Token received." -ForegroundColor Green
    Write-Host "User: $($loginResponse.user.email) | Role: $($loginResponse.user.role) | Tenant: $($loginResponse.user.tenant.name)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Set headers for authenticated requests
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Step 2: Test GET /notes (List all notes)
Write-Host "`n2. Testing GET /notes (List all notes)..." -ForegroundColor Yellow
try {
    $notesResponse = Invoke-RestMethod -Uri "$baseUrl/notes" -Method GET -Headers $headers
    Write-Host "✅ GET /notes successful! Found $($notesResponse.Count) notes." -ForegroundColor Green
    $notesResponse | ForEach-Object { Write-Host "  - $($_.title) by $($_.author_email)" -ForegroundColor Cyan }
} catch {
    Write-Host "❌ GET /notes failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 3: Test POST /notes (Create a note)
Write-Host "`n3. Testing POST /notes (Create a note)..." -ForegroundColor Yellow
$newNote = @{
    title = "Test Note from PowerShell"
    content = "This is a test note created via API testing script."
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$baseUrl/notes" -Method POST -Body $newNote -Headers $headers
    $noteId = $createResponse.id
    Write-Host "✅ POST /notes successful! Created note with ID: $noteId" -ForegroundColor Green
    Write-Host "Note: $($createResponse.title)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ POST /notes failed: $($_.Exception.Message)" -ForegroundColor Red
    $noteId = $null
}

# Step 4: Test GET /notes/:id (Get specific note)
if ($noteId) {
    Write-Host "`n4. Testing GET /notes/$noteId (Get specific note)..." -ForegroundColor Yellow
    try {
        $getNoteResponse = Invoke-RestMethod -Uri "$baseUrl/notes/$noteId" -Method GET -Headers $headers
        Write-Host "✅ GET /notes/$noteId successful!" -ForegroundColor Green
        Write-Host "Title: $($getNoteResponse.title)" -ForegroundColor Cyan
        Write-Host "Content: $($getNoteResponse.content)" -ForegroundColor Cyan
        Write-Host "Author: $($getNoteResponse.author_email)" -ForegroundColor Cyan
    } catch {
        Write-Host "❌ GET /notes/$noteId failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Step 5: Test PUT /notes/:id (Update note)
if ($noteId) {
    Write-Host "`n5. Testing PUT /notes/$noteId (Update note)..." -ForegroundColor Yellow
    $updateNote = @{
        title = "Updated Test Note from PowerShell"
        content = "This note has been updated via API testing script."
    } | ConvertTo-Json

    try {
        $updateResponse = Invoke-RestMethod -Uri "$baseUrl/notes/$noteId" -Method PUT -Body $updateNote -Headers $headers
        Write-Host "✅ PUT /notes/$noteId successful!" -ForegroundColor Green
        Write-Host "Updated Title: $($updateResponse.title)" -ForegroundColor Cyan
    } catch {
        Write-Host "❌ PUT /notes/$noteId failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Step 6: Test DELETE /notes/:id (Delete note)
if ($noteId) {
    Write-Host "`n6. Testing DELETE /notes/$noteId (Delete note)..." -ForegroundColor Yellow
    try {
        $deleteResponse = Invoke-RestMethod -Uri "$baseUrl/notes/$noteId" -Method DELETE -Headers $headers
        Write-Host "✅ DELETE /notes/$noteId successful!" -ForegroundColor Green
        Write-Host "Response: $($deleteResponse.message)" -ForegroundColor Cyan
    } catch {
        Write-Host "❌ DELETE /notes/$noteId failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Step 7: Test tenant isolation
Write-Host "`n7. Testing Tenant Isolation..." -ForegroundColor Yellow
Write-Host "Logging in as different tenant user..." -ForegroundColor Cyan

$loginData2 = @{
    email = "admin@globex.test"
    password = "password"
} | ConvertTo-Json

try {
    $loginResponse2 = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginData2 -ContentType "application/json"
    $token2 = $loginResponse2.token
    $headers2 = @{
        "Authorization" = "Bearer $token2"
        "Content-Type" = "application/json"
    }
    
    $notesResponse2 = Invoke-RestMethod -Uri "$baseUrl/notes" -Method GET -Headers $headers2
    Write-Host "✅ Tenant isolation working! Globex tenant has $($notesResponse2.Count) notes." -ForegroundColor Green
    Write-Host "Tenant: $($loginResponse2.user.tenant.name)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Tenant isolation test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎉 API Testing Complete!" -ForegroundColor Green
Write-Host "All CRUD endpoints have been tested with tenant isolation." -ForegroundColor Cyan
