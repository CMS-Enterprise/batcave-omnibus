builder_cmd := "docker"

publish-image tag:
	just build-image {{tag}} && just push-image {{tag}}

build-image tag:
	{{builder_cmd}} build -t artifactory.cloud.cms.gov/batcave-docker/devops-pipelines/pipeline-tools/omnibus:{{tag}} .

push-image tag:
	{{builder_cmd}} push artifactory.cloud.cms.gov/batcave-docker/devops-pipelines/pipeline-tools/omnibus:{{tag}}

