FROM debian:bullseye-slim as builder

LABEL maintainer="Wesley Blake (@WesleyCharlesBlake)"

RUN useradd -r bitcoin \
  && apt-get update -y \
  && apt-get install -y curl gnupg \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# This should be ARG and created based on the host image builder platform.
ENV TARGETPLATFORM=linux/amd64
ENV BITCOIN_VERSION=0.21.0

RUN set -ex \
  && if [ "${TARGETPLATFORM}" = "linux/amd64" ]; then export TARGETPLATFORM=x86_64-linux-gnu; fi \
  && if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then export TARGETPLATFORM=aarch64-linux-gnu; fi \
  && if [ "${TARGETPLATFORM}" = "linux/arm/v7" ]; then export TARGETPLATFORM=arm-linux-gnueabihf; fi \

  && curl -SLO https://bitcoin.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-${TARGETPLATFORM}.tar.gz \

  && tar -xzf *.tar.gz -C /opt \
  && rm *.tar.gz \
  && rm -rf /opt/bitcoin-${BITCOIN_VERSION}/bin/bitcoin-qt

# Start a new, final image to reduce size.
FROM ubuntu:20.04 as final

RUN useradd -r bitcoin && \
  apt-get update -y \
  && apt-get install -y curl gosu \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV BITCOIN_DATA=/home/bitcoin/.bitcoin
ENV BITCOIN_VERSION=0.21.0
ENV PATH=/opt/bitcoin-${BITCOIN_VERSION}/bin:$PATH

VOLUME ["/home/bitcoin/.bitcoin"]

EXPOSE 8332 8333 18332 18333 18443 18444

COPY docker-entrypoint.sh /entrypoint.sh

COPY --from=builder /opt/ /opt/

RUN ls -al /opt/

ENTRYPOINT ["/entrypoint.sh"]

RUN bitcoind -version | grep "Bitcoin Core version v${BITCOIN_VERSION}"

CMD ["bitcoind"]