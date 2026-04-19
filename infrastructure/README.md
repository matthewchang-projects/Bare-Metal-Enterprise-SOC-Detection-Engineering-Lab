# Infrastructure

This section documents the full physical and virtual infrastructure build for the SOC lab. Every component is documented in build order, from Proxmox bridge configuration through final connectivity verification. Each subsection includes the exact commands used and screenshots as evidence.

## Build Order

The lab was built in the following sequence. Each dependency must be completed before the next phase begins.

1. [Proxmox Host](./proxmox-host/) - Bridge configuration and VM creation
2. [FW01 (OPNsense)](./fw01-opnsense/) - Firewall, routing, IDS/IPS, traffic monitoring
3. [SIEM-01](./siem-01/) - Splunk Enterprise, index creation, log ingestion
4. [WEC-01](./wec-01/) - Windows Event Collector, WEF subscription
5. [Workstations (WS01-WS06)](./workstations/) - Domain join, Sysmon, UF, CorpBot
6. [Attacker VMs (KALI-01, WIN-ATK)](./attacker-vms/) - Red team network configuration
7. [Honeypot and DMZ (HONEY01, ZEEK-01)](./honeypot-dmz/) - Deception layer, network sensor
8. [Network Audit](./network-audit/) - Final end-to-end connectivity and telemetry verification

## VM Inventory

| VM | OS | Bridge | IP | Role |
|---|---|---|---|---|
| SIEM-01 | Windows 11 + Splunk Enterprise | vmbr0 + vmbr5 | 192.168.3.106 / 10.0.0.10 | SOC console, SIEM, GPU passthrough |
| DC01 | Windows Server 2022 | vmbr1 | 192.168.10.10 | Active Directory, DNS, DHCP |
| WS01 | Windows 11 Pro | vmbr2 | 192.168.20.21 | Domain workstation |
| WS02 | Windows 11 Pro | vmbr2 | 192.168.20.22 | Domain workstation |
| WS03 | Windows 11 Pro | vmbr2 | 192.168.20.23 | Domain workstation |
| WS04 | Windows 11 Pro | vmbr2 | 192.168.20.24 | Domain workstation |
| WS05 | Windows 11 Pro | vmbr2 | 192.168.20.25 | Domain workstation |
| WS06 | Windows 11 Pro | vmbr2 | 192.168.20.26 | Domain workstation |
| WEC-01 | Windows Server 2022 | vmbr2 | 192.168.20.10 | Windows Event Collector |
| FW01 | OPNsense 26.1.2 | vmbr0-vmbr4 + vmbr6 | See bridge map | Firewall, routing, Suricata, ntopng |
| ZEEK-01 | Ubuntu | vmbr3 | 192.168.30.10 | Network sensor |
| HONEY01 | Linux | vmbr3 | 192.168.30.130 | Cowrie SSH honeypot |
| KALI-01 | Kali Linux | vmbr4 | 192.168.40.10 | Red team / adversary simulation |
| WIN-ATK | Windows 10 | vmbr4 | 192.168.40.11 | C2 frameworks, exploitation |

## Network Bridge Summary

| Bridge | Subnet | Purpose |
|---|---|---|
| vmbr0 | 192.168.3.x | Management / Proxmox host / SIEM |
| vmbr1 | 192.168.10.0/24 | Domain Controller |
| vmbr2 | 192.168.20.0/24 | Corporate workstations, WEC-01 |
| vmbr3 | 192.168.30.0/24 | DMZ, honeypots, Zeek |
| vmbr4 | 192.168.40.0/24 | Attacker network |
| vmbr5 | 10.0.0.0/24 | SIEM management link (dedicated log forwarding) |
| vmbr6 | 192.168.3.x | OPNsense internet access for updates only |

> The Proxmox host holds an IP only on vmbr0. vmbr1 through vmbr4 have no host IPs. All inter-VLAN routing is handled by FW01 (OPNsense), which is the only VM with interfaces on every bridge.
