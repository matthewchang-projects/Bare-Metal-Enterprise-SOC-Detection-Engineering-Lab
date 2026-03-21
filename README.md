# Bare-Metal Enterprise SOC & Detection Engineering Lab
 
A fully segmented, enterprise-grade Security Operations Center built on bare-metal Proxmox VE. Designed to simulate real-world adversary activity, generate authentic endpoint and network telemetry, and develop custom detection logic mapped to MITRE ATT&CK.
 
---
 
## Hardware
 
| Component | Spec |
|---|---|
| CPU | AMD Threadripper 7960X (24c / 48t) |
| RAM | 128 GB |
| Storage | 2TB Samsung 990 Pro NVMe (Gen4) |
| Hypervisor | Proxmox VE |
| GPU | NVIDIA RTX 5060 8GB (passthrough to SIEM VM) |
 
---
 
##  Network Architecture
 
```



```
 
> All inter-VLAN traffic routes through OPNsense. Every simulated attack from the attacker network passes through Suricata before reaching corporate workstations, generating both network and endpoint telemetry simultaneously.
 
---
 
## VM Inventory
 
| VM | OS | Network | Role |
|---|---|---|---|
| SIEM-01 | Windows 11 + Splunk | vmbr0 | SOC Console, SIEM, SOAR, GPU |
| DC01 | Windows Server 2022 | vmbr1 | Active Directory, DNS, DHCP |
| WS01–WS07 | Windows 11 Pro | vmbr2 | Employee Bots, Sysmon, UF |
| WEC-01 | Windows Server 2022 | vmbr2 | Windows Event Collector |
| FW01 | OPNsense | vmbr0–4 | Firewall, IDS/IPS, Routing |
| ZEEK-01 | Ubuntu | vmbr3 | Dedicated Network Sensor |
| HONEYPOT-01 | Linux | vmbr3 | Deception / Canary Systems |
| KALI-01 | Kali Linux | vmbr4 | Red Team / Adversary Sim |
| WIN-ATK | Windows 10 | vmbr4 | C2 Frameworks, Exploitation |
 
---
 
## Detection Stack
 
| Layer | Tool | Purpose |
|---|---|---|
| Endpoint | Sysmon (SwiftOnSecurity config) | Process, network, file telemetry |
| Endpoint | Splunk Universal Forwarder | Log shipping to SIEM |
| Network | Suricata (ET Open rules) | Signature-based IDS/IPS |
| Network | Zeek | Protocol analysis, flow logging |
| Network | ntopng | Traffic visualization |
| Identity | Windows Event Forwarding | Auth, logon, AD activity |
| Deception | Honeypots + Canary tokens | Zero false-positive tripwires |
| SIEM | Splunk Enterprise | Correlation, detection, dashboards |
| SOAR | Shuffle | Automated response playbooks |
 
---
 
## Detection Engineering
 
Custom SPL detection rules mapped to MITRE ATT&CK, documented with:
- Detection hypothesis
- Required telemetry sources
- True/false positive analysis
- Coverage gaps and blind spots
 
**Techniques targeted:**
 
- `T1558.003` — Kerberoasting
- `T1550.002` — Pass-the-Hash
- `T1003.001` — LSASS Memory Dump
- `T1059.001` — PowerShell Execution
- `T1071` — C2 Beacon Traffic
- `T1021.001` — Lateral Movement via RDP
- `T1078` — Valid Accounts / Credential Abuse
 
---
 
## Adversary Simulation
 
The attacker network (`vmbr4`) runs controlled attack scenarios using:
- **Kali Linux** — Enumeration, exploitation, credential attacks
- **C2 Frameworks** — Beacon simulation, implant communication
- **Atomic Red Team** — Mapped ATT&CK technique execution
 
All attack traffic routes through OPNsense/Suricata, producing correlated network + endpoint evidence in Splunk.
 
---
 
## Repository Structure
 
```
/
├── infrastructure/        # Proxmox configs, network setup, VM specs
├── active-directory/      # AD build scripts, OU structure, GPOs
├── detection-rules/       # Custom Splunk SPL queries + Sigma rules
├── soar-playbooks/        # Shuffle automation workflows
├── attack-scenarios/      # End-to-end scenario writeups
│   ├── kerberoasting/
│   ├── pass-the-hash/
│   └── c2-beacon/
├── mitre-coverage/        # ATT&CK coverage matrix
└── docs/                  # Architecture diagrams, runbooks
```
 
---
 
## Intentional Security Decisions
 
This lab is built for **detection**, not prevention. Firewall rules are intentionally permissive between internal segments to maximize attack surface and generate realistic telemetry. Vulnerable AD configurations (Kerberoastable SPNs, over-privileged service accounts) are deliberate detection targets.
 
> This is a closed, isolated lab environment with no connection to production systems.
 
---
 
*Built as a detection engineering research environment. See `/attack-scenarios` for documented end-to-end attack chains with telemetry, detection logic, and SOAR response.*
