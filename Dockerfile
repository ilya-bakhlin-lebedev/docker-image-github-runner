FROM debian:stable AS main

ARG DEBIAN_FRONTEND="noninteractive"

ARG VERSION_GITHUB_CLI="2.92.0"

RUN apt-get -qqy update && \
    apt-get -qqy upgrade && \
    apt-get -qqy dist-upgrade && \
    apt-get -qqy clean && \
    apt-get -qqy autoclean && \
    apt-get -qqy autoremove && \
    groupadd github && \
    useradd -c "GitHub Runner" -d /home/github/runner -g github -m -s /bin/bash runner && \
    find /home/github/runner/ -type f -delete

FROM main AS wget

RUN apt-get -qqy install unzip wget

FROM wget AS wget-aws-cli

RUN wget -P /tmp/ -q "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" && \
     unzip -d /tmp/ /tmp/awscli-exe-linux-x86_64.zip -x "aws/dist/awscli/examples/*" && \
    /tmp/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws && \
    chmod -v 755 /usr/local/bin/aws

FROM wget AS wget-github-cli

RUN wget -P /tmp/ -q "https://github.com/cli/cli/releases/download/v${VERSION_GITHUB_CLI}/gh_${VERSION_GITHUB_CLI}_linux_amd64.tar.gz" && \
    tar -C /tmp/ -f /tmp/gh_${VERSION_GITHUB_CLI}_linux_amd64.tar.gz -o -v -x -z && \
    mv -v /tmp/gh_${VERSION_GITHUB_CLI}_linux_amd64/bin/gh /usr/local/bin/ && \
    chmod -v 755 /usr/local/bin/gh

FROM wget AS wget-github-actions-runner

RUN wget -P /tmp/ -q "https://github.com/actions/runner/releases/download/v2.334.0/actions-runner-linux-x64-2.334.0.tar.gz" && \
    tar -C /home/github/runner/ --exclude "./externals*" -f /tmp/actions-runner-linux-x64-2.334.0.tar.gz -o -v -x -z

FROM scratch AS export-github-runner

COPY --from=main /etc/ /etc/
COPY --from=wget-aws-cli /usr/local/ /usr/local/
COPY --from=wget-github-actions-runner /home/ /home/
COPY --from=wget-github-cli /usr/local/bin/ /usr/local/bin/

FROM debian:stable AS github-runner

COPY --from=export-github-runner / /
