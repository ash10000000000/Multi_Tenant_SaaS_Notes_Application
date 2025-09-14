# Quick Test of CRUD Endpoints
Write-Host "Quick Test of CRUD Endpoints" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green

# Replace with your actual backend URL
$backendUrl = "https://your-backend.vercel.app"

# Test with Acme admin
$credentials = @{ email = "admin@acme.test"; password = "password" }

try {
    # Login
    Write-Host "1. Logging in..." -ForegroundColor Cyan
    $loginResponse = Invoke-RestMethod -Uri "$backendUrl/auth/login" -Method POST -Body ($credentials | ConvertTo-Json) -ContentType "application/json"
    $token = $loginResponse.token
    $headers = @{ "Authorization" = "Bearer $token" }
    Write-Host "✅ Login successful" -ForegroundColor Green
    
    # Test GET /notes
    Write-Host "2. Testing GET /notes..." -ForegroundColor Cyan
    $notesResponse = Invoke-RestMethod -Uri "$backendUrl/notes" -Method GET -Headers $headers
    Write-Host "✅ GET /notes successful - Found $($notesResponse.Count) notes" -ForegroundColor Green
    
    # Test POST /notes
    Write-Host "3. Testing POST /notes..." -ForegroundColor Cyan
    $noteData = @{ title = "Test Note $(Get-Date -Format 'HH:mm:ss')"; content = "Test content" }
    $createResponse = Invoke-RestMethod -Uri "$backendUrl/notes" -Method POST -Headers $headers -Body ($noteData | ConvertTo-Json) -ContentType "application/json"
    Write-Host "✅ POST /notes successful - Created note ID: $($createResponse.id)" -ForegroundColor Green
    
    # Test GET /notes/:id
    Write-Host "4. Testing GET /notes/$($createResponse.id)..." -ForegroundColor Cyan
    $getResponse = Invoke-RestMethod -Uri "$backendUrl/notes/$($createResponse.id)" -Method GET -Headers $headers
    Write-Host "✅ GET /notes/:id successful - Retrieved: $($getResponse.title)" -ForegroundColor Green
    
    # Test PUT /notes/:id
    Write-Host "5. Testing PUT /notes/$($createResponse.id)..." -ForegroundColor Cyan
    $updateData = @{ title = "Updated Note $(Get-Date -Format 'HH:mm:ss')"; content = "Updated content" }
    $updateResponse = Invoke-RestMethod -Uri "$backendUrl/notes/$($createResponse.id)" -Method PUT -Headers $headers -Body ($updateData | ConvertTo-Json) -ContentType "application/json"
    Write-Host "✅ PUT /notes/:id successful - Updated: $($updateResponse.title)" -ForegroundColor Green
    
    # Test DELETE /notes/:id
    Write-Host "6. Testing DELETE /notes/$($createResponse.id)..." -ForegroundColor Cyan
    $deleteResponse = Invoke-RestMethod -Uri "$backendUrl/notes/$($createResponse.id)" -Method DELETE -Headers $headers
    Write-Host "✅ DELETE /notes/:id successful - $($deleteResponse.message)" -ForegroundColor Green
    
    Write-Host "`n🎉 All CRUD endpoints are working correctly!" -ForegroundColor Green
    Write-Host "✅ POST /notes - Create note" -ForegroundColor Green
    Write-Host "✅ GET /notes - List all notes for current tenant" -ForegroundColor Green
    Write-Host "✅ GET /notes/:id - Retrieve specific note" -ForegroundColor Green
    Write-Host "✅ PUT /notes/:id - Update note" -ForegroundColor Green
    Write-Host "✅ DELETE /notes/:id - Delete note" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
}
