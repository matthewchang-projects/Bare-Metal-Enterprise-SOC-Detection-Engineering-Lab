# Bare-Metal Enterprise SOC & Detection Engineering Lab

Security Operations Centers are increasingly limited not by a lack of data, but by an inability to effectively transform high-volume telemetry into reliable detections. This lab investigates detection engineering as a systematic approach to improving signal fidelity by designing and deploying a bare-metal, enterprise-scale SOC lab. The environment replicates real-world infrastructure, including network segmentation, endpoint activity, and adversary simulation, to enable end-to-end validation of detection logic. The primary objective is to bridge the gap between raw log ingestion and actionable security insights through iterative detection development, testing, and tuning. This lab reflects a focus on building reproducible, high-confidence detection pipelines aligned with modern SOC practices.

---

## Hardware

| Component | Spec |
|---|---|
| CPU | AMD Threadripper 7960X (24c / 48t) |
| RAM | 128 GB |
| Storage | 2TB Samsung 990 Pro NVMe (Gen4) |
| Hypervisor | Proxmox VE |
| NIC0 | Primary ethernet → vmbr0 (home / management network) |
| NIC1 | Secondary ethernet → vmbr6 (OPNsense internet updates only) |
| GPU | NVIDIA RTX 5060 8GB (passthrough to SIEM VM) |

---

## Network Architecture

![network-diagram (1)](https://github.com/user-attachments/assets/86e2243f-fbe3-4654-8b35-febe8662c3d1)

> All inter-VLAN traffic routes through OPNsense. Every simulated attack from the attacker network passes through Suricata before reaching corporate workstations, generating both network and endpoint telemetry simultaneously.

### Bridge & Subnet Map

| Bridge | Purpose | Subnet | OPNsense Interface | OPNsense IP |
|---|---|---|---|---|
| vmbr0 | Home / Management | 192.168.3.x | OPT4 (vtnet5) | 192.168.3.2 |
| vmbr1 | Domain Controller | 192.168.10.0/24 | OPT2 (vtnet1) | 192.168.10.1 |
| vmbr2 | Corporate Workstations | 192.168.20.0/24 | LAN (vtnet2) | 192.168.20.1 |
| vmbr3 | DMZ / Honeypots | 192.168.30.0/24 | OPT3 (vtnet3) | 192.168.30.1 |
| vmbr4 | Attacker Network | 192.168.40.0/24 | WAN (vtnet4) | 192.168.40.1 |
| vmbr5 | SIEM Management Link | 10.0.0.0/24 | OPT1 (vtnet0) | 10.0.0.1 |
| vmbr6 | OPNsense Internet Updates | 192.168.3.x | via NIC1 | 192.168.3.2 |

### Firewall Traffic Matrix

| Source | Can Reach | Cannot Reach |
|---|---|---|
| LAN (Workstations) | DC (OPT2), SIEM (OPT1) | Attacker, DMZ, Internet |
| OPT2 (DC) | LAN, SIEM (OPT1) | Attacker, DMZ, Internet |
| OPT3 (DMZ / Honeypot) | SIEM (OPT1) log forwarding only | Everything else |
| WAN (Attacker) | LAN (workstations), DMZ (honeypot) | DC, SIEM, Internet |
| OPT1 (SIEM) | DC, LAN, DMZ, OPNsense GUI | Attacker network |

---

## VM Inventory

| VM | OS | vmbr | IP | Role |
|---|---|---|---|---|
| SIEM-01 | Windows 11 + Splunk Enterprise | vmbr0 + vmbr5 | 192.168.3.106 / 10.0.0.10 | SOC console, SIEM, SOAR, GPU passthrough |
| DC01 | Windows Server 2022 | vmbr1 | 192.168.10.10 | Active Directory, DNS, DHCP, GPO |
| WS01–WS06 | Windows 11 Pro | vmbr2 | 192.168.20.20–.25 | Domain workstations, Sysmon, UF, CorpBot |
| WEC-01 | Windows Server 2022 | vmbr2 | 192.168.20.10 | Windows Event Collector |
| FW01 | OPNsense | vmbr0–6 | (see above) | Firewall, IDS/IPS, routing, ntopng |
| ZEEK-01 | Ubuntu | vmbr2 | 192.168.20.15 | Dedicated network sensor |
| HONEY01 | Linux | vmbr3 | 192.168.30.50 | Cowrie SSH honeypot, honey files, canary tokens |
| KALI-01 | Kali Linux | vmbr4 | 192.168.40.10 | Red team / adversary simulation |
| WIN-ATK | Windows 10 | vmbr4 | 192.168.40.11 | C2 frameworks, exploitation |

---

## Detection Stack

| Layer | Tool | Purpose |
|---|---|---|
| Endpoint | Sysmon (SwiftOnSecurity config) | Process, network, file telemetry |
| Endpoint | Splunk Universal Forwarder | Log shipping to SIEM |
| Endpoint | CorpBot (PowerShell) | Realistic baseline user activity across WS01–WS06 |
| Network | Suricata (ET Open rules) | Signature-based IDS/IPS |
| Network | Zeek | Protocol analysis, flow logging |
| Network | ntopng | Traffic visualization |
| Identity | Windows Event Forwarding | Auth, logon, AD activity centralized via WEC-01 |
| Deception | Cowrie + canary tokens + honey files | Zero false-positive tripwires |
| SIEM | Splunk Enterprise (6 indexes) | Correlation, detection, dashboards |
| SOAR | Shuffle | Automated response playbooks |

---

## Detection Engineering

Custom SPL detection rules mapped to MITRE ATT&CK, each documented with:

- Detection hypothesis
- Required telemetry sources
- True / false positive analysis
- Coverage gaps and blind spots

**Techniques targeted:**

- `T1558.003` - Kerberoasting
- `T1550.002` - Pass-the-Hash
- `T1003.001` - LSASS Memory Dump
- `T1059.001` - PowerShell Execution
- `T1071` - C2 Beacon Traffic
- `T1021.001` - Lateral Movement via RDP
- `T1078` - Valid Accounts / Credential Abuse

See [`/detection-rules`](/detection-rules) for full SPL queries and [`/mitre-coverage`](/mitre-coverage) for the ATT&CK coverage matrix including gap analysis.

---

## Adversary Simulation

The attacker network (`vmbr4`) runs controlled attack scenarios using:

- **Kali Linux** - Enumeration, exploitation, credential attacks
- **C2 Frameworks** - Beacon simulation, implant communication
- **Atomic Red Team** - Mapped ATT&CK technique execution

All attack traffic routes through OPNsense/Suricata, producing correlated network + endpoint evidence in Splunk. See [`/attack-scenarios`](/attack-scenarios) for end-to-end documented attack chains with telemetry, detection logic, and SOAR response.

---

## Lessons Learned

Building a production-grade detection engineering environment from bare metal surfaced several non-obvious engineering problems that vendor documentation and tutorials consistently underrepresent.

**False positive volume at initial deployment is much higher than expected.** When Sysmon, WEF, Suricata, and Zeek were brought online simultaneously, the volume of alerts that did not represent real threats was high enough to undermine confidence in the entire pipeline. Detection engineering is not just rule-writing, it is a sustained process of establishing behavioral baselines first, then layering detections on top of that baseline. Deploying detection logic before baselines are stable produces noise, not signal.

**Network time synchronization is a hard dependency, not an afterthought.** Timestamp mismatches across VMs caused correlated alerts to appear out of sequence in Splunk, making attack chain reconstruction unreliable. NTP enforcement via GPO across all domain-joined VMs must be validated before any detection work begins. A detection pipeline built on unsynchronized clocks is not a detection pipeline.

**The WEC/WEF architecture requires strict operational sequencing.** Windows Event Forwarding subscriptions silently fail if the collector service is not running before workstations attempt to register. WEC-01 must be fully configured before the WEF GPO is pushed, and OPNsense firewall rules must permit event log traffic on port 5985 before testing. Each dependency is invisible until it fails.

**Segmentation that is too strict blocks legitimate telemetry paths.** Several log forwarding pipelines were silently dropping events because OPNsense rules were correctly blocking traffic from a security standpoint but incorrectly from a monitoring standpoint. The dedicated SIEM management link (vmbr5, 10.0.0.x) was added specifically to decouple log forwarding from production network segments without loosening security boundaries.

**Realistic baseline traffic is essential before running attack simulations.** Running attack scenarios against workstations with no prior activity produces trivially detectable anomalies. The CorpBot framework was built to generate realistic application, authentication, and network events across WS01–WS06 so that detections are validated against a realistic signal-to-noise environment rather than an artificially quiet one.

**Detection tuning is iterative, not one-time.** Initial Suricata ET Open rules generated significant alert volume from legitimate lab management traffic that superficially resembled scanning behavior. The tuning process, suppression rules, threshold adjustments, correlation logic refinement, required more time than anticipated and represents a realistic approximation of what production SOC teams manage continuously.

---

## Repository Structure

```
/
├── infrastructure/        # Proxmox configs, network setup, VM specs
├── active-directory/      # AD build scripts, OU structure, GPOs
└── docs/                  # Architecture diagrams, runbooks
```

---

## Intentional Security Decisions

This lab is built for **detection**, not prevention. Firewall rules are intentionally permissive between internal segments to maximize attack surface and generate realistic telemetry. Vulnerable AD configurations Kerberoastable SPNs, over-privileged service accounts, weak password policies are deliberate detection targets, not oversights.

> This is a closed, isolated lab environment. The attacker network has no path to the internet and no path to the SIEM. No production systems are connected.

---

*Built as a detection engineering research environment. See `/attack-scenarios` for documented end-to-end attack chains with telemetry, detection logic, and SOAR response.*
