FROM opensuse/tumbleweed:latest
RUN zypper ref && zypper in -y git zip wget docker ruby gzip make jq curl which unzip go
# Extras, mostly for the terminal image (that could be split in another image)
RUN zypper in -y vim zsh tmux glibc-locale glibc-i18ndata python ruby python3 python3-pip
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl
RUN curl -L "https://packages.cloudfoundry.org/stable?release=linux64-binary&source=github" | tar -zx
RUN mv cf /usr/local/bin && chmod +x /usr/local/bin/cf
ADD . /catapult
WORKDIR /catapult
ENTRYPOINT [ "/usr/bin/make" ]
