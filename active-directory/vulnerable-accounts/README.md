# Vulnerable Accounts

These accounts are intentional misconfigurations, not oversights. Each one maps directly to a MITRE ATT&CK technique and serves as a detection target. A clean, hardened AD produces no meaningful telemetry for credential attacks. These accounts create the attack surface that makes detection engineering possible.

## svc_sql - Kerberoasting Target (T1558.003)

`svc_sql` is a service account with a weak password and a registered Service Principal Name (SPN). Any domain user can request a Kerberos service ticket for an SPN without elevated privileges. That ticket is encrypted with the account password hash and can be cracked offline. This is Kerberoasting.

```powershell
# Create the service account with a weak password
New-ADUser `
    -Name "SQL Service Account" `
    -SamAccountName "svc_sql" `
    -AccountPassword (ConvertTo-SecureString "<SVC-SQL-PASSWORD>" -AsPlainText -Force) `
    -Enabled $true `
    -PasswordNeverExpires $true `
    -Path "OU=Servers,OU=Corp,DC=corp,DC=local"

# Register the SPN - this is what makes the account Kerberoastable
setspn -A MSSQLSvc/sqlserver.corp.local:1433 CORP\svc_sql
```

**ATT&CK Technique:** T1558.003 - Steal or Forge Kerberos Tickets: Kerberoasting
**Detection signal:** Event ID 4769 (Kerberos Service Ticket Request) with encryption type 0x17 (RC4-HMAC), logged to DC01 Security event log and forwarded to Splunk via WEF.

## svc_backup - Lateral Movement Target (T1078, T1003)

`svc_backup` is a service account that was added to Domain Admins. Over-privileged service accounts are extremely common in real environments and represent one of the highest-value lateral movement paths. If an attacker compromises any host running a process as this account, they have immediate domain admin access.

```powershell
# Create the backup service account
New-ADUser `
    -Name "Backup Service" `
    -SamAccountName "svc_backup" `
    -AccountPassword (ConvertTo-SecureString "<SVC-BACKUP-PASSWORD>" -AsPlainText -Force) `
    -Enabled $true `
    -PasswordNeverExpires $true `
    -Path "OU=Servers,OU=Corp,DC=corp,DC=local"

# Add to Domain Admins - this is the deliberate misconfiguration
Add-ADGroupMember -Identity "Domain Admins" -Members "svc_backup"
```

**ATT&CK Techniques:** T1078 (Valid Accounts), T1003.001 (LSASS Memory Dump - if credentials are extracted from memory on a host where svc_backup is cached)
**Detection signal:** Any process access to LSASS with access rights 0x1010 or 0x1410, logged by Sysmon Event ID 10 on the workstations.

## Weak Password Policy

The domain password policy is intentionally permissive. `PasswordNeverExpires` is set on all accounts and the minimum password length is not enforced to enterprise standards. This allows the weak service account passwords to exist without policy rejection.

> These misconfigurations replicate what is found in a significant percentage of real enterprise Active Directory environments. The goal is not to simulate a poorly run environment but to create realistic, documentable detection targets with known ground truth.
