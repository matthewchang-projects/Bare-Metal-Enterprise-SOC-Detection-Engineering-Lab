# configure-vulnerable-accounts.ps1
# Creates intentionally misconfigured service accounts as detection targets.
# These accounts are deliberate. Each maps to a specific ATT&CK technique.
#
# svc_sql  - Kerberoasting target  (T1558.003)
# svc_backup - Over-privileged DA  (T1078, T1003.001)
#
# Run on DC01 as CORP\Administrator after create-ous.ps1 completes.

$domain = "DC=corp,DC=local"

# --- svc_sql: Kerberoasting target ---
# Weak password + SPN registration = any domain user can request a service ticket
# and attempt to crack the RC4-encrypted hash offline.

New-ADUser `
    -Name                 "SQL Service Account" `
    -SamAccountName       "svc_sql" `
    -AccountPassword      (ConvertTo-SecureString "<SVC-SQL-PASSWORD>" -AsPlainText -Force) `
    -Enabled              $true `
    -PasswordNeverExpires $true `
    -Path                 "OU=Servers,OU=Corp,$domain"

# Register the SPN - this is what makes the account Kerberoastable
setspn -A MSSQLSvc/sqlserver.corp.local:1433 CORP\svc_sql

# Verify SPN registration
Write-Host "SPN registered for svc_sql:"
setspn -L svc_sql


# --- svc_backup: Over-privileged service account ---
# Domain Admin membership on a service account is a critical misconfiguration.
# If the account is cracked or a host running it is compromised, full DA access follows.

New-ADUser `
    -Name                 "Backup Service" `
    -SamAccountName       "svc_backup" `
    -AccountPassword      (ConvertTo-SecureString "<SVC-BACKUP-PASSWORD>" -AsPlainText -Force) `
    -Enabled              $true `
    -PasswordNeverExpires $true `
    -Path                 "OU=Servers,OU=Corp,$domain"

Add-ADGroupMember -Identity "Domain Admins" -Members "svc_backup"

Write-Host "Vulnerable accounts created."
Write-Host "svc_sql  -> Kerberoastable (T1558.003) - detect via Event ID 4769, enc type 0x17"
Write-Host "svc_backup -> Domain Admin (T1078)     - detect via 4728 group membership change"
