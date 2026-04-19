# create-users.ps1
# Creates 15 domain user accounts across 5 departments in corp.local
# Run on DC01 as CORP\Administrator after create-ous.ps1 completes

$domain   = "DC=corp,DC=local"
$password = ConvertTo-SecureString "<USER-PASSWORD>" -AsPlainText -Force

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
        -Name                 $user.Name `
        -SamAccountName       $user.SamAccount `
        -UserPrincipalName    "$($user.SamAccount)@corp.local" `
        -Path                 "OU=$($user.Dept),OU=Corp,$domain" `
        -AccountPassword      $password `
        -Enabled              $true `
        -Title                $user.Title `
        -Department           $user.Dept `
        -PasswordNeverExpires $true
}

Write-Host "15 users created successfully"
Get-ADUser -Filter * -SearchBase "OU=Corp,$domain" | Select-Object Name, SamAccountName, Department | Sort-Object Department | Format-Table -AutoSize
