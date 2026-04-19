# Active Directory

DC01 is the identity backbone of the lab. Everything downstream depends on it: workstations cannot join the domain without it, Group Policy cannot push WEF configuration without it, and the detection targets (Kerberoasting, Pass-the-Hash, DCSync) only exist because of the deliberate misconfigurations built into it.

## Contents

- [DC01 Build](./dc01-build/) - VM creation, OS install, domain promotion, DNS, DHCP
- [OU Structure](./ou-structure/) - Organizational unit layout and user accounts
- [Vulnerable Accounts](./vulnerable-accounts/) - Intentionally misconfigured accounts for detection targets
- [GPO and WEF](./gpo-wef/) - Group Policy configuration, NTP enforcement, Windows Event Forwarding
- [Scripts](./scripts/) - PowerShell scripts used to build the AD environment

## Domain Summary

| Setting | Value |
|---|---|
| Domain | corp.local |
| NetBIOS | CORP |
| Forest / Domain Mode | WinThreshold (2016) |
| DC01 IP | 192.168.10.10 |
| DNS | Integrated with AD, DC01 is authoritative |
| DHCP scope | 192.168.20.20 - 192.168.20.100 (vmbr2) |

## User Summary

| Department | Users |
|---|---|
| IT | jsmith, dmartinez, kjackson, dthompson |
| HR | sjohnson, jbrown |
| Finance | mdavis, ataylor, lwhite |
| Engineering | echen, canderson, jharris |
| Sales | rwilson, mthomas, nmartin |
| Service Accounts | svc_sql (Kerberoastable), svc_backup (Domain Admin) |
