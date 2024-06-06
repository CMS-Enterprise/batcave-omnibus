ARG SEMGREP_VERSION=1.75.0

FROM golang:alpine3.20 as build

# Link to All Apps https://arc.net/folder/40C7B38D-FE7B-4DCE-BEF2-49C652757741

ARG GRYPE_VERSION=v0.78.0
ARG SYFT_VERSION=v1.5.0
ARG GITLEAKS_VERSION=v8.18.3
ARG COSIGN_VERSION=v2.2.4
ARG CRANE_VERSION=v0.19.1
ARG RELEASE_CLI_VERSION=v0.18.0
ARG GATECHECK_VERSION=v0.7.3
ARG S3UPLOAD_VERSION=v1.0.4
ARG ORAS_VERSION=v1.2.0
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

FROM rust:alpine3.20 as build-just

RUN apk add musl-dev
RUN cargo install just

FROM semgrep/semgrep:$SEMGREP_VERSION as semgrep

FROM alpine:3.20

RUN apk --no-cache add curl jq sqlite-libs git ca-certificates tzdata clamav

WORKDIR /app

LABEL org.opencontainers.image.title="omnibus"
LABEL org.opencontainers.image.description="A collection of CI/CD tools for batCAVE"
LABEL org.opencontainers.image.vendor="CMS batCAVE - Pipeline Team"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL io.artifacthub.package.readme-url="https://raw.githubusercontent.com/CMS-Enterprise/batcave-omnibus/main/README.md"
LABEL io.artifacthub.package.license="Apache-2.0"

COPY --from=build-just /usr/local/cargo/bin/just /usr/local/bin/just
COPY --from=semgrep /usr/local/bin/semgrep-core /usr/local/bin/osemgrep

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
