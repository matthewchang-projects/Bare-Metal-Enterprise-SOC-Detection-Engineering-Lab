# Docs

Architecture reference and design decisions for the lab.

## Network Architecture

The full network diagram is in the main [README](../README.md). Key design principles are documented below.

### Why OPNsense is the Only Router

The Proxmox host holds an IP only on vmbr0 (the management bridge). Bridges vmbr1 through vmbr4 have no host IPs. All inter-VLAN routing runs exclusively through FW01 (OPNsense), which has one VirtIO NIC on every bridge.

This mirrors real enterprise design. If the Proxmox host had IPs on every bridge, a workstation compromise could pivot directly to the hypervisor. With OPNsense as the sole routing point, every cross-segment packet is subject to firewall policy and Suricata inspection regardless of which segment the attack originates from.

### Why the SIEM Has a Dedicated Management Link

SIEM-01 has two interfaces: vmbr0 (192.168.3.106) for management access and vmbr5 (10.0.0.10) for log ingestion. All Universal Forwarders and WEC-01 send logs to 10.0.0.10:9997.

Without vmbr5, log forwarding from workstations would have to traverse the corporate network (vmbr2), which would require loosening the LAN firewall rules. By adding a dedicated management bridge, log traffic is completely separated from production segments and firewall policy on those segments does not need to accommodate forwarder traffic.

### Why the WEF Architecture Has a Strict Setup Order

Windows Event Forwarding subscriptions fail silently if the sequence is wrong. The correct order is:

1. WEC-01 is built and joined to the domain
2. The Windows Event Collector service is running on WEC-01
3. OPNsense LAN rule for port 5985 to WEC-01 is in place
4. The WEF GPO is pushed from DC01
5. Workstations join the domain and receive the GPO

If the GPO reaches workstations before WEC-01 is ready to accept subscriptions, the workstations attempt registration and receive no response. They will retry eventually, but the initial failure introduces gaps in log coverage that are not obvious until you check the subscription status on WEC-01.

### Why CorpBot Runs Before Any Attack Simulation

Detection rules validated against a silent baseline are not meaningful. If the only events on a workstation are an attacker's Kerberoasting query, every detection threshold is trivially low and every rule fires on the first event.

CorpBot was built to run continuously from the moment workstations joined the domain. By the time any attack simulation runs, each workstation has thousands of events across Sysmon, Security, and PowerShell channels. Detection rules are tuned against this volume, which is what determines whether a rule produces actionable signal or alert fatigue.

### Firewall Traffic Matrix

| Source | Reaches | Blocked From |
|---|---|---|
| LAN (Workstations) | DC (OPT2), SIEM (OPT1), WEC-01:5985 | Attacker, DMZ, Internet |
| OPT2 (DC) | LAN, SIEM (OPT1) | Attacker, DMZ, Internet |
| OPT3 (DMZ) | SIEM (OPT1) log path only | Everything else |
| WAN (Attacker) | LAN workstations, DMZ honeypot | DC, SIEM, Management |
| OPT1 (SIEM) | DC, LAN, DMZ, OPNsense GUI | Attacker network |

### Suricata Placement

Suricata runs on the LAN and WAN interfaces of OPNsense. This means it inspects traffic in both directions across the attack path. An outbound scan from KALI-01 hits the WAN interface. The response from a workstation hits the LAN interface. Both generate alerts that appear in the `suricata` index in Splunk with matching flow IDs, enabling full bidirectional attack chain reconstruction from network telemetry alone.
