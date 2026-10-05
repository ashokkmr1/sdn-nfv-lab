# The "VNF": a transparent (bump-in-the-wire) L2 firewall in a container.
FROM alpine:3.20
RUN apk add --no-cache bash iproute2 nftables tcpdump
COPY fw.sh /fw.sh
RUN chmod +x /fw.sh
CMD ["sleep", "infinity"]
