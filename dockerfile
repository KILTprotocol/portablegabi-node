FROM rust

# create a new empty shell project
RUN USER=root cargo new --bin portablegabi-node
WORKDIR /portablegabi-node
RUN USER=root cargo new --lib runtime

# copy over your manifests
COPY ./Cargo.lock ./Cargo.lock
COPY ./Cargo.toml ./Cargo.toml
COPY ./runtime/Cargo.toml ./runtime/Cargo.toml

# this build step will cache your dependencies
RUN cargo build --release
RUN rm src/*.rs

# copy your source tree
COPY ./src ./src
COPY ./runtime ./runtime

# build for release
RUN rm ./target/release/deps/portablegabi-node*
RUN cargo build --release


RUN /bin/bash scripts/init.sh

RUN cargo build --release

FROM ubuntu:xenial

WORKDIR /runtime

RUN apt-get -y update && \
	apt-get install -y --no-install-recommends \
	openssl \
	curl \
	libssl-dev dnsutils \
	clang

RUN mkdir -p /runtime/target/release/
COPY --from=builder /build/target/release/node-portablegabi ./target/release/node-portablegabi

# expose node ports
EXPOSE 30333 9933 9944

ENTRYPOINT [ "/runtime/target/release/node-portablegabi" ]
CMD ["--dev", "--ws-port", "9944", "--ws-external"]
