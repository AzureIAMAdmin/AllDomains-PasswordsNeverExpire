# Script to set "Password Never Expires" for all users in verified domains
# Requires Microsoft Graph PowerShell module

# Check if MgGraph module is installed and import it
if (-not (Get-Module -Name Microsoft.Graph -ListAvailable)) {
    Write-Host "Microsoft Graph PowerShell module is not installed. Installing..."
    Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force
}

# Import the Microsoft Graph module
Import-Module Microsoft.Graph

# Connect to Microsoft Graph with appropriate permissions
# This requires Directory.ReadWrite.All permission
Connect-MgGraph -Scopes "Directory.ReadWrite.All"

# Get all verified domains in the tenant
$verifiedDomains = Get-MgDomain | Where-Object { $_.IsVerified -eq $true }

if ($verifiedDomains.Count -eq 0) {
    Write-Host "No verified domains found."
    exit
}

Write-Host "Found $($verifiedDomains.Count) verified domains:"
$verifiedDomains | ForEach-Object { Write-Host "- $($_.Id)" }

# Confirm before proceeding
$confirmation = Read-Host "Do you want to set passwords to never expire for all users in these domains? (y/n)"
if ($confirmation -ne 'y') {
    Write-Host "Operation cancelled."
    exit
}

# Track statistics
$totalUsers = 0
$updatedUsers = 0
$errorUsers = 0

# Process each verified domain
foreach ($domain in $verifiedDomains) {
    Write-Host "`nProcessing domain: $($domain.Id)"
    
    # Get all users in this domain
    # When using endsWith operator, we need to specify ConsistencyLevel header as 'eventual' and include $count=true
    $domainFilter = "endsWith(userPrincipalName, '@$($domain.Id)')"
    $users = Get-MgUser -Filter $domainFilter -ConsistencyLevel "eventual" -CountVariable totalCount -All
    
    Write-Host "Found $($users.Count) users in domain $($domain.Id)"
    $totalUsers += $users.Count
    
    # Update each user to set password never expires
    foreach ($user in $users) {
        try {
            Write-Host "Attempting to update user: $($user.UserPrincipalName)" -ForegroundColor Yellow
            
            # Update the user's password policy
            Update-MgUser -UserId $user.Id -PasswordPolicies "DisablePasswordExpiration"
            
            Write-Host "Successfully updated user: $($user.UserPrincipalName)" -ForegroundColor Green
            $updatedUsers++
        }
        catch {
            Write-Host "Failed to update user: $($user.UserPrincipalName)" -ForegroundColor Red
            Write-Host "Error details: $_" -ForegroundColor Red
            $errorUsers++
        }
    }
}

# Display summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Total domains processed: $($verifiedDomains.Count)"
Write-Host "Total users found: $totalUsers"
Write-Host "Successfully updated users: $updatedUsers" -ForegroundColor Green
Write-Host "Failed to update users: $errorUsers" -ForegroundColor Red

# Disconnect from Microsoft Graph
Disconnect-MgGraph