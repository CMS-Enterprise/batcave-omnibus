# TODO: clamAV, semgrep

FROM golang:alpine as build

ARG GRYPE_VERSION=v0.69.0
ARG SYFT_VERSION=v0.91.0
ARG GITLEAKS_VERSION=v8.18.0
ARG COSIGN_VERSION=v2.2.0
ARG CRANE_VERSION=v0.16.1
ARG RELEASE_CLI_VERSION=v0.16.0
ARG GATECHECK_VERSION=v0.2.1

RUN apk --no-cache add ca-certificates git openssh

# Layer on purpose for caching improvements
RUN go install github.com/anchore/grype/cmd/grype@${GRYPE_VERSION}
RUN go install github.com/anchore/syft/cmd/syft@${SYFT_VERSION}
RUN go install github.com/zricethezav/gitleaks/v8@${GITLEAKS_VERSION}
RUN go install github.com/sigstore/cosign/v2/cmd/cosign@${COSIGN_VERSION}
RUN go install github.com/google/go-containerregistry/cmd/crane@${CRANE_VERSION}
RUN go install gitlab.com/gitlab-org/release-cli/cmd/release-cli@${RELEASE_CLI_VERSION}
RUN go install github.com/gatecheckdev/gatecheck/cmd/gatecheck@${GATECHECK_VERSION}

# Add the dependencies for the final image
FROM alpine:latest as add-deps

RUN apk --no-cache add curl jq sqlite-libs git

# Final Image
FROM add-deps 

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

COPY --from=build /go/bin/grype /usr/local/bin/grype
COPY --from=build /go/bin/syft /usr/local/bin/syft
COPY --from=build /go/bin/gitleaks /usr/local/bin/gitleaks
COPY --from=build /go/bin/cosign /usr/local/bin/cosign
COPY --from=build /go/bin/crane /usr/local/bin/crane
COPY --from=build /go/bin/release-cli /usr/local/bin/release-cli
COPY --from=build /go/bin/gatecheck /usr/local/bin/gatecheck

USER omnibus

LABEL org.opencontainers.image.title="omnibus"
LABEL org.opencontainers.image.description="A collection of CI/CD tools for batCAVE"
LABEL org.opencontainers.image.vendor="nightwing"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL io.artifacthub.package.readme-url="https://code.batcave.internal.cms.gov/devops-pipelines/pipeline-tools/omnibus/-/blob/main/README.md"
LABEL io.artifacthub.package.license="Apache-2.0"
