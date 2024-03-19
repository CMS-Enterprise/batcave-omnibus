# Omnibus

[![Build Omnibus](https://github.com/CMS-Enterprise/batcave-omnibus/actions/workflows/omnibus.yml/badge.svg)](https://github.com/CMS-Enterprise/batcave-omnibus/actions/workflows/omnibus.yml)

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
- [Semgrep](https://github.com/semgrep/semgrep)
- [ClamAV](https://clamav.net)
- [ORAS](https://oras.land)
