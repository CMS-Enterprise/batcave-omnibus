# TODO: clamAV, semgrep

FROM golang:alpine3.18 as build
ARG GRYPE_VERSION=v0.66.0
ARG SYFT_VERSION=v0.89.0
ARG GITLEAKS_VERSION=v8.18.0
ARG COSIGN_VERSION=v2.2.0
ARG CRANE_VERSION=v0.16.1
ARG RELEASE_CLI_VERSION=v0.15.0
ARG GATECHECK_VERSION=v0.2.0

RUN apk --no-cache add ca-certificates git openssh

# Layer on purpose for caching improvements
RUN go install github.com/anchore/grype/cmd/grype@${GRYPE_VERSION}
RUN  go install github.com/anchore/syft/cmd/syft@${SYFT_VERSION}
RUN  go install github.com/zricethezav/gitleaks/v8@${GITLEAKS_VERSION}
RUN  go install github.com/sigstore/cosign/v2/cmd/cosign@${COSIGN_VERSION}
RUN  go install github.com/google/go-containerregistry/cmd/crane@${CRANE_VERSION}
RUN  go install gitlab.com/gitlab-org/release-cli/cmd/release-cli@${RELEASE_CLI_VERSION}
RUN  go install github.com/gatecheckdev/gatecheck/cmd/gatecheck@${GATECHECK_VERSION}

# Add the dependencies for the final image
FROM alpine:3.18.2 as add-deps

RUN apk --no-cache add curl jq sqlite-libs git

# Final Image
FROM add-deps 

COPY --from=build /go/bin/grype /usr/local/bin/grype
COPY --from=build /go/bin/syft /usr/local/bin/syft
COPY --from=build /go/bin/gitleaks /usr/local/bin/gitleaks
COPY --from=build /go/bin/cosign /usr/local/bin/cosign
COPY --from=build /go/bin/crane /usr/local/bin/crane
COPY --from=build /go/bin/release-cli /usr/local/bin/release-cli
COPY --from=build /go/bin/gatecheck /usr/local/bin/gatecheck

