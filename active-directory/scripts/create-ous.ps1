# create-ous.ps1
# Creates the Corp OU hierarchy in corp.local
# Run on DC01 as CORP\Administrator after domain promotion

$domain = "DC=corp,DC=local"

# Top-level Corp OU
New-ADOrganizationalUnit -Name "Corp" -Path $domain

# Department OUs under Corp
$depts = @("IT","HR","Finance","Engineering","Sales")
foreach ($dept in $depts) {
    New-ADOrganizationalUnit -Name $dept -Path "OU=Corp,$domain"
}

# Computer object OUs
New-ADOrganizationalUnit -Name "Workstations" -Path "OU=Corp,$domain"
New-ADOrganizationalUnit -Name "Servers"      -Path "OU=Corp,$domain"

# Verify
Write-Host "OU structure created:"
Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName | Format-Table -AutoSize
