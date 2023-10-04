# TODO: clamAV, semgrep

FROM golang:alpine as build

ARG GRYPE_VERSION=v0.68.1
ARG SYFT_VERSION=v0.90.0
ARG GITLEAKS_VERSION=v8.18.0
ARG COSIGN_VERSION=v2.2.0
ARG CRANE_VERSION=v0.16.1
ARG RELEASE_CLI_VERSION=v0.16.0
ARG GATECHECK_VERSION=v0.2.1

RUN apk --no-cache add ca-certificates git openssh make

WORKDIR /app

# Layer on purpose for caching improvements
RUN git clone --branch ${GRYPE_VERSION} --depth 1 https://github.com/anchore/grype
WORKDIR /app/grype
RUN go build -ldflags="-w -s -extldflags '-static' -X 'main.version=${GRYPE_VERSION}' -X 'main.gitCommit=$(git rev-parse HEAD)' -X 'main.buildDate=$(date -u +%Y-%m-%dT%H:%M:%SZ)' -X 'main.gitDescription=$(git log -1 --pretty=%B)'" -o /usr/local/bin ./cmd/grype
    
RUN git clone --branch ${SYFT_VERSION} --depth 1 https://github.com/anchore/syft
WORKDIR /app/syft 
RUN go build -ldflags="-w -s -extldflags '-static' -X 'main.version=${SYFT_VERSION}' -X 'main.gitCommit=$(git rev-parse HEAD)' -X 'main.buildDate=$(date -u +%Y-%m-%dT%H:%M:%SZ)' -X 'main.gitDescription=$(git log -1 --pretty=%B)'" -o /usr/local/bin ./cmd/syft
    
RUN git clone --branch ${GITLEAKS_VERSION} --depth 1 https://github.com/zricethezav/gitleaks
WORKDIR /app/gitleaks
RUN go build -ldflags="-s -w -X=github.com/zricethezav/gitleaks/v8/cmd.Version=${GITLEAKS_VERSION}" -o /usr/local/bin .

RUN git clone --branch ${COSIGN_VERSION} --depth 1 https://github.com/sigstore/cosign
WORKDIR /app/cosign
RUN make cosign && \
    mv cosign /usr/local/bin
   
RUN git clone --branch ${CRANE_VERSION} --depth 1 https://github.com/google/go-containerregistry
WORKDIR /app/go-containerregistry
RUN go build -ldflags="-s -w -X github.com/google/go-containerregistry/cmd/crane/cmd.Version=${CRANE_VERSION}" -o /usr/local/bin ./cmd/crane

RUN git clone --branch ${RELEASE_CLI_VERSION} --depth 1 https://gitlab.com/gitlab-org/release-cli
WORKDIR /app/release-cli
RUN make build && \
    mv ./bin/release-cli /usr/local/bin
    
RUN git clone --branch ${GATECHECK_VERSION} --depth 1 https://github.com/gatecheckdev/gatecheck
WORKDIR /app/gatecheck
RUN go build -ldflags="-s -w" -o /usr/local/bin ./cmd/gatecheck
    
# Final Image
FROM alpine:latest

RUN apk --no-cache add curl jq sqlite-libs git ca-certificates 

ENV USER=omnibus
ENV UID=12345
ENV GID=23456

WORKDIR /app

RUN addgroup omnibus && adduser \
    --disabled-password \
    --gecos "" \
    --home "$(pwd)" \
    --ingroup "$USER" \
    --uid "$UID" \
    "$USER" && \
	chown -R omnibus:omnibus /usr/local/bin/ && \
	chown -R omnibus:omnibus /app

COPY --from=build /usr/local/bin/grype /usr/local/bin/grype
COPY --from=build /usr/local/bin/syft /usr/local/bin/syft
COPY --from=build /usr/local/bin/gitleaks /usr/local/bin/gitleaks
COPY --from=build /usr/local/bin/cosign /usr/local/bin/cosign
COPY --from=build /usr/local/bin/crane /usr/local/bin/crane
COPY --from=build /usr/local/bin/release-cli /usr/local/bin/release-cli
COPY --from=build /usr/local/bin/gatecheck /usr/local/bin/gatecheck

USER omnibus

LABEL org.opencontainers.image.title="omnibus"
LABEL org.opencontainers.image.description="A collection of CI/CD tools for batCAVE"
LABEL org.opencontainers.image.vendor="nightwing"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL io.artifacthub.package.readme-url="https://code.batcave.internal.cms.gov/devops-pipelines/pipeline-tools/omnibus/-/blob/main/README.md"
LABEL io.artifacthub.package.license="Apache-2.0"
