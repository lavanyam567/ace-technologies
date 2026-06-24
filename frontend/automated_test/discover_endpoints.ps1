param(
  [string]$BaseUrl = "https://bjjvvqlztmfjskxsykmz.supabase.co",
  [string]$AnonKey = "sb_publishable_SnFXOvSnXEqQ_3cLPVX0lw_4zqjwyyf"
)

$ErrorActionPreference = "Stop"

$base = $BaseUrl.TrimEnd("/")
$headers = @{
  "apikey" = $AnonKey
  "Authorization" = "Bearer $AnonKey"
}

$knownEndpoints = @(
  @{ method = "GET"; path = "/rest/v1/products?select=id&is_active=eq.true"; access = "public read expected" },
  @{ method = "GET"; path = "/rest/v1/services?select=id&is_active=eq.true"; access = "public read expected" },
  @{ method = "GET"; path = "/rest/v1/reviews?select=id,product_id,rating,comment,created_at"; access = "public read expected" },
  @{ method = "GET"; path = "/rest/v1/profiles?select=id,full_name,phone,avatar_url,role"; access = "requires-auth / owner or admin expected" },
  @{ method = "GET"; path = "/rest/v1/orders?select=id,created_at,total_amount,status,address_id,payment_method,tracking_number"; access = "requires-auth / owner, admin broader access expected" },
  @{ method = "GET"; path = "/rest/v1/order_items?select=id,order_id,product_id,quantity,price"; access = "requires-auth / order owner or admin expected" },
  @{ method = "GET"; path = "/rest/v1/cart_items?select=id,product_id,quantity"; access = "requires-auth / owner expected" },
  @{ method = "GET"; path = "/rest/v1/wishlist_items?select=product_id"; access = "requires-auth / owner expected" },
  @{ method = "GET"; path = "/rest/v1/recently_viewed_products?select=product_id,viewed_at"; access = "requires-auth / owner expected" },
  @{ method = "GET"; path = "/rest/v1/compare_items?select=product_id"; access = "requires-auth / owner expected" },
  @{ method = "GET"; path = "/rest/v1/addresses?select=id,name,phone,city,state,pincode"; access = "requires-auth / owner expected" },
  @{ method = "GET"; path = "/rest/v1/service_bookings?select=id,user_id,service_id,address_id,status,total_price,created_at"; access = "requires-auth / owner or admin expected" },
  @{ method = "POST"; path = "/rest/v1/rpc/is_admin"; access = "requires-auth expected" },
  @{ method = "POST"; path = "/rest/v1/rpc/create_order_with_items"; access = "requires-auth expected; write path, do not probe without confirmation" },
  @{ method = "POST"; path = "/rest/v1/rpc/update_admin_order_status"; access = "admin-only expected; write path, do not probe without confirmation" },
  @{ method = "POST"; path = "/functions/v1/create-razorpay-order"; access = "requires-auth expected; safe malformed-body probe only after confirmation" },
  @{ method = "POST"; path = "/functions/v1/verify-razorpay-payment"; access = "requires-auth expected; safe malformed-body probe only after confirmation" },
  @{ method = "POST"; path = "/functions/v1/razorpay-webhook"; access = "signature-protected webhook expected; safe malformed-body probe only after confirmation" }
)

$specCandidates = @(
  "/rest/v1/",
  "/swagger.json",
  "/v3/api-docs",
  "/functions/v1/"
)

New-Item -ItemType Directory -Force -Path "automated_test" | Out-Null

$discovery = [ordered]@{
  baseUrl = $base
  generatedAt = (Get-Date).ToUniversalTime().ToString("o")
  specProbeResults = @()
  endpoints = $knownEndpoints
}

foreach ($path in $specCandidates) {
  $url = "$base$path"
  $result = [ordered]@{ url = $url; reachable = $false; status = $null; note = "" }
  try {
    $response = Invoke-WebRequest -Uri $url -Method GET -Headers $headers -TimeoutSec 10
    $result.reachable = $true
    $result.status = [int]$response.StatusCode
    $contentType = $response.Headers["Content-Type"] -join ","
    $result.note = "content-type=$contentType length=$($response.RawContentLength)"
  } catch {
    $response = $_.Exception.Response
    if ($response -ne $null) {
      $result.reachable = $true
      $result.status = [int]$response.StatusCode
      $result.note = $_.Exception.Message
    } else {
      $result.note = $_.Exception.Message
    }
  }
  $discovery.specProbeResults += $result
}

$json = $discovery | ConvertTo-Json -Depth 6
Set-Content -Path "automated_test\discovered_endpoints.json" -Value $json -Encoding UTF8

Write-Host "BASE_URL: $base"
Write-Host "Discovered endpoint count: $($knownEndpoints.Count)"
Write-Host ""
foreach ($endpoint in $knownEndpoints) {
  Write-Host ("{0,-6} {1} [{2}]" -f $endpoint.method, $endpoint.path, $endpoint.access)
}
Write-Host ""
Write-Host "Spec probe results:"
foreach ($probe in $discovery.specProbeResults) {
  Write-Host ("{0} status={1} reachable={2} {3}" -f $probe.url, $probe.status, $probe.reachable, $probe.note)
}
Write-Host ""
Write-Host "Saved: automated_test\discovered_endpoints.json"
