FROM rust as builder

COPY . /portablegabi-node/

WORKDIR /portablegabi-node

RUN apt-get clean && apt-get -y update && \
	apt-get install -y --no-install-recommends \
	openssl \
	curl \
	libssl-dev dnsutils \
	clang

RUN bash scripts/init.sh
RUN bash scripts/build.sh
RUN cargo build --release

# expose node ports
EXPOSE 30333 9933 9944

FROM rust

RUN apt-get clean && apt-get -y update && \
	apt-get install -y --no-install-recommends \
	openssl \
	curl \
	libssl-dev dnsutils \
	clang

# cleanup
RUN apt-get autoremove -y
RUN apt-get clean -y
RUN rm -rf /tmp/* /var/tmp/*

RUN mkdir -p /target/release
COPY --from=builder /portablegabi-node/target/release/node-portablegabi /target/release/node-portablegabi

ENTRYPOINT [ "/target/release/node-portablegabi" ]
CMD ["--dev", "--ws-port", "9944", "--ws-external"]