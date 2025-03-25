# AllDomains-PasswordsNeverExpire
This Powershell script is meant to track an Entra tenants list of custom domains and set each domain to have the password expiration policy never expire. This utilizes the MgGraph module and will download the appropriate dependencies if not already downloaded.

Running the script will require the following:

-PowerShell 5.1 or higher
-Administrative access to your Microsoft 365 tenant
-The ability to grant "Directory.ReadWrite.All" permission
