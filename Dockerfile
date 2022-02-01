#######################################################################################################################
# Build AdGuardHome frontend
#######################################################################################################################
FROM lansible/nexe:4.0.0-beta.19 as frontend

# https://github.com/AdguardTeam/AdGuardHome/releases/
ENV VERSION=v0.107.3

RUN git clone --depth 1 --branch "${VERSION}" https://github.com/AdguardTeam/AdGuardHome.git /AdGuardHome

WORKDIR /AdGuardHome/client

# Install all modules
# Run build to make all html files
# creates client/public folder
RUN CORES=$(grep -c '^processor' /proc/cpuinfo); \
  export MAKEFLAGS="-j$((CORES+1)) -l${CORES}"; \
  npm ci --no-audit --no-optional --no-update-notifier && \
  npm run build-prod


#######################################################################################################################
# Build static AdGuardHome
#######################################################################################################################
FROM golang:1.17.6-alpine3.15 as builder

# Add unprivileged user and group
RUN echo "adguardhome:x:1000:1000:adguardhome:/:" > /etc_passwd && \
    echo "adguardhome:x:1000:adguardhome" > /etc_group

# Do a copy so the frontend is in place
COPY --from=frontend /AdGuardHome /AdGuardHome

WORKDIR /AdGuardHome

RUN go mod download && \
    CGO_ENABLED=0 go build -ldflags='-s -w'

# 'Install' upx from image since upx isn't available for aarch64 from Alpine
COPY --from=lansible/upx /usr/bin/upx /usr/bin/upx
# Minify binaries
# no upx: 24.7M
# upx: 8.2M
# --best: 6.6M
# --brute: 5.0M
# --ultra-brute: 5.0M
RUN upx --brute /AdGuardHome/AdGuardHome && \
    upx -t /AdGuardHome/AdGuardHome


#######################################################################################################################
# Final scratch image
#######################################################################################################################
FROM scratch

# Add description
LABEL org.label-schema.description="AdGuardHome as static binary in a scratch container"

# Copy the unprivileged user
COPY --from=builder /etc_passwd /etc/passwd
COPY --from=builder /etc_group /etc/group

# Add ssl certificates
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# Add the binary
COPY --from=builder /AdGuardHome/AdGuardHome /opt/adguardhome/AdGuardHome
# Add the default config
COPY --chown=adguardhome:adguardhome ./examples/docker-compose/config/AdGuardHome.yaml /opt/adguardhome/conf/AdGuardHome.yaml
# Add symlink (tarred to keep symbolic link to /dev/shm). Can be overidden by user for persistance
ADD  ./symlink-work-dev-shm /opt/adguardhome/

# 53     : TCP, UDP : DNS
# 67     :      UDP : DHCP (server)
# 68     :      UDP : DHCP (client)
# 80     : TCP      : HTTP (main)
# 443    : TCP, UDP : HTTPS, DNS-over-HTTPS (incl. HTTP/3), DNSCrypt (main)
# 784    :      UDP : DNS-over-QUIC (experimental)
# 853    : TCP, UDP : DNS-over-TLS, DNS-over-QUIC
# 3000   : TCP, UDP : HTTP(S) (alt, incl. HTTP/3)
# 3001   : TCP, UDP : HTTP(S) (beta, incl. HTTP/3)
# 5443   : TCP, UDP : DNSCrypt (alt)
# 6060   : TCP      : HTTP (pprof)
# 8853   :      UDP : DNS-over-QUIC (experimental)
EXPOSE 53/tcp 53/udp 67/udp 68/udp 80/tcp 443/tcp 443/udp 784/udp\
	853/tcp 853/udp 3000/tcp 3000/udp 3001/tcp 3001/udp 5443/tcp\
	5443/udp 6060/tcp 8853/udp

USER adguardhome
ENTRYPOINT ["/opt/adguardhome/AdGuardHome"]
CMD [ \
	"--no-check-update", \
	"-c", "/opt/adguardhome/conf/AdGuardHome.yaml", \
	"-h", "0.0.0.0", \
	"-w", "/opt/adguardhome/work" \
]