FROM alpine:3.15.0 as alpine-glibc

LABEL maintainer="Vlad Frolov"
LABEL src=https://github.com/frol/docker-alpine-glibc
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

ENV ALPINE_GLIBC_PACKAGE_VERSION="2.32-r0"

# hadolint ignore=DL3018
RUN UNAME_M="$(uname -m)" && \
    if [ "${UNAME_M}" = "x86_64" ]; then \
        ARCH="x86_64"; \
        GH_ACCT="sgerrand"; \
        SUFFIX=""; \
    elif [ "${UNAME_M}" = "aarch64" ]; then \
        ARCH="arm64"; \
        GH_ACCT="ljfranklin"; \
        SUFFIX="-${ARCH}"; \
    fi && \
    ALPINE_GLIBC_BASE_URL="https://github.com/${GH_ACCT}/alpine-pkg-glibc/releases/download" && \
    echo $ALPINE_GLIBC_BASE_URL && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add -q --no-cache --virtual=.build-dependencies wget ca-certificates && \
    wget -q \
        "$ALPINE_GLIBC_BASE_URL/${ALPINE_GLIBC_PACKAGE_VERSION}${SUFFIX}/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/${ALPINE_GLIBC_PACKAGE_VERSION}${SUFFIX}/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/${ALPINE_GLIBC_PACKAGE_VERSION}${SUFFIX}/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk --allow-untrusted add -q --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    \
    apk del -q glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del -q .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"


FROM alpine-glibc

LABEL maintainer="Anaconda, Inc."

ARG CONDA_VERSION=py39_4.10.3
ARG ANACONDA_PROJECT_VERSION=0.11.1

LABEL io.k8s.description="Run Anaconda Project commands" \
      io.k8s.display-name="Anaconda Project ${ANACONDA_PROJECT_VERSION}" \
      io.openshift.expose-services="8086:http" \
      io.openshift.tags="builder,anaconda-project,conda" \
      io.openshift.s2i.scripts-url=image:///usr/libexec/s2i

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV PATH=/opt/conda/bin:$PATH 
ENV PYTHONDONTWRITEBYTECODE=1
ENV HOME=/opt/app-root/src
ENV TZ=US/Central
ENV PIP_NO_CACHE_DIR=1

### Set timezone
RUN apk add --no-cache tzdata \
    && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone

### Install and configure miniconda
COPY ./etc/condarc /opt/conda/.condarc
RUN apk add --no-cache --virtual wget tar bash curl \
    && UNAME_M="$(uname -m)" \
    && wget "https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-${UNAME_M}.sh" -O miniconda.sh -q \
    && sh miniconda.sh -u -b -p /opt/conda \
    && rm -f miniconda.sh \
    && ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && conda install anaconda-project=${ANACONDA_PROJECT_VERSION} anaconda-client conda-repo-cli conda-token conda-forge::tini --yes \
    && conda clean --all --yes \
    && chmod -R 755 /opt/conda

### AWS Lambda Runtime Emulator
ADD https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie /opt/aws/
RUN chmod +x /opt/aws/aws-lambda-rie

COPY ./entrypoints/ /
COPY ./s2i/bin/ /usr/libexec/s2i

RUN mkdir -p /opt/app-root && \
    chown -R 1001:1001 /opt/app-root

USER 1001

##########################################
## Authenticate to your repo with
## conda-token, anaconda-client,
## or conda-repo-cli by calling one of
## these tools here. This will configure
## access to the repo in the base image.

EXPOSE 8086

WORKDIR $HOME

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/usr/libexec/s2i/usage"]
