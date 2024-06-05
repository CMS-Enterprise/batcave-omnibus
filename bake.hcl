target "default" {
  dockerfile = "Dockerfile"
  tags = [
      "ghcr.io/cms-enterprise/batcave/omnibus:latest",
      ]
  context = "."
  platforms = ["linux/amd64"]
}

target "arm" {
    dockerfile = "Dockerfile"
    tags = [
        "omnibus:latest",
        ]
    context = "."
    platforms = ["linux/arm64"]
}
