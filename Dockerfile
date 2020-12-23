FROM alpine:3.10 as build
LABEL maintainer="Konkerlabs, Andre Rocha <andre@konkerlabs.com>"

RUN apk add --update --no-cache ca-certificates git

ENV VERSION=v3.0.0
ENV FILENAME=helm-${VERSION}-linux-amd64.tar.gz
ENV SHA256SUM=10e1fdcca263062b1d7b2cb93a924be1ef3dd6c381263d8151dd1a20a3d8c0dc

WORKDIR /

RUN apk add --update -t deps curl tar gzip
RUN curl -L https://get.helm.sh/${FILENAME} > ${FILENAME} && \
    echo "${SHA256SUM}  ${FILENAME}" > helm_${VERSION}_SHA256SUMS && \
    sha256sum -cs helm_${VERSION}_SHA256SUMS && \
    tar zxv -C /tmp -f ${FILENAME} && \
    rm -f ${FILENAME}



FROM alpine:3.8

ARG KUBERNETES_VERSION=1.15.12
ARG AWS_IAM_AUTHENTICATOR_VERSION=0.3.0

RUN apk add --update --no-cache git ca-certificates

COPY --from=build /tmp/linux-amd64/helm /bin/helm

RUN apk add --update --upgrade --no-cache jq bash curl && \
    apk -v --update add \
            python \
            py-pip \
            groff \
            less \
            mailcap \
            && \
            pip install --upgrade awscli==1.16.93 s3cmd==2.0.1 python-magic && \
            apk -v --purge del py-pip && \
            rm /var/cache/apk/* && \
    curl -L -o /usr/local/bin/aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${AWS_IAM_AUTHENTICATOR_VERSION}/heptio-authenticator-aws_${AWS_IAM_AUTHENTICATOR_VERSION}_linux_amd64 && \
    chmod +x /usr/local/bin/aws-iam-authenticator && \
    curl -L -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kubectl; \
    chmod +x /usr/local/bin/kubectl

ADD assets /opt/resource
RUN chmod +x /opt/resource/*

RUN helm plugin install https://github.com/databus23/helm-diff

ENTRYPOINT ["/bin/helm"]
