# ExpressVPN (Minimal Container)

This fork is intentionally stripped down for high-density deployments (for example, running hundreds or thousands of containers).

## What is kept

- ExpressVPN bootstrap and activation with `CODE`.
- Initial VPN connect to `SERVER`.
- Fast Docker healthcheck script.
- Auto-reconnect on failure from the healthcheck script.

## What was removed

- Metrics server/exporter.
- Control API server.
- SOCKS5 proxy.
- DNS leak helper scripts and optional external health integrations.
- Extra runtime dependencies used only by removed features.

## Required capabilities

```bash
docker run \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_PTRACE \
  --device=/dev/net/tun \
  -e CODE=your_code \
  -e SERVER=smart \
  your-image
```

## Runtime environment variables

| ENV | Description | Default |
| :--- | :--- | :---: |
| `CODE` | ExpressVPN activation code | `code` |
| `SERVER` | Region name or `smart` | `smart` |
| `PROTOCOL` | VPN protocol (`auto`, `lightwayudp`, `lightwaytcp`, `openvpnudp`, `openvpntcp`, `wireguard`) | `lightwayudp` |
| `HEALTHCHECK_RECONNECT_WAIT` | Seconds to wait for reconnect success during healthcheck | `15` |

## Behavior

1. Container startup script activates account, sets protocol, and connects VPN.
2. Docker healthcheck runs `/expressvpn/healthcheck.sh` every 30 seconds.
3. If tunnel is down, healthcheck script attempts reconnect immediately.
4. Container returns healthy only when connected and `tun0` exists.
