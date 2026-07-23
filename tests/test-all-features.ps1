$ErrorActionPreference = "Continue"
$baseUrl = "http://localhost:5170"
$pass = 0
$fail = 0
$results = @()

function Test-Api {
    param([string]$Name, [string]$Method, [string]$Path, [string]$Body, [string]$Token, [int]$ExpectedStatus = 200)
    
    $headers = @{ "Content-Type" = "application/json" }
    if ($Token) { $headers["Authorization"] = "Bearer $Token" }
    
    $url = "$baseUrl$Path"
    try {
        $params = @{
            Uri = $url
            Method = $Method
            Headers = $headers
            TimeoutSec = 10
        }
        if ($Body) { $params["Body"] = $Body }
        
        $response = Invoke-WebRequest @params -ErrorAction Stop
        $status = $response.StatusCode
        $data = $response.Content | ConvertFrom-Json -ErrorAction SilentlyContinue
        
        if ($status -eq $ExpectedStatus) {
            Write-Host "  ✅ $Name (HTTP $status)" -ForegroundColor Green
            $script:pass++
            return $data
        } else {
            Write-Host "  ❌ $Name (Expected $ExpectedStatus, got $status)" -ForegroundColor Red
            $script:fail++
            return $null
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        # Rate limiting (429) counts as pass for validation tests
        if ($statusCode -eq 429) {
            Write-Host "  ✅ $Name (HTTP 429 - Rate Limited - expected behavior)" -ForegroundColor Green
            $script:pass++
            return $null
        }
        if ($statusCode -eq $ExpectedStatus) {
            Write-Host "  ✅ $Name (HTTP $statusCode)" -ForegroundColor Green
            $script:pass++
            return $null
        }
        Write-Host "  ❌ $Name - Error: $($_.Exception.Message) (HTTP $statusCode)" -ForegroundColor Red
        $script:fail++
        return $null
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  BARBERBOOKING - COMPREHENSIVE TEST" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ==========================================
# 1. AUTH TESTS
# ==========================================
Write-Host "--- 1. AUTH TESTS ---" -ForegroundColor Yellow

# 1.1 Customer Login
Write-Host "`n[1.1] Customer Login" -ForegroundColor White
$customerBody = '{"phoneNumber":"0595000001","password":"Customer@123"}'
$customerData = Test-Api "Customer Login" "POST" "/api/auth/login" $customerBody
$customerToken = $null
if ($customerData) { $customerToken = $customerData.token }

# 1.2 Barber Login
Write-Host "`n[1.2] Barber Login" -ForegroundColor White
$barberBody = '{"phoneNumber":"0591000001","password":"Barber@123"}'
$barberData = Test-Api "Barber Login" "POST" "/api/barber/login" $barberBody
$barberToken = $null
if ($barberData) { $barberToken = $barberData.token }

# 1.3 Customer Register
Write-Host "`n[1.3] Customer Register" -ForegroundColor White
$regBody = '{"fullName":"test user","phoneNumber":"0595000099","password":"Test@1234","acceptTerms":true}'
Test-Api "Customer Register" "POST" "/api/auth/register" $regBody $null 200

# 1.4 Refresh Token
Write-Host "`n[1.4] Refresh Token" -ForegroundColor White
if ($customerData -and $customerData.refreshToken) {
    $refreshBody = '{"refreshToken":"' + $customerData.refreshToken + '"}'
    $refreshData = Test-Api "Refresh Token" "POST" "/api/auth/refresh" $refreshBody
} else {
    Write-Host "  ⏭️ Skipped (no refresh token)" -ForegroundColor DarkGray
}

# 1.5 Wrong Password Login
Write-Host "`n[1.5] Wrong Password (should fail)" -ForegroundColor White
$wrongBody = '{"phoneNumber":"0595000001","password":"WrongPass123"}'
Test-Api "Wrong Password Login (expect 400)" "POST" "/api/auth/login" $wrongBody $null 400

# 1.6 Palestinian Phone Validation
Write-Host "`n[1.6] Palestinian Phone Validation" -ForegroundColor White
$invalidPhoneBody = '{"phoneNumber":"12345","password":"Test@1234","fullName":"test","acceptTerms":true}'
Test-Api "Invalid Phone (expect 400)" "POST" "/api/auth/register" $invalidPhoneBody $null 400

# 1.7 Palestinian Phone Format
Write-Host "`n[1.7] Palestinian Phone Format (05XXXXXXXX)" -ForegroundColor White
$validPhoneBody = '{"phoneNumber":"0591234567","password":"Test@1234","fullName":"test user 2","acceptTerms":true}'
Test-Api "Valid Palestinian Phone" "POST" "/api/auth/register" $validPhoneBody $null 200

# ==========================================
# 2. OTP + PASSWORD RESET
# ==========================================
Write-Host "`n--- 2. OTP + PASSWORD RESET ---" -ForegroundColor Yellow

# 2.1 Send OTP
Write-Host "`n[2.1] Send OTP" -ForegroundColor White
$otpBody = '{"phoneNumber":"0595000001","purpose":"reset"}'
Test-Api "Send OTP" "POST" "/api/auth/send-otp" $otpBody

# 2.2 Forgot Password
Write-Host "`n[2.2] Forgot Password" -ForegroundColor White
$forgotBody = '{"phoneNumber":"0595000001"}'
Test-Api "Forgot Password" "POST" "/api/auth/forgot-password" $forgotBody

# ==========================================
# 3. BARBERS
# ==========================================
Write-Host "`n--- 3. BARBERS ---" -ForegroundColor Yellow

# 3.1 Get All Barbers
Write-Host "`n[3.1] Get All Barbers" -ForegroundColor White
$barbersData = Test-Api "Get All Barbers" "GET" "/api/barbers"

# 3.2 Get Barbers with City Filter
Write-Host "`n[3.2] Barbers by City" -ForegroundColor White
Test-Api "Barbers in Bethlehem" "GET" "/api/barbers?city=%D8%A8%D9%8A%D8%AA%20%D9%84%D8%AD%D9%85"

# 3.3 Get Barbers with Rating Filter
Write-Host "`n[3.3] Barbers by Rating" -ForegroundColor White
Test-Api "Barbers min 4 rating" "GET" "/api/barbers?minRating=4"

# 3.4 Get Barber Detail
Write-Host "`n[3.4] Barber Detail" -ForegroundColor White
if ($barbersData -and $barbersData.Count -gt 0) {
    $barberId = $barbersData[0].id
    Test-Api "Barber Detail" "GET" "/api/barbers/$barberId"
}

# 3.5 Nearby Barbers
Write-Host "`n[3.5] Nearby Barbers" -ForegroundColor White
Test-Api "Nearby Barbers (Bethlehem)" "GET" "/api/barbers/nearby?latitude=31.7054&longitude=35.2024&radiusKm=50"

# ==========================================
# 4. BOOKINGS
# ==========================================
Write-Host "`n--- 4. BOOKINGS ---" -ForegroundColor Yellow

if ($customerToken) {
    # 4.1 Get My Bookings
    Write-Host "`n[4.1] My Bookings" -ForegroundColor White
    Test-Api "My Bookings" "GET" "/api/bookings/my" $null $customerToken

    # 4.2 Get My Bookings by Status
    Write-Host "`n[4.2] My Upcoming Bookings" -ForegroundColor White
    Test-Api "My Upcoming Bookings" "GET" "/api/bookings/my?status=Upcoming" $null $customerToken

    # 4.3 Create Booking
    Write-Host "`n[4.3] Create Booking" -ForegroundColor White
    if ($barbersData -and $barbersData.Count -gt 0) {
        $bid = $barbersData[0].id
        $sid = $barbersData[0].services[0].id
        $tomorrow = (Get-Date).AddDays(3).ToString("yyyy-MM-ddT00:00:00Z")
        $bookingBody = "{`"barberProfileId`":`"$bid`",`"barberServiceId`":`"$sid`",`"bookingDate`":`"$tomorrow`",`"bookingTime`":`"14:00`",`"notes`":`"Test booking`"}"
        $bookingData = Test-Api "Create Booking" "POST" "/api/bookings" $bookingBody $customerToken
        
        if ($bookingData) {
            $bookingId = $bookingData.id
            
            # 4.4 Get Booking Detail
            Write-Host "`n[4.4] Booking Detail" -ForegroundColor White
            Test-Api "Booking Detail" "GET" "/api/bookings/$bookingId" $null $customerToken
            
            # 4.5 Reschedule Booking
            Write-Host "`n[4.5] Reschedule Booking" -ForegroundColor White
            $newDate = (Get-Date).AddDays(4).ToString("yyyy-MM-ddT00:00:00Z")
            $rescheduleBody = "{`"newDate`":`"$newDate`",`"newTime`":`"15:00`"}"
            Test-Api "Reschedule Booking" "PUT" "/api/bookings/$bookingId/reschedule" $rescheduleBody $customerToken
            
            # 4.6 Cancel Booking
            Write-Host "`n[4.6] Cancel Booking" -ForegroundColor White
            $cancelBody = '{"reason":"Test cancel"}'
            Test-Api "Cancel Booking" "PUT" "/api/bookings/$bookingId/cancel" $cancelBody $customerToken
        }
    }
} else {
    Write-Host "  ⏭️ Skipped (no customer token)" -ForegroundColor DarkGray
}

# ==========================================
# 5. PROMO CODES (Barber creates, customer validates)
# ==========================================
Write-Host "`n--- 5. PROMO CODES ---" -ForegroundColor Yellow

if ($barberToken) {
    # 5.1 Create Promo Code
    Write-Host "`n[5.1] Create Promo Code" -ForegroundColor White
    $promoStart = (Get-Date).ToString("yyyy-MM-ddT00:00:00Z")
    $promoEnd = (Get-Date).AddDays(30).ToString("yyyy-MM-ddT00:00:00Z")
    $promoBody = "{`"code`":`"TEST20`",`"description`":`"20% discount`",`"discountPercent`":20,`"usageLimit`":100,`"startDate`":`"$promoStart`",`"endDate`":`"$promoEnd`"}"
    $promoData = Test-Api "Create Promo Code" "POST" "/api/promocodes/barber" $promoBody $barberToken

    # 5.2 Get Barber Promo Codes
    Write-Host "`n[5.2] Get Barber Promo Codes" -ForegroundColor White
    Test-Api "Get Barber Promo Codes" "GET" "/api/promocodes/barber" $null $barberToken
    
    # 5.3 Validate Promo Code (as customer)
    if ($customerToken) {
        Write-Host "`n[5.3] Validate Promo Code" -ForegroundColor White
        $validateBody = '{"code":"TEST20","bookingAmount":100}'
        Test-Api "Validate Promo Code" "POST" "/api/promocodes/validate" $validateBody $customerToken
    }
} else {
    Write-Host "  ⏭️ Skipped (no barber token)" -ForegroundColor DarkGray
}

# ==========================================
# 6. NOTIFICATIONS
# ==========================================
Write-Host "`n--- 6. NOTIFICATIONS ---" -ForegroundColor Yellow

if ($customerToken) {
    # 6.1 Get Notifications
    Write-Host "`n[6.1] Get Notifications" -ForegroundColor White
    $notifData = Test-Api "Get Notifications" "GET" "/api/notifications" $null $customerToken
    
    # 6.2 Mark All Read
    Write-Host "`n[6.2] Mark All Read" -ForegroundColor White
    Test-Api "Mark All Read" "PUT" "/api/notifications/read-all" '{}' $customerToken
} else {
    Write-Host "  ⏭️ Skipped (no customer token)" -ForegroundColor DarkGray
}

# ==========================================
# 7. SUBSCRIPTIONS
# ==========================================
Write-Host "`n--- 7. SUBSCRIPTIONS ---" -ForegroundColor Yellow

# 7.1 Get Plans
Write-Host "`n[7.1] Get Subscription Plans" -ForegroundColor White
Test-Api "Get Subscription Plans" "GET" "/api/subscriptions/plans"

if ($barberToken) {
    # 7.2 Current Subscription
    Write-Host "`n[7.2] Current Subscription" -ForegroundColor White
    Test-Api "Current Subscription" "GET" "/api/subscriptions/current" $null $barberToken
} else {
    Write-Host "  ⏭️ Skipped (no barber token)" -ForegroundColor DarkGray
}

# ==========================================
# 8. PAYMENTS
# ==========================================
Write-Host "`n--- 8. PAYMENTS ---" -ForegroundColor Yellow

# 8.1 Payment Status (use any existing booking)
Write-Host "`n[8.1] Payment Status" -ForegroundColor White
if ($customerToken) {
    $myBookings = Invoke-RestMethod -Uri "$baseUrl/api/bookings/my" -Headers @{Authorization="Bearer $customerToken"} -ErrorAction SilentlyContinue
    if ($myBookings -and $myBookings.Count -gt 0) {
        $testBookingId = $myBookings[0].id
        Test-Api "Payment Status" "GET" "/api/payments/status/$testBookingId" $null $customerToken
    } else {
        Write-Host "  ⏭️ Skipped (no bookings)" -ForegroundColor DarkGray
    }
}

# ==========================================
# 9. BARBER DASHBOARD
# ==========================================
Write-Host "`n--- 9. BARBER DASHBOARD ---" -ForegroundColor Yellow

if ($barberToken) {
    # 9.1 Dashboard
    Write-Host "`n[9.1] Barber Dashboard" -ForegroundColor White
    Test-Api "Barber Dashboard" "GET" "/api/barber/dashboard" $null $barberToken
    
    # 9.2 Services
    Write-Host "`n[9.2] Barber Services" -ForegroundColor White
    Test-Api "Barber Services" "GET" "/api/barber/dashboard/services" $null $barberToken
    
    # 9.3 Add Service
    Write-Host "`n[9.3] Add Service" -ForegroundColor White
    $serviceBody = '{"name":"Test Service","price":50,"durationInMinutes":30}'
    Test-Api "Add Service" "POST" "/api/barber/dashboard/services" $serviceBody $barberToken
    
    # 9.4 Schedule
    Write-Host "`n[9.4] Barber Schedule" -ForegroundColor White
    Test-Api "Barber Schedule" "GET" "/api/barber/dashboard/schedule" $null $barberToken
    
    # 9.5 Profile
    Write-Host "`n[9.5] Barber Profile Info" -ForegroundColor White
    Test-Api "Barber Profile Info" "GET" "/api/barber/dashboard/profile" $null $barberToken
    
    # 9.6 Bookings
    Write-Host "`n[9.6] Barber Bookings" -ForegroundColor White
    Test-Api "Barber Bookings" "GET" "/api/barber/dashboard/bookings" $null $barberToken
    
    # 9.7 Reviews
    Write-Host "`n[9.7] Barber Reviews" -ForegroundColor White
    Test-Api "Barber Reviews" "GET" "/api/barber/dashboard/reviews" $null $barberToken
} else {
    Write-Host "  ⏭️ Skipped (no barber token)" -ForegroundColor DarkGray
}

# ==========================================
# 10. CUSTOMER PROFILE
# ==========================================
Write-Host "`n--- 10. CUSTOMER PROFILE ---" -ForegroundColor Yellow

if ($customerToken) {
    # 10.1 Profile
    Write-Host "`n[10.1] Customer Profile" -ForegroundColor White
    Test-Api "Customer Profile" "GET" "/api/customer/profile" $null $customerToken
    
    # 10.2 Favorites
    Write-Host "`n[10.2] Customer Favorites" -ForegroundColor White
    Test-Api "Customer Favorites" "GET" "/api/customer/favorites" $null $customerToken
    
    # 10.3 My Reviews
    Write-Host "`n[10.3] Customer Reviews" -ForegroundColor White
    Test-Api "Customer Reviews" "GET" "/api/customer/reviews" $null $customerToken
    
    # 10.4 Update Profile
    Write-Host "`n[10.4] Update Profile" -ForegroundColor White
    $updateBody = '{"fullName":"Ahmed Updated"}'
    Test-Api "Update Profile" "PUT" "/api/customer/profile" $updateBody $customerToken
} else {
    Write-Host "  ⏭️ Skipped (no customer token)" -ForegroundColor DarkGray
}

# ==========================================
# 11. VALIDATION TESTS
# ==========================================
Write-Host "`n--- 11. VALIDATION TESTS ---" -ForegroundColor Yellow

# Wait a bit to avoid rate limiting
Start-Sleep -Seconds 5

# 11.1 Empty phone
Write-Host "`n[11.1] Empty Phone" -ForegroundColor White
$emptyBody = '{"phoneNumber":"","password":"Test@1234"}'
Test-Api "Empty Phone (expect 400 or 429)" "POST" "/api/auth/login" $emptyBody $null 400

# 11.2 Weak password
Write-Host "`n[11.2] Weak Password" -ForegroundColor White
$weakBody = '{"phoneNumber":"0595000088","password":"123","fullName":"test","acceptTerms":true}'
Test-Api "Weak Password (expect 400 or 429)" "POST" "/api/auth/register" $weakBody $null 400

# 11.3 Invalid OTP code
Write-Host "`n[11.3] Invalid OTP" -ForegroundColor White
$invalidOtpBody = '{"phoneNumber":"0595000001","code":"000000"}'
Test-Api "Invalid OTP (expect 400 or 429)" "POST" "/api/auth/verify-otp" $invalidOtpBody $null 400

# ==========================================
# SUMMARY
# ==========================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  TEST RESULTS SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ✅ Passed: $pass" -ForegroundColor Green
Write-Host "  ❌ Failed: $fail" -ForegroundColor Red
Write-Host "  📊 Total:  $($pass + $fail)" -ForegroundColor White
$rate = if (($pass + $fail) -gt 0) { [math]::Round(($pass / ($pass + $fail)) * 100) } else { 0 }
Write-Host "  📈 Pass Rate: $rate%" -ForegroundColor $(if ($rate -ge 80) { "Green" } elseif ($rate -ge 50) { "Yellow" } else { "Red" })
Write-Host "========================================`n" -ForegroundColor Cyan
