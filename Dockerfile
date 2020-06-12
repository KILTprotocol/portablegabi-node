# the WASM build of the runtime is completely indepedent 
# we can avoid cache invalidations by running it in an extra container
FROM rust as builder

# install rust nightly
RUN rustup update nightly

# install wasm toolchain for polkadot
RUN rustup target add wasm32-unknown-unknown --toolchain nightly

# Install wasm-gc. It's useful for stripping slimming down wasm binaries.
# (polkadot)
RUN cargo +nightly install --git https://github.com/alexcrichton/wasm-gc

# show backtraces
ENV RUST_BACKTRACE 1

# Copy runtime library files
COPY ./runtime/Cargo.lock ./runtime/Cargo.toml ./runtime/
COPY ./runtime/src ./runtime/src
# Copy WASM build crate files
COPY ./runtime/wasm/build.sh ./runtime/wasm/Cargo.lock ./runtime/wasm/Cargo.toml ./runtime/wasm/
COPY ./runtime/wasm/src ./runtime/wasm/src

WORKDIR /build

# install clang
RUN apt-get clean && apt-get -y update && \
	apt-get install -y --no-install-recommends \
	openssl \
	curl \
	libssl-dev dnsutils \
	clang

# show backtraces
ENV RUST_BACKTRACE 1

# to avoid early cache invalidation, we build only dependencies first. For this we create fresh crates we are going to overwrite.
RUN USER=root cargo init --bin --name=portablegabi-node
RUN USER=root cargo new --lib --name=portablegabi-node-runtime runtime
RUN USER=root cargo new --name=portablegabi-node-node node
# overwrite cargo.toml with real files
COPY Cargo.toml Cargo.lock build.rs ./
COPY ./runtime/Cargo.toml ./runtime/Cargo.lock ./runtime/
COPY ./node/Cargo.toml ./node/build.rs ./node/

# build depedencies (and bogus source files)
RUN cargo build --release

# remove bogus build (but keep depedencies)
RUN cargo clean --release -p portablegabi-node-runtime

# copy everything over (cache invalidation will happen here)
COPY . /build
# get wasm built in previous step
COPY --from=builder /runtime/wasm/target/wasm32-unknown-unknown/release ./runtime/wasm/target/wasm32-unknown-unknown/release
# build source again, dependencies are already built
RUN cargo build --release

# test
RUN cargo test --release -p portablegabi-node-runtime


WORKDIR /runtime

# cleanup linux dependencies
RUN apt-get autoremove -y
RUN apt-get clean -y
RUN rm -rf /tmp/* /var/tmp/*

RUN mkdir -p /runtime/target/release/
COPY --from=builder /build/target/release/portablegabi-node ./target/release/portablegabi-node

RUN chmod a+x *.sh
RUN ls -la .

# expose node ports
EXPOSE 30333 9933 9944

# add entrypoint
ENTRYPOINT [ "/target/release/portablegabi-node" ]

# add default commands s.t. you only have to call docker run -p 9944:9944 kiltprotocol/portablegabi-node
CMD ["--dev", "--ws-port", "9944", "--ws-external"]