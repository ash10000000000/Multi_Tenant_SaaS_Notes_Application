# Test Note Count Calculation Per Tenant
Write-Host "Testing Note Count Calculation Per Tenant" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# Replace with your actual backend URL
$backendUrl = "https://your-backend.vercel.app"

# Test accounts
$acmeAdmin = @{ email = "admin@acme.test"; password = "password" }
$globexAdmin = @{ email = "admin@globex.test"; password = "password" }

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

function Test-NoteCountPerTenant {
    param($userName, $credentials, $expectedTenant)
    
    Write-Host "`n🧪 Testing $userName ($expectedTenant)" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Yellow
    
    $token, $user = Get-AuthToken $credentials
    if (-not $token) { return }
    
    $headers = @{ "Authorization" = "Bearer $token" }
    
    # Test 1: Get current note count
    Write-Host "1. Getting current note count..." -ForegroundColor Cyan
    try {
        $notesResponse = Invoke-RestMethod -Uri "$backendUrl/notes" -Method GET -Headers $headers
        $noteCount = $notesResponse.Count
        Write-Host "✅ Current note count: $noteCount" -ForegroundColor Green
        
        # Test 2: Get tenant info
        Write-Host "2. Getting tenant information..." -ForegroundColor Cyan
        $tenantResponse = Invoke-RestMethod -Uri "$backendUrl/tenants/$($user.tenant.slug)" -Method GET -Headers $headers
        Write-Host "✅ Tenant info retrieved" -ForegroundColor Green
        Write-Host "   Tenant: $($tenantResponse.name)" -ForegroundColor Gray
        Write-Host "   Plan: $($tenantResponse.plan)" -ForegroundColor Gray
        Write-Host "   Note Count: $($tenantResponse.noteCount)" -ForegroundColor Gray
        Write-Host "   Note Limit: $($tenantResponse.noteLimit)" -ForegroundColor Gray
        Write-Host "   Can Create Note: $($tenantResponse.canCreateNote)" -ForegroundColor Gray
        
        # Verify note counts match
        if ($noteCount -eq $tenantResponse.noteCount) {
            Write-Host "✅ Note counts match between /notes and /tenants endpoints" -ForegroundColor Green
        } else {
            Write-Host "❌ MISMATCH: /notes shows $noteCount, /tenants shows $($tenantResponse.noteCount)" -ForegroundColor Red
        }
        
        # Test 3: Create a test note
        Write-Host "3. Creating test note..." -ForegroundColor Cyan
        $noteData = @{
            title = "Test Note for $expectedTenant - $(Get-Date -Format 'HH:mm:ss')"
            content = "This is a test note to verify note count calculation"
        }
        $createResponse = Invoke-RestMethod -Uri "$backendUrl/notes" -Method POST -Headers $headers -Body ($noteData | ConvertTo-Json) -ContentType "application/json"
        Write-Host "✅ Test note created with ID: $($createResponse.id)" -ForegroundColor Green
        
        # Test 4: Verify note count increased
        Write-Host "4. Verifying note count increased..." -ForegroundColor Cyan
        $newNotesResponse = Invoke-RestMethod -Uri "$backendUrl/notes" -Method GET -Headers $headers
        $newNoteCount = $newNotesResponse.Count
        Write-Host "✅ New note count: $newNoteCount" -ForegroundColor Green
        
        if ($newNoteCount -eq ($noteCount + 1)) {
            Write-Host "✅ Note count correctly increased by 1" -ForegroundColor Green
        } else {
            Write-Host "❌ ERROR: Note count should be $($noteCount + 1) but is $newNoteCount" -ForegroundColor Red
        }
        
        # Test 5: Get updated tenant info
        Write-Host "5. Getting updated tenant information..." -ForegroundColor Cyan
        $updatedTenantResponse = Invoke-RestMethod -Uri "$backendUrl/tenants/$($user.tenant.slug)" -Method GET -Headers $headers
        Write-Host "✅ Updated tenant info retrieved" -ForegroundColor Green
        Write-Host "   Updated Note Count: $($updatedTenantResponse.noteCount)" -ForegroundColor Gray
        Write-Host "   Can Create Note: $($updatedTenantResponse.canCreateNote)" -ForegroundColor Gray
        
        # Verify updated note counts match
        if ($newNoteCount -eq $updatedTenantResponse.noteCount) {
            Write-Host "✅ Updated note counts match between /notes and /tenants endpoints" -ForegroundColor Green
        } else {
            Write-Host "❌ MISMATCH: /notes shows $newNoteCount, /tenants shows $($updatedTenantResponse.noteCount)" -ForegroundColor Red
        }
        
        # Clean up test note
        Write-Host "6. Cleaning up test note..." -ForegroundColor Cyan
        Invoke-RestMethod -Uri "$backendUrl/notes/$($createResponse.id)" -Method DELETE -Headers $headers | Out-Null
        Write-Host "✅ Test note deleted" -ForegroundColor Green
        
        return $true
    } catch {
        Write-Host "❌ Error during testing: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Test both tenants
Write-Host "Testing Note Count Calculation for Both Tenants" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

$acmeResult = Test-NoteCountPerTenant "Acme Admin" $acmeAdmin "Acme"
$globexResult = Test-NoteCountPerTenant "Globex Admin" $globexAdmin "Globex"

Write-Host "`n📊 Test Results Summary" -ForegroundColor Magenta
Write-Host "=======================" -ForegroundColor Magenta
Write-Host "Acme Corporation: $(if ($acmeResult) { '✅ PASSED' } else { '❌ FAILED' })" -ForegroundColor $(if ($acmeResult) { 'Green' } else { 'Red' })
Write-Host "Globex Corporation: $(if ($globexResult) { '✅ PASSED' } else { '❌ FAILED' })" -ForegroundColor $(if ($globexResult) { 'Green' } else { 'Red' })

if ($acmeResult -and $globexResult) {
    Write-Host "`n🎉 All note count calculations are working correctly!" -ForegroundColor Green
    Write-Host "Each tenant's note count is calculated separately and accurately." -ForegroundColor Green
} else {
    Write-Host "`n⚠️ Some issues detected with note count calculation." -ForegroundColor Yellow
    Write-Host "Please check the backend implementation." -ForegroundColor Yellow
}
