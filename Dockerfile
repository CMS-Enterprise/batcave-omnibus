FROM golang:alpine3.18 as build

ARG GRYPE_VERSION=v0.64.2
ARG SYFT_VERSION=v0.85.0
ARG GITLEAKS_VERSION=v8.17.0
ARG COSIGN_VERSION=v2.1.1
ARG CRANE_VERSION=v0.15.2
ARG RELEASE_CLI_VERSION=v0.15.0

RUN apk --no-cache add ca-certificates git openssh && \
  go install github.com/anchore/grype/cmd/grype@$GRYPE_VERSION && \
  go install github.com/anchore/syft/cmd/syft@$SYFT_VERSION && \
  go install github.com/zricethezav/gitleaks/v8@$GITLEAKS_VERSION && \
  go install github.com/sigstore/cosign/v2/cmd/cosign@$COSIGN_VERSION && \
  go install github.com/google/go-containerregistry/cmd/crane@$CRANE_VERSION && \
  go install gitlab.com/gitlab-org/release-cli/cmd/release-cli@$RELEASE_CLI_VERSION

FROM alpine:3.18.2

COPY --from=build /root/go/bin/grype /usr/local/bin/grype
COPY --from=build /root/go/bin/syft /usr/local/bin/syft
COPY --from=build /root/go/bin/gitleaks /usr/local/bin/gitleaks
COPY --from=build /root/go/bin/cosign /usr/local/bin/cosign
COPY --from=build /root/go/bin/crane /usr/local/bin/crane
COPY --from=build /root/go/bin/release-cli /usr/local/bin/release-cli


