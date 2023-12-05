# Omnibus

[![pipeline status](https://code.batcave.internal.cms.gov/devops-pipelines/pipeline-tools/omnibus/badges/main/pipeline.svg)](https://code.batcave.internal.cms.gov/devops-pipelines/pipeline-tools/omnibus/-/commits/main) 
| [![Latest Release](https://code.batcave.internal.cms.gov/devops-pipelines/pipeline-tools/omnibus/-/badges/release.svg)](https://code.batcave.internal.cms.gov/devops-pipelines/pipeline-tools/omnibus/-/releases)

![Omnibus Logo](assets/splash_1_light.png)

## Background

Omnibus is a light-weight utility image built by the Nightwing team as a pipeline optimization.
Since most of the security scanning and utility tools we use in the pipeline are written in Golang,
they can be statically compiled and loaded into a bare-bones container.
This reduces the overhead of maintaining repositories for each tool if there isn't much to the build process.

## Included

The criteria for a tool to be considered for omnibus is as follows:

1. The tool MUST be a command line interface application.
2. The tool MUST be a statically compiled binary
3. The tool MUST not require an additional runtime, (i.e. Python, Java, Node)
4. The tool MUST target Alpine Linux for it's binary

These rules exist to keep the image as small as possible which decreases the amount of time each job takes in the
pipeline.

- [Anchore Grype](https://github.com/anchore/grype)
- [Anchore Syft](https://github.com/anchore/syft)
- [Gitleaks](https://github.com/zricethezav/gitleaks)
- [Cosign](https://github.com/sigstore/cosign)
- [Google Crane](https://github.com/google/go-containerregistry/cmd/crane)
- [GitLab Release CLI](https://gitlab.com/gitlab-org/release-cli/cmd/release-cli)
- [Gatecheck](https://github.com/gatecheckdev/gatecheck)
- [Go S3 Upload](https://github.com/bacchusjackson/go-s3-upload)

## Rejected

## Podman

Rejected: 13 Sept 2023
Reason: violates rule 2 & 4
POC: Bacchus Jackson (bjackson@clarityinnovates.com)

We haven't been able to get a reliable build with podman into an Alpine container as a statically linked binary.
Podman relies on mounting a daemon from outside of the container on the runner which increases the complexity of
the container image.
As of the rejection date, the only reproducible image build was in a RHEL image.

### ClamAV

Rejected: 13 Sept 2023
Reason: violates rule 2
POC: Bacchus Jackson (bjackson@clarityinnovates.com)

As of the rejection date, ClamAV requires a lot of libraries as dependencies, being a C++ application which
would significantly increase the build time for Omnibus.
There have also been several attempts to build it as statically linked binary with little success in
alpine container.
Adding it into Omnibus with all the dependent dynamic libraries would increase the threat vector for the container.

### Semgrep

Rejected: 13 Sept 2023
Reason: violates rule 3
POC: Bacchus Jackson (bjackson@clarityinnovates.com)

Semgrep CLI uses a Python wrapper.
This would require the python runtime, which violates rule 3.

