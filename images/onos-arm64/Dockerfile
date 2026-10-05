# OPTIONAL, UNTESTED: native arm64 ONOS 2.7.0 (the official image is amd64-only and
# runs under Rosetta). Only try this if the Rosetta image is too slow on the Mac.
#   docker build -t onos:2.7.0-arm64 images/onos-arm64
# then change the image in labs/ctrl.clab.yml to onos:2.7.0-arm64
FROM eclipse-temurin:11-jre
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
WORKDIR /root
RUN curl -fsSL https://repo1.maven.org/maven2/org/onosproject/onos-releases/2.7.0/onos-2.7.0.tar.gz | tar xz \
    && mv onos-2.7.0 onos
WORKDIR /root/onos
EXPOSE 6653 6640 8181 8101 9876
ENTRYPOINT ["./bin/onos-service"]
CMD ["server"]
