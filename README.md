# OGN VPS installer

Reusable **OpenMPTCProuter VPS 0.1046-rolling** installation bundle for fresh **OVH Debian 13 amd64 UEFI** instances. It installs **XanMod 6.12.67**, revision `0~20260123.ga077982`, and `omr-vps-admin 0.16+20251126`.

## Download and install on a new VPS

Log in to your new VPS on its initial SSH port. Run:

```sh
cd /home/debian
wget -4 https://raw.githubusercontent.com/sskola/ogn-vps/main/ogn-vps-0.1046-bundle.tar.gz
wget -4 https://raw.githubusercontent.com/sskola/ogn-vps/main/ogn-vps-0.1046-bundle.tar.gz.sha256
sha256sum -c ogn-vps-0.1046-bundle.tar.gz.sha256
tar -xzf ogn-vps-0.1046-bundle.tar.gz
cd ogn-vps-0.1046-bundle
sudo sh ./install.sh
```

The launcher checks the OS, architecture, privileges, IPv4 default route, connectivity and bundle hashes. It applies the three IPv6-disable sysctls before downloads, removes unattended-upgrades, performs Debian update/upgrade, and installs OMR from the bundled source/packages. It does not edit netplan automatically; multiple IPv4 default routes require operator correction before continuing.

SSH moves to **65222**. After successful installation, establish a new SSH connection on that port, then reboot:

```sh
sudo reboot
```

Reconnect on port 65222 and verify:

```sh
sudo sh /opt/ogn-vps/0.1046-rolling/verify-vps.sh
```

Keep the installer-generated API and tunnel credentials private.

## Contents and validation

- [Download the complete bundle](https://raw.githubusercontent.com/sskola/ogn-vps/main/ogn-vps-0.1046-bundle.tar.gz)
- [Browse the complete bundle](ogn-vps-0.1046-bundle/)
- [SHA-256 checksum](ogn-vps-0.1046-bundle.tar.gz.sha256)

The archive contains the full `ogn-vps-0.1046-bundle/` directory, including the launcher, derived installer, untouched upstream source, all pinned packages, reviewable patch, integrity manifest, detailed instructions and validation history.

Fresh disposable installation, SSH transition, reboot into XanMod 6.12.67, required services, authenticated admin API and local MPTCP negotiation/data checks passed on 2026-10-02. Paired-router provisioning, remote web forwarding, multi-WAN traffic/failover/throughput and extended stability remain unverified.

This is an **online-assisted bundle**: OMR assets and pinned packages are included; Debian dependencies/updates, public-IP discovery and the XanMod kernel download still use IPv4 internet access. No GRUB IPv6-disable parameter is added.

## Upstream

Derived from [Ysurac/openmptcprouter-vps](https://github.com/Ysurac/openmptcprouter-vps), tag `v0.1046-rolling`. An untouched copy is included under the bundle's `upstream/` directory. Included software retains its original licenses and notices; this repository is a packaging/customization of upstream components.
