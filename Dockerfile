FROM ubuntu:25.10

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:0
ENV RESOLUTION=1280x720

RUN apt-get update && apt-get install -y \
    lxde-core lxterminal \
    x11vnc xvfb \
    tigervnc-standalone-server \
    net-tools curl wget \
    x11-utils procps \
    sudo \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY ./config/lxpanel /etc/skel/.config/lxpanel

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD netstat -tuln | grep -q ':5900' || exit 1

EXPOSE 5900

CMD ["/entrypoint.sh"]

