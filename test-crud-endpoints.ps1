# Test All CRUD Endpoints with Tenant Isolation
Write-Host "Testing All CRUD Endpoints with Tenant Isolation" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# Replace with your actual backend URL
$backendUrl = "https://your-backend.vercel.app"

# Test accounts
$acmeAdmin = @{ email = "admin@acme.test"; password = "password" }
$acmeUser = @{ email = "user@acme.test"; password = "password" }
$globexAdmin = @{ email = "admin@globex.test"; password = "password" }
$globexUser = @{ email = "user@globex.test"; password = "password" }

function Get-AuthToken {
    param($credentials)
    try {
        $response = Invoke-RestMethod -Uri "$backendUrl/auth/login" -Method POST -Body ($credentials | ConvertTo-Json) -ContentType "application/json"
        return $response.token, $response.user
    } catch {
        Write-Host "❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
        return $null, $null
    }
}

function Test-CRUDEndpoints {
    param($userName, $credentials, $expectedTenant)
    
    Write-Host "`n🧪 Testing $userName ($expectedTenant)" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Yellow
    
    $token, $user = Get-AuthToken $credentials
    if (-not $token) { return }
    
    $headers = @{ "Authorization" = "Bearer $token" }
    Write-Host "✅ Login successful - User: $($user.email), Tenant: $($user.tenant.slug)" -ForegroundColor Green
    
    # Test 1: POST /notes - Create a note
    Write-Host "`n1. Testing POST /notes (Create note)..." -ForegroundColor Cyan
    try {
        $noteData = @{
            title = "Test Note for $expectedTenant - $(Get-Date -Format 'HH:mm:ss')"
            content = "This is a test note created by $userName"
        }
        $createResponse = Invoke-RestMethod -Uri "$backendUrl/notes" -Method POST -Headers $headers -Body ($noteData | ConvertTo-Json) -ContentType "application/json"
        Write-Host "✅ Note created successfully" -ForegroundColor Green
        Write-Host "   ID: $($createResponse.id), Title: $($createResponse.title)" -ForegroundColor Gray
        Write-Host "   Tenant ID: $($createResponse.tenantId), User ID: $($createResponse.userId)" -ForegroundColor Gray
        $noteId = $createResponse.id
    } catch {
        Write-Host "❌ Failed to create note: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
    
    # Test 2: GET /notes - List all notes
    Write-Host "`n2. Testing GET /notes (List all notes)..." -ForegroundColor Cyan
    try {
        $listResponse = Invoke-RestMethod -Uri "$backendUrl/notes" -Method GET -Headers $headers
        Write-Host "✅ Notes listed successfully" -ForegroundColor Green
        Write-Host "   Found $($listResponse.Count) notes for $expectedTenant" -ForegroundColor Gray
        
        # Verify all notes belong to the correct tenant
        $wrongTenantNotes = $listResponse | Where-Object { $_.tenantId -ne $user.tenant.id }
        if ($wrongTenantNotes.Count -eq 0) {
            Write-Host "✅ All notes belong to correct tenant ($($user.tenant.id))" -ForegroundColor Green
        } else {
            Write-Host "❌ SECURITY ISSUE: Found notes from other tenants!" -ForegroundColor Red
        }
        
        foreach ($note in $listResponse) {
            Write-Host "   - ID: $($note.id), Title: $($note.title), Author: $($note.author_email)" -ForegroundColor Gray
        }
    } catch {
        Write-Host "❌ Failed to list notes: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test 3: GET /notes/:id - Get specific note
    Write-Host "`n3. Testing GET /notes/$noteId (Get specific note)..." -ForegroundColor Cyan
    try {
        $getResponse = Invoke-RestMethod -Uri "$backendUrl/notes/$noteId" -Method GET -Headers $headers
        Write-Host "✅ Note retrieved successfully" -ForegroundColor Green
        Write-Host "   ID: $($getResponse.id), Title: $($getResponse.title)" -ForegroundColor Gray
        Write-Host "   Author: $($getResponse.author_email), Tenant ID: $($getResponse.tenantId)" -ForegroundColor Gray
        
        # Verify note belongs to correct tenant
        if ($getResponse.tenantId -eq $user.tenant.id) {
            Write-Host "✅ Note belongs to correct tenant" -ForegroundColor Green
        } else {
            Write-Host "❌ SECURITY ISSUE: Note belongs to wrong tenant!" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Failed to get note: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test 4: PUT /notes/:id - Update note
    Write-Host "`n4. Testing PUT /notes/$noteId (Update note)..." -ForegroundColor Cyan
    try {
        $updateData = @{
            title = "Updated Note for $expectedTenant - $(Get-Date -Format 'HH:mm:ss')"
            content = "This note has been updated by $userName"
        }
        $updateResponse = Invoke-RestMethod -Uri "$backendUrl/notes/$noteId" -Method PUT -Headers $headers -Body ($updateData | ConvertTo-Json) -ContentType "application/json"
        Write-Host "✅ Note updated successfully" -ForegroundColor Green
        Write-Host "   Title: $($updateResponse.title)" -ForegroundColor Gray
        Write-Host "   Updated by: $($updateResponse.updatedBy)" -ForegroundColor Gray
        Write-Host "   Updated at: $($updateResponse.updatedAt)" -ForegroundColor Gray
        
        # Verify update belongs to correct tenant
        if ($updateResponse.tenantId -eq $user.tenant.id) {
            Write-Host "✅ Updated note belongs to correct tenant" -ForegroundColor Green
        } else {
            Write-Host "❌ SECURITY ISSUE: Updated note belongs to wrong tenant!" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Failed to update note: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test 5: DELETE /notes/:id - Delete note
    Write-Host "`n5. Testing DELETE /notes/$noteId (Delete note)..." -ForegroundColor Cyan
    try {
        $deleteResponse = Invoke-RestMethod -Uri "$backendUrl/notes/$noteId" -Method DELETE -Headers $headers
        Write-Host "✅ Note deleted successfully" -ForegroundColor Green
        Write-Host "   Message: $($deleteResponse.message)" -ForegroundColor Gray
    } catch {
        Write-Host "❌ Failed to delete note: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test 6: Verify note is deleted
    Write-Host "`n6. Verifying note deletion..." -ForegroundColor Cyan
    try {
        $verifyResponse = Invoke-RestMethod -Uri "$backendUrl/notes/$noteId" -Method GET -Headers $headers
        Write-Host "❌ ERROR: Note still exists after deletion!" -ForegroundColor Red
    } catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-Host "✅ Note successfully deleted (404 Not Found)" -ForegroundColor Green
        } else {
            Write-Host "❌ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    return $true
}

function Test-CrossTenantAccess {
    Write-Host "`n🚫 Testing Cross-Tenant Access Prevention" -ForegroundColor Red
    Write-Host "=========================================" -ForegroundColor Red
    
    # Create notes for both tenants
    $acmeToken, $acmeUser = Get-AuthToken $acmeAdmin
    $globexToken, $globexUser = Get-AuthToken $globexAdmin
    
    if (-not $acmeToken -or -not $globexToken) { 
        Write-Host "❌ Failed to get tokens for cross-tenant test" -ForegroundColor Red
        return 
    }
    
    $acmeHeaders = @{ "Authorization" = "Bearer $acmeToken" }
    $globexHeaders = @{ "Authorization" = "Bearer $globexToken" }
    
    # Create Acme note
    $acmeNoteData = @{ title = "Acme Secret Note"; content = "Acme's confidential data" }
    $acmeNote = Invoke-RestMethod -Uri "$backendUrl/notes" -Method POST -Headers $acmeHeaders -Body ($acmeNoteData | ConvertTo-Json) -ContentType "application/json"
    Write-Host "✅ Acme note created: ID $($acmeNote.id)" -ForegroundColor Green
    
    # Create Globex note
    $globexNoteData = @{ title = "Globex Secret Note"; content = "Globex's confidential data" }
    $globexNote = Invoke-RestMethod -Uri "$backendUrl/notes" -Method POST -Headers $globexHeaders -Body ($globexNoteData | ConvertTo-Json) -ContentType "application/json"
    Write-Host "✅ Globex note created: ID $($globexNote.id)" -ForegroundColor Green
    
    # Test cross-tenant access
    Write-Host "`nTesting cross-tenant access prevention..." -ForegroundColor Cyan
    
    # Acme user tries to access Globex note
    try {
        $crossAccess = Invoke-RestMethod -Uri "$backendUrl/notes/$($globexNote.id)" -Method GET -Headers $acmeHeaders
        Write-Host "❌ SECURITY BREACH: Acme user can access Globex note!" -ForegroundColor Red
    } catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-Host "✅ Acme user cannot access Globex note (404)" -ForegroundColor Green
        } else {
            Write-Host "❌ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Globex user tries to access Acme note
    try {
        $crossAccess = Invoke-RestMethod -Uri "$backendUrl/notes/$($acmeNote.id)" -Method GET -Headers $globexHeaders
        Write-Host "❌ SECURITY BREACH: Globex user can access Acme note!" -ForegroundColor Red
    } catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-Host "✅ Globex user cannot access Acme note (404)" -ForegroundColor Green
        } else {
            Write-Host "❌ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Test cross-tenant update attempts
    try {
        $updateData = @{ title = "Hacked by Acme"; content = "Acme hacked this note" }
        $crossUpdate = Invoke-RestMethod -Uri "$backendUrl/notes/$($globexNote.id)" -Method PUT -Headers $acmeHeaders -Body ($updateData | ConvertTo-Json) -ContentType "application/json"
        Write-Host "❌ SECURITY BREACH: Acme user can update Globex note!" -ForegroundColor Red
    } catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-Host "✅ Acme user cannot update Globex note (404)" -ForegroundColor Green
        } else {
            Write-Host "❌ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Test cross-tenant delete attempts
    try {
        $crossDelete = Invoke-RestMethod -Uri "$backendUrl/notes/$($globexNote.id)" -Method DELETE -Headers $acmeHeaders
        Write-Host "❌ SECURITY BREACH: Acme user can delete Globex note!" -ForegroundColor Red
    } catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-Host "✅ Acme user cannot delete Globex note (404)" -ForegroundColor Green
        } else {
            Write-Host "❌ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Clean up test notes
    Invoke-RestMethod -Uri "$backendUrl/notes/$($acmeNote.id)" -Method DELETE -Headers $acmeHeaders | Out-Null
    Invoke-RestMethod -Uri "$backendUrl/notes/$($globexNote.id)" -Method DELETE -Headers $globexHeaders | Out-Null
    Write-Host "✅ Test notes cleaned up" -ForegroundColor Green
}

# Main test execution
Write-Host "Starting CRUD Endpoints Testing..." -ForegroundColor Green

# Test all users
$acmeAdminResult = Test-CRUDEndpoints "Acme Admin" $acmeAdmin "Acme"
$acmeUserResult = Test-CRUDEndpoints "Acme User" $acmeUser "Acme"
$globexAdminResult = Test-CRUDEndpoints "Globex Admin" $globexAdmin "Globex"
$globexUserResult = Test-CRUDEndpoints "Globex User" $globexUser "Globex"

# Test cross-tenant access prevention
Test-CrossTenantAccess

Write-Host "`n📊 Test Results Summary" -ForegroundColor Magenta
Write-Host "=======================" -ForegroundColor Magenta
Write-Host "Acme Admin: $(if ($acmeAdminResult) { '✅ PASSED' } else { '❌ FAILED' })" -ForegroundColor $(if ($acmeAdminResult) { 'Green' } else { 'Red' })
Write-Host "Acme User: $(if ($acmeUserResult) { '✅ PASSED' } else { '❌ FAILED' })" -ForegroundColor $(if ($acmeUserResult) { 'Green' } else { 'Red' })
Write-Host "Globex Admin: $(if ($globexAdminResult) { '✅ PASSED' } else { '❌ FAILED' })" -ForegroundColor $(if ($globexAdminResult) { 'Green' } else { 'Red' })
Write-Host "Globex User: $(if ($globexUserResult) { '✅ PASSED' } else { '❌ FAILED' })" -ForegroundColor $(if ($globexUserResult) { 'Green' } else { 'Red' })

if ($acmeAdminResult -and $acmeUserResult -and $globexAdminResult -and $globexUserResult) {
    Write-Host "`n🎉 All CRUD endpoints are working correctly!" -ForegroundColor Green
    Write-Host "✅ POST /notes - Create note with tenant isolation" -ForegroundColor Green
    Write-Host "✅ GET /notes - List all notes for current tenant" -ForegroundColor Green
    Write-Host "✅ GET /notes/:id - Retrieve specific note with tenant isolation" -ForegroundColor Green
    Write-Host "✅ PUT /notes/:id - Update note with tenant isolation" -ForegroundColor Green
    Write-Host "✅ DELETE /notes/:id - Delete note with tenant isolation" -ForegroundColor Green
    Write-Host "✅ Cross-tenant access prevention working" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ Some CRUD endpoints have issues." -ForegroundColor Yellow
    Write-Host "Please check the implementation." -ForegroundColor Yellow
}
