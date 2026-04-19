# OU Structure and User Accounts

## Organizational Unit Layout

```
corp.local
└── Corp
    ├── IT
    ├── HR
    ├── Finance
    ├── Engineering
    ├── Sales
    ├── Workstations    (computer objects for WS01-WS06)
    └── Servers         (computer objects for WEC-01, service accounts)
```

## User Accounts

15 user accounts were created to simulate a real employee population across five departments. All accounts use the same base password with `PasswordNeverExpires` set, which is intentional. This generates realistic authentication telemetry and creates the credential attack surface that detection rules will target.

```powershell
$domain = "DC=corp,DC=local"
$password = ConvertTo-SecureString "Winter2024!" -AsPlainText -Force

$users = @(
    @{Name="John Smith";      SamAccount="jsmith";     Dept="IT";          Title="IT Administrator"},
    @{Name="Sarah Johnson";   SamAccount="sjohnson";   Dept="HR";          Title="HR Manager"},
    @{Name="Mike Davis";      SamAccount="mdavis";     Dept="Finance";     Title="Financial Analyst"},
    @{Name="Emily Chen";      SamAccount="echen";      Dept="Engineering"; Title="Software Engineer"},
    @{Name="Robert Wilson";   SamAccount="rwilson";    Dept="Sales";       Title="Sales Rep"},
    @{Name="Jessica Brown";   SamAccount="jbrown";     Dept="HR";          Title="HR Coordinator"},
    @{Name="David Martinez";  SamAccount="dmartinez";  Dept="IT";          Title="Sysadmin"},
    @{Name="Amanda Taylor";   SamAccount="ataylor";    Dept="Finance";     Title="Accountant"},
    @{Name="Chris Anderson";  SamAccount="canderson";  Dept="Engineering"; Title="DevOps Engineer"},
    @{Name="Michelle Thomas"; SamAccount="mthomas";    Dept="Sales";       Title="Account Executive"},
    @{Name="Kevin Jackson";   SamAccount="kjackson";   Dept="IT";          Title="Help Desk"},
    @{Name="Lauren White";    SamAccount="lwhite";     Dept="Finance";     Title="CFO"},
    @{Name="James Harris";    SamAccount="jharris";    Dept="Engineering"; Title="Security Engineer"},
    @{Name="Nicole Martin";   SamAccount="nmartin";    Dept="Sales";       Title="Sales Manager"},
    @{Name="Daniel Thompson"; SamAccount="dthompson";  Dept="IT";          Title="Network Admin"}
)

foreach ($user in $users) {
    New-ADUser `
        -Name $user.Name `
        -SamAccountName $user.SamAccount `
        -UserPrincipalName "$($user.SamAccount)@corp.local" `
        -Path "OU=$($user.Dept),OU=Corp,$domain" `
        -AccountPassword $password `
        -Enabled $true `
        -Title $user.Title `
        -Department $user.Dept `
        -PasswordNeverExpires $true
}
```

## User Table

| Name | Username | Department | Title |
|---|---|---|---|
| John Smith | jsmith | IT | IT Administrator |
| Sarah Johnson | sjohnson | HR | HR Manager |
| Mike Davis | mdavis | Finance | Financial Analyst |
| Emily Chen | echen | Engineering | Software Engineer |
| Robert Wilson | rwilson | Sales | Sales Rep |
| Jessica Brown | jbrown | HR | HR Coordinator |
| David Martinez | dmartinez | IT | Sysadmin |
| Amanda Taylor | ataylor | Finance | Accountant |
| Chris Anderson | canderson | Engineering | DevOps Engineer |
| Michelle Thomas | mthomas | Sales | Account Executive |
| Kevin Jackson | kjackson | IT | Help Desk |
| Lauren White | lwhite | Finance | CFO |
| James Harris | jharris | Engineering | Security Engineer |
| Nicole Martin | nmartin | Sales | Sales Manager |
| Daniel Thompson | dthompson | IT | Network Admin |

The user spread across departments ensures CorpBot can simulate realistic per-department activity patterns. The CFO account (lwhite) and IT Administrator account (jsmith) are high-value targets that will be referenced in detection scenarios.
