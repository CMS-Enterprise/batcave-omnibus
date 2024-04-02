FROM golang:alpine3.19 as build

# Link to All Apps https://arc.net/folder/40C7B38D-FE7B-4DCE-BEF2-49C652757741

ARG GRYPE_VERSION=v0.74.7
ARG SYFT_VERSION=v1.1.0
ARG GITLEAKS_VERSION=v8.18.2
ARG COSIGN_VERSION=v2.2.3
ARG CRANE_VERSION=v0.19.1
ARG RELEASE_CLI_VERSION=v0.16.0
ARG GATECHECK_VERSION=v0.4.1
ARG S3UPLOAD_VERSION=v1.0.4
ARG ORAS_VERSION=v1.1.0
ARG SHOUT_VERSION=v0.1.1

RUN apk --no-cache add ca-certificates git make

WORKDIR /app

# Layer on purpose for caching improvements
RUN git clone --branch ${GRYPE_VERSION} --depth=1 --single-branch https://github.com/anchore/grype /app/grype
RUN git clone --branch ${SYFT_VERSION} --depth=1 --single-branch https://github.com/anchore/syft /app/syft
RUN git clone --branch ${GITLEAKS_VERSION} --depth=1 --single-branch https://github.com/zricethezav/gitleaks /app/gitleaks
RUN git clone --branch ${COSIGN_VERSION} --depth=1 --single-branch https://github.com/sigstore/cosign /app/cosign
RUN git clone --branch ${CRANE_VERSION} --depth=1 --single-branch https://github.com/google/go-containerregistry /app/go-containerregistry
RUN git clone --branch ${RELEASE_CLI_VERSION} --depth=1 --single-branch https://gitlab.com/gitlab-org/release-cli /app/release-cli
RUN git clone --branch ${GATECHECK_VERSION} --depth=1 --single-branch https://github.com/gatecheckdev/gatecheck /app/gatecheck
RUN git clone --branch ${SHOUT_VERSION} --depth=1 --single-branch https://github.com/bacchusjackson/shout /app/shout
RUN git clone --branch ${S3UPLOAD_VERSION} --depth=1 --single-branch https://github.com/bacchusjackson/go-s3-upload /app/go-s3-upload
RUN git clone --branch ${ORAS_VERSION} --depth=1 --single-branch https://github.com/oras-project/oras /app/oras


RUN cd /app/grype && \
    go build -ldflags="-w -s -extldflags '-static' -X 'main.version=${GRYPE_VERSION}' -X 'main.gitCommit=$(git rev-parse HEAD)' -X 'main.buildDate=$(date -u +%Y-%m-%dT%H:%M:%SZ)' -X 'main.gitDescription=$(git log -1 --pretty=%B)'" -o /usr/local/bin ./cmd/grype

RUN cd /app/syft && \
    go build -ldflags="-w -s -extldflags '-static' -X 'main.version=${SYFT_VERSION}' -X 'main.gitCommit=$(git rev-parse HEAD)' -X 'main.buildDate=$(date -u +%Y-%m-%dT%H:%M:%SZ)' -X 'main.gitDescription=$(git log -1 --pretty=%B)'" -o /usr/local/bin ./cmd/syft

RUN cd /app/gitleaks && \
    go build -ldflags="-s -w -X=github.com/zricethezav/gitleaks/v8/cmd.Version=${GITLEAKS_VERSION}" -o /usr/local/bin .

RUN cd /app/cosign && \
    make cosign && \
    mv cosign /usr/local/bin

RUN cd /app/go-containerregistry && \
    go build -ldflags="-s -w -X github.com/google/go-containerregistry/cmd/crane/cmd.Version=${CRANE_VERSION}" -o /usr/local/bin ./cmd/crane

RUN cd /app/release-cli && \
    make build && \
    mv ./bin/release-cli /usr/local/bin

RUN cd /app/gatecheck && \
    go build -ldflags="-s -w -X 'main.cliVersion=$(git describe --tags)' -X 'main.gitCommit=$(git rev-parse HEAD)' -X 'main.buildDate=$(date -u +%Y-%m-%dT%H:%M:%SZ)' -X 'main.gitDescription=$(git log -1 --pretty=%B)'" -o /usr/local/bin ./cmd/gatecheck

RUN cd /app/shout && \
    go build -ldflags="-s -w -X 'main.cliVersion=$(git describe --tags)' -X 'main.gitCommit=$(git rev-parse HEAD)' -X 'main.buildDate=$(date -u +%Y-%m-%dT%H:%M:%SZ)' -X 'main.gitDescription=$(git log -1 --pretty=%B)'" -o /usr/local/bin .

RUN cd /app/go-s3-upload && \
    go build -ldflags="-s -w" -o /usr/local/bin/s3upload .

RUN cd /app/oras && \
    make build-linux-amd64 && \
    mv bin/linux/amd64/oras /usr/local/bin/oras

FROM rust:alpine3.19 as build-just

RUN apk add musl-dev
RUN cargo install just

# Build Semgrep Core
#
# The Docker image below (after the 'FROM') is prepackaged with 'ocamlc',
# 'opam', and lots of packages that are used by semgrep-core and installed in
# the 'make install-deps' command further below.
# See https://github.com/returntocorp/ocaml-layer/blob/master/configs/alpine.sh
# for this list of packages.
# Thanks to this container, 'make install-deps' finishes very quickly because it's
# mostly a noop. Alternative base container candidates are:
#
#  - 'ocaml/opam:alpine', the official OCaml/opam Docker image,
#    but building our Docker image would take longer because
#    of all the necessary Semgrep dependencies installed in 'make install-deps'.
#
#    We build a new Semgrep Docker image on each pull-request (PR) so we don't
#    want to wait 30min each time just for 'docker build' to finish.
#
#    Note also that ocaml/opam:alpine default user is 'opam', not 'root', which
#    is not without problems when used inside Github actions (GHA) or even inside
#    this Dockerfile.
#
#  - 'alpine', the official Alpine Docker image, but this would require some
#    extra 'apk' commands to install opam, and extra commands to setup OCaml
#    with this opam from scratch, and more importantly this would take
#    far more time to finish. Moreover, it is not trivial to work from such
#    a base container as 'opam' itself requires lots of extra
#    tools like gcc, make, which are not provided by default on Alpine.
#
# An alternative to ocaml-layer would be to use https://depot.dev/
#
# Note that the Docker base image below currently uses OCaml 4.14.0
# coupling: if you modify the OCaml version there, you probably also need
# to modify:
# - scripts/{osx-setup-for-release,setup-m1-builder}.sh
# - doc/SEMGREP_CORE_CONTRIBUTING.md
# - https://github.com/Homebrew/homebrew-core/blob/master/Formula/semgrep.rb
#
# coupling: if you modify the FROM below, you probably need to modify also
# a few .github/workflows/ files. grep for returntocorp/ocaml there.

FROM returntocorp/ocaml:alpine-2023-10-17 as build-semgrep-core

ARG SEMGREP_VERSION=v1.45.0

WORKDIR /src

RUN apk add --no-cache git make

RUN git clone --recurse-submodules --branch ${SEMGREP_VERSION} --depth=1 --single-branch https://github.com/semgrep/semgrep /src/semgrep

WORKDIR /src/semgrep

RUN make install-deps-ALPINE-for-semgrep-core &&\
    make install-deps-for-semgrep-core

COPY Makefile.semgrep .

# Let's build just semgrep-core
# Note: I'm not sure that using dune --release actually makes an appreciable difference
# The binary is the same size, and I haven't tested the result when building without --release
RUN eval "$(opam env)" &&\
    make -f Makefile.semgrep release-build &&\
    # Sanity check
    /src/semgrep/_build/default/src/main/Main.exe -version

FROM alpine:3.19.1

RUN apk --no-cache add curl jq sqlite-libs git ca-certificates tzdata clamav

WORKDIR /app

LABEL org.opencontainers.image.title="omnibus"
LABEL org.opencontainers.image.description="A collection of CI/CD tools for batCAVE"
LABEL org.opencontainers.image.vendor="CMS batCAVE - Pipeline Team"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL io.artifacthub.package.readme-url="https://raw.githubusercontent.com/CMS-Enterprise/batcave-omnibus/main/README.md"
LABEL io.artifacthub.package.license="Apache-2.0"

COPY --from=build-just /usr/local/cargo/bin/just /usr/local/bin/just
COPY --from=build-semgrep-core /src/semgrep/_build/default/src/main/Main.exe /usr/local/bin/osemgrep

COPY --from=build /usr/local/bin/grype /usr/local/bin/grype
COPY --from=build /usr/local/bin/syft /usr/local/bin/syft
COPY --from=build /usr/local/bin/gitleaks /usr/local/bin/gitleaks
COPY --from=build /usr/local/bin/cosign /usr/local/bin/cosign
COPY --from=build /usr/local/bin/crane /usr/local/bin/crane
COPY --from=build /usr/local/bin/release-cli /usr/local/bin/release-cli
COPY --from=build /usr/local/bin/gatecheck /usr/local/bin/gatecheck
COPY --from=build /usr/local/bin/shout /usr/local/bin/shout
COPY --from=build /usr/local/bin/s3upload /usr/local/bin/s3upload
COPY --from=build /usr/local/bin/oras /usr/local/bin/oras

