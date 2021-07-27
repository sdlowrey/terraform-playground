FROM alpine:3.14

ENV TERRAFORM_VERSION=1.0.3
ENV TERRAFORM_SHA256SUM=99c4866ffc4d3a749671b1f74d37f907eda1d67d7fc29ed5485aeff592980644

RUN apk add --update git curl openssh openssl python3 py-pip bash jq && \
    curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip > terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    echo "${TERRAFORM_SHA256SUM}  terraform_${TERRAFORM_VERSION}_linux_amd64.zip" > terraform_${TERRAFORM_VERSION}_SHA256SUMS && \
    sha256sum -cs terraform_${TERRAFORM_VERSION}_SHA256SUMS && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /bin && \
    rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip

RUN pip install --upgrade pip awscli

WORKDIR /terraform
COPY ./ .