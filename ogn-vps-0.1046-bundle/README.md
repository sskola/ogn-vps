# OGN VPS 0.1046-rolling online-assisted bundle

**Current policy (2026-10-02): the derived installer now pins XanMod 6.12.67, revision `0~20260123.ga077982`, matching upstream 0.1082's optional 6.12 path.** IPv6 preparation uses only the guide's three `sysctl.d` settings, applied with `sysctl --system` before downloads and OMR installation. No GRUB IPv6-disable parameter is added. The fresh disposable installation, reboot and server checks passed with 6.12.67; paired-router traffic and failover testing remain pending. See `docs/validation.txt` and `docs/kernel-6.12.67-validation.json`.

This bundle targets a **fresh OVH Debian 13 amd64 UEFI VPS**. It combines the user's VPS preparation steps with the upstream v0.1046-rolling installer and a local APT repository of its pinned OMR packages. Debian package updates, Debian dependencies, public-IP discovery, and the **XanMod 6.12.67 image/headers download** still require IPv4 internet access. This is not a fully offline installer.

## Before running

1. Confirm a recovery method is available: a snapshot or reinstall of the disposable VPS. VNC guest login requires a user password; this bundle does not set one. Check the public IPv4 reputation separately if required by your operations policy.
2. Confirm the correct SSH user and host key through the OVH console. Do not use the public key supplied for this project as a server host key.
3. Confirm the OVH private NIC does not create a second IPv4 default route. The launcher stops if more than one exists. Fix the correct private interface through the OVH console; it never edits netplan or applies network changes over SSH.
4. Transfer this whole directory to the VPS. Do not transfer only `install.sh`.

Run as root:

```sh
sh ./install.sh
```

The launcher verifies `manifest.sha256` before modifying the VPS. It writes the three guide settings to `/etc/sysctl.d/99-disable-ipv6.conf`, applies them with `sysctl --system`, confirms `all`, `default`, and `lo` are disabled before downloads, removes `unattended-upgrades`, runs Debian `apt-get update` and `apt-get upgrade -y` over IPv4, copies the verified bundle to `/opt/ogn-vps/0.1046-rolling`, then invokes the derived upstream installer with `LOCALFILES=yes`, `SOURCES=no`, and `KERNEL=6.12`. It preserves the upstream XanMod download and installation, then selects that kernel through its full GRUB menu path.

The installer changes SSH to port 65222, reloads SSH and waits up to nine seconds for the new listener before configuring Shorewall. Keep the OVH console available. Do not run this on a production VPS without a separate site-specific review.

After the upstream installer finishes, reboot the VPS, reconnect on SSH port 65222, and run:

```sh
sh /opt/ogn-vps/0.1046-rolling/verify-vps.sh
```

A completed installer is not proof that XanMod booted. `verify-vps.sh` checks the exact XanMod 6.12.67 release in `uname -r`, MPTCP, admin API, selected services, and the selected admin package. Post-boot IPv6 flags and address/route counts are informational; persistent IPv6 disablement after reboot is not a pass requirement under the selected preparation policy. If XanMod did not boot, stop and inspect GRUB through the console. The installer stops before completion if it cannot find the XanMod menu entry or regenerate GRUB configuration.

## What is preserved and what differs

- `upstream/` is an untouched copy of the downloaded Git tag. Its main script SHA-256 is `a16c45157bc3d88eb8a556e41b6c7afd4a767b02e1b6e4baf6f2b59411f00e92`.
- `payload/` is the derived installer. `ogn-0.1046.patch` shows its main-script changes: admin pin `0.16+20251126`, corrected `OMR_VERSION=0.1046-rolling`, a local APT repository branch, a guard for removing old iperf packages that are absent on a fresh Debian 13 VPS, an SSH reload/listener check before Shorewall, and a backport of upstream's submenu-aware GRUB selector. The kernel version/revision deliberately change from upstream 0.1046's 6.12.47 to 0.1082's 6.12.67. Download URL templates, CPU build selection, package installation commands and kernel parameters remain unchanged.
- `repo/` holds 13 exact-version `.deb` files, including the user's `omr-vps-admin_0.16+20251126_all.deb`. Debian supplies ordinary dependencies online. The repository also carries Debian Buster `libjson-c3` because the preserved 2021 `tracebox` package depends on that old soname; this is a compatibility package for the disposable test, not a production recommendation. The repo is persistent under `/opt/ogn-vps/0.1046-rolling/repo` after installation.
- The upstream script's final `omr-server=${OMR_VERSION}` install is nonfatal (`|| true`). No historical `omr-server_0.1046-rolling` package was available in the current official pool, and the tag's old `debian/control` still describes 2021 dependencies. The script itself installs the services; the missing metapackage is recorded here rather than silently replaced with `0.1082`.
- The guide's old `git`, `/etc/shadowsocks-libev` directory, and empty `manager.json` workaround is not applied. The 0.1046 script creates the directory and copies its bundled `manager.json` on fresh installation.
- The guide's `XRAY=no` and `BPFTUNE=no` example is for 0.1043. This bundle retains 0.1046's defaults; `BPFTUNE` is not read by this tagged script.

## Remaining network dependencies

The local repository removes dependence on finding the pinned OMR binary packages again. The install still uses Debian and historical Debian repositories for ordinary APT dependencies; the original XanMod package download is deliberately online. The upstream script also contacts OMR's public IP/hostname endpoints to discover this VPS's address, and contains direct-download branches for other architectures or source builds; those branches are not taken with this launcher. The local validation record is in `docs/validation.txt`. Package origin and hashes are in `docs/package-sources.tsv`. The full source-level network-call inventory is in `docs/upstream-network-calls.txt`; it includes branches not taken under this Debian 13 `SOURCES=no`, `LOCALFILES=yes` configuration.

Disposable VPS test results and remaining checks are recorded in `docs/validation.txt`. A full pass requires installation, reboot and the runtime checks below.

## Kernel risk

The selected pin is XanMod **6.12.67**, revision **0~20260123.ga077982**, copied from upstream 0.1082's optional 6.12 path. Its presence in 0.1082 does not establish full compatibility with this derived 0.1046 bundle. It predates later security fixes, including the upstream MPTCP IPv6 subflow fix in 6.12.82. IPv6-disable sysctls are applied before installation; network setup can re-enable IPv6 after reboot. Boot-level IPv6 disablement remains excluded at the user's direction. The fresh disposable installation, 6.12.67 boot and server runtime checks passed on 2026-10-02. Paired-router traffic, failover, throughput and longer stability checks remain pending before production use.
