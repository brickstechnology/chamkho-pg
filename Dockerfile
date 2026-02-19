FROM docker.io/postgres:17 AS build
ARG RUST_VERSION=1.88.0
RUN apt-get update; apt-get upgrade -y
RUN apt-get install -y clang llvm-dev curl postgresql-server-dev-17
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup install $RUST_VERSION
RUN mkdir /work
COPY Cargo.toml Cargo.lock install.sh README.md build.rs wrapper.h /work/
COPY src/ /work/src/
COPY control/ /work/control/
COPY data/ /work/data/
COPY sql/ /work/sql
WORKDIR /work
RUN cargo build --release

FROM docker.io/postgres:17
COPY --from=build /work/target/release/libchamkho_parser.so /usr/lib/postgresql/17/lib/chamkho_parser.so
COPY --from=build /work/control/*.control /work/sql/*.sql /usr/share/postgresql/17/extension/
COPY --from=build /work/data/chamkho_dict.txt /usr/share/postgresql/17/tsearch_data/
COPY --from=build /work /work


