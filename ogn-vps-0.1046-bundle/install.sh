#!/bin/sh
# OGN online-assisted installer for fresh OVH Debian 13 amd64 UEFI VPSs.
set -eu

BUNDLE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TARGET_DIR=/opt/ogn-vps/0.1046-rolling
SYSCTL_FILE=/etc/sysctl.d/99-disable-ipv6.conf

fail() { echo "ERROR: $*" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || fail "Run as root."
[ -r /etc/os-release ] || fail "Cannot identify the operating system."
. /etc/os-release
[ "$ID" = debian ] && [ "$VERSION_ID" = 13 ] || fail "Requires Debian 13."
[ "$(dpkg --print-architecture)" = amd64 ] || fail "Requires amd64."
[ -d /sys/firmware/efi ] || fail "Requires a UEFI-booted VPS."
command -v python3 >/dev/null 2>&1 || fail "python3 is required to verify the bundle."
command -v ip >/dev/null 2>&1 || fail "iproute2 is required."
command -v wget >/dev/null 2>&1 || fail "wget is required by the upstream installer."
python3 "$BUNDLE_DIR/verify-bundle.py" "$BUNDLE_DIR" || fail "Bundle integrity check failed."

DEFAULT_ROUTES=$(ip -4 route show default)
ROUTE_COUNT=$(printf '%s\n' "$DEFAULT_ROUTES" | awk 'NF { n++ } END { print n+0 }')
if [ "$ROUTE_COUNT" -ne 1 ]; then
    echo "IPv4 default routes found:" >&2
    printf '%s\n' "$DEFAULT_ROUTES" >&2
    fail "Expected one IPv4 default route. Resolve any OVH private-interface DHCP route through the provider console, then rerun. This installer never edits netplan."
fi

if [ -e "$SYSCTL_FILE" ]; then
    EXPECTED=$(printf 'net.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.default.disable_ipv6 = 1\nnet.ipv6.conf.lo.disable_ipv6 = 1\n')
    ACTUAL=$(cat "$SYSCTL_FILE")
    [ "$ACTUAL" = "$EXPECTED" ] || fail "$SYSCTL_FILE already exists with different content; review it before rerunning."
else
    cat > "$SYSCTL_FILE" <<'IPV6'
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
IPV6
    chmod 644 "$SYSCTL_FILE"
fi
sysctl --system || fail "Could not apply system sysctl settings."
for scope in all default lo; do
    [ "$(cat "/proc/sys/net/ipv6/conf/$scope/disable_ipv6")" = 1 ] || fail "IPv6 remains enabled for $scope."
done
wget -4 -q --spider -T 15 https://deb.debian.org/debian/ || fail "IPv4 internet access to Debian is unavailable."

export DEBIAN_FRONTEND=noninteractive
apt-get -y remove unattended-upgrades
apt-get -o Acquire::ForceIPv4=true update
apt-get -o Acquire::ForceIPv4=true -y upgrade

if [ "$BUNDLE_DIR" != "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
    cp -a "$BUNDLE_DIR/." "$TARGET_DIR/"
fi
python3 "$TARGET_DIR/verify-bundle.py" "$TARGET_DIR" || fail "Staged bundle integrity check failed."
export OGN_LOCAL_REPO="$TARGET_DIR/repo"
export LOCALFILES=yes
export SOURCES=no
export KERNEL=6.12
cd "$TARGET_DIR/payload"
sh ./debian9-x86_64.sh
printf '\nInstallation script finished. Reboot the VPS, reconnect on SSH port 65222, and run %s/verify-vps.sh.\n' "$TARGET_DIR"
