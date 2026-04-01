ARG DISTRIBUTION="trixie-slim"
FROM debian:${DISTRIBUTION}

ENV CODE="code" \
    SERVER="smart" \
    PROTOCOL="lightwayudp" \
    NETWORK="on" \
    ALLOW_LAN="true" \
    HEALTHCHECK_RECONNECT_WAIT="15"

ARG EXPRESSVPN_VERSION="5.1.0.12141"
ARG EXPRESSVPN_RUN_URL="https://www.expressvpn.works/clients/linux/expressvpn-linux-universal-${EXPRESSVPN_VERSION}_release.run"
COPY files/start.sh files/healthcheck.sh /expressvpn/

RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        iptables \
        libatomic1 \
        libglib2.0-0 \
        procps \
        psmisc \
        xz-utils; \
    curl -fsSL "${EXPRESSVPN_RUN_URL}" -o /tmp/expressvpn.run; \
    sh /tmp/expressvpn.run --accept --quiet --noprogress -- --no-gui --sysvinit; \
    rm -f /tmp/expressvpn.run; \
    rm -rf /var/lib/apt/lists/*; \
    rm -rf /var/log/*.log

HEALTHCHECK --start-period=30s --timeout=15s --interval=30s --retries=3 CMD bash /expressvpn/healthcheck.sh

ENTRYPOINT ["/bin/bash", "/expressvpn/start.sh"]
