#!/bin/sh
# Run after the required reboot. Prints no credentials.
set -u
FAILED=0
check() {
    label=$1
    shift
    if "$@" >/dev/null 2>&1; then
        printf 'PASS %s\n' "$label"
    else
        printf 'FAIL %s\n' "$label"
        FAILED=1
    fi
}
printf 'Running kernel: %s\n' "$(uname -r)"
check 'XanMod 6.12.67 is running' sh -c 'case "$(uname -r)" in 6.12.67-*-xanmod1) exit 0;; *) exit 1;; esac'
# The user's IPv6 preparation policy is enforced before installation.
# Report post-boot runtime state without requiring persistent disablement.
printf 'IPv6 runtime state (informational; preparation uses sysctl.d):\n'
for scope in all default lo; do
    value=$(cat "/proc/sys/net/ipv6/conf/$scope/disable_ipv6" 2>/dev/null || printf 'unavailable')
    printf '  %s.disable_ipv6=%s\n' "$scope" "$value"
done
printf '  IPv6 address count: '
ip -6 -o address show 2>/dev/null | awk 'END { print NR+0 }'
printf '  IPv6 default route count: '
ip -6 route show default 2>/dev/null | awk 'END { print NR+0 }'
check 'MPTCP enabled' sh -c '[ "$(sysctl -n net.mptcp.enabled 2>/dev/null)" = 1 ]'
check 'omr-admin active' systemctl is-active --quiet omr-admin
check 'Shorewall active' systemctl is-active --quiet shorewall
for unit in omr xray v2ray shadowsocks-go shadowsocks-libev-manager@manager glorytun-udp@tun0 glorytun-tcp@tun0 mlvpn@mlvpn0 dsvpn-server@dsvpn0 openvpn@tun0 openvpn@tun1 wg-quick@wg0 iperf3 fail2ban; do
    check "$unit active" systemctl is-active --quiet "$unit"
done
check 'Shadowsocks manager enabled' systemctl is-enabled --quiet shadowsocks-libev-manager@manager.service
check 'Glorytun UDP enabled' systemctl is-enabled --quiet glorytun-udp@tun0.service
check 'Glorytun TCP enabled' systemctl is-enabled --quiet glorytun-tcp@tun0.service
check 'MLVPN enabled' systemctl is-enabled --quiet mlvpn@mlvpn0.service
check 'OMR API local HTTPS' sh -c '[ "$(curl -k -s -o /dev/null -w "%{http_code}" --max-time 5 https://127.0.0.1:65500/)" = 200 ]'
printf 'GRUB_DEFAULT: '
grep '^GRUB_DEFAULT=' /etc/default/grub 2>/dev/null || true
ADMIN_VERSION=$(dpkg-query -W -f='${Version}' omr-vps-admin 2>/dev/null || true)
check 'admin package pin' test "$ADMIN_VERSION" = '0.16+20251126'
printf 'Installed admin package: '
dpkg-query -W -f='${Version}\n' omr-vps-admin 2>/dev/null || true
printf 'Listening on 65500:\n'
ss -ltn '( sport = :65500 )' 2>/dev/null || true
exit "$FAILED"
