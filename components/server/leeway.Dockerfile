# Copyright (c) 2020 Gitpod GmbH. All rights reserved.
# Licensed under the GNU Affero General Public License (AGPL).
# See License-AGPL.txt in the project root for license information.

FROM node:16.13.0-slim as builder

RUN apt-get update && apt-get install -y build-essential python3

COPY components-server--app /installer/

WORKDIR /app
RUN /installer/install.sh

FROM docker.branch.io/gitpod-core-dev/build/server:commit-3c79f0c68c9e480f0e8daf65c44a484296161786 as current

FROM node:16.13.0-slim
ENV NODE_OPTIONS="--unhandled-rejections=warn --max_old_space_size=2048"
# Using ssh-keygen for RSA keypair generation
RUN apt-get update && apt-get install -yq \
        openssh-client \
        procps \
        net-tools \
        nano \
        curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

EXPOSE 3000

ENV PATH="/go/bin:${PATH}"

# '--no-log-init': see https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user
RUN useradd --no-log-init --create-home --uid 31001 --home-dir /app/ unode
COPY --from=current /app /app/
COPY --from=builder /app/node_modules/@gitpod/server/dist/src/workspace /app/node_modules/@gitpod/server/dist/src/workspace
USER unode
WORKDIR /app/node_modules/@gitpod/server
# Don't use start-ee-inspect as long as we use native modules (casues segfault)

ARG __GIT_COMMIT
ARG VERSION

ENV GITPOD_BUILD_GIT_COMMIT=${__GIT_COMMIT}
ENV GITPOD_BUILD_VERSION=${VERSION}
CMD exec yarn start-ee
