FROM rust

COPY . /portablegabi-node
WORKDIR /portablegabi-node

RUN apt-get -y update && \
	apt-get install -y --no-install-recommends \
	openssl \
	curl \
	libssl-dev dnsutils \
	clang

RUN /bin/bash scripts/init.sh
RUN cargo build --release

# expose node ports
EXPOSE 30333 9933 9944

ENTRYPOINT [ "/portablegabi-node/target/release/node-portablegabi" ]
CMD ["--dev", "--ws-port", "9944", "--ws-external"]
