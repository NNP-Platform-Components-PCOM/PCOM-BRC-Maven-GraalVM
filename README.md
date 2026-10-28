# PCOM - BRC - Maven GraalVM

**Base Runtime Component: Maven GraalVM** — Maven 3.9.11 on the
[`PCOM-BRC-GraalVM`](https://github.com/NNP-Platform-Components-PCOM/PCOM-BRC-GraalVM)
JDK 21 image, for the Nubo Native Platform (NNP). It is a **build** image: CI
uses it to compile and package Java applications with the same JDK that runs
them. It is not meant to be deployed.

## Image

Published to Docker Hub on every push to `main`:

```
docker.io/nubonativesolution/pcom-brc-maven-graalvm:3.9.11-graalvm21-v1
docker.io/nubonativesolution/pcom-brc-maven-graalvm:latest
```

Architecture: `linux/amd64`.

## Contents

- GraalVM Community JDK 21 (from `pcom-brc-graalvm:21`)
- Apache Maven 3.9.11, installed from the Apache distribution with its SHA-512
  checksum verified
- `git`
- Unprivileged `appuser`; working directory `/data`

## Use in a pipeline

```yaml
maven-build:
  image: docker.io/nubonativesolution/pcom-brc-maven-graalvm:3.9.11-graalvm21-v1
  script:
    - mvn --batch-mode package
```

Then build the runtime image `FROM docker.io/nubonativesolution/pcom-brc-graalvm:21`
and copy the packaged jar into it.

## Build locally

```bash
docker build -t pcom-brc-maven-graalvm:3.9.11-graalvm21-v1 .

# Different Maven version or base:
docker build \
  --build-arg MAVEN_VERSION=3.9.11 \
  --build-arg base_version=21 \
  -t pcom-brc-maven-graalvm:3.9.11-graalvm21-v1 .
```

## CI/CD

`.github/workflows/build.yml` is a thin caller for the shared
[`PCOM-CICD`](https://github.com/NNP-Platform-Components-PCOM/PCOM-CICD)
reusable pipeline: build with Buildx, publish with SBOM + provenance, sign with
**cosign keyless** (OIDC), and scan with Trivy and Grype (results in the
**Security** tab). Pull requests build and scan without publishing. The image is
rebuilt weekly to pick up base security updates.

## License

Apache-2.0 for the packaging in this repository.
