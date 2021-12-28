FROM registry.access.redhat.com/ubi7/s2i-base

LABEL maintainer="Anaconda, Inc."

ARG CONDA_VERSION=py39_4.10.3
ARG ANACONDA_PROJECT_VERSION=0.10.2

LABEL io.k8s.description="Run Anaconda Project commands" \
      io.k8s.display-name="Anaconda Project ${ANACONDA_PROJECT_VERSION}" \
      io.openshift.expose-services="8086:http" \
      io.openshift.tags="builder,anaconda-project,conda" 

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    PATH=/opt/conda/bin:$PATH 

### Install and configure miniconda
COPY ./etc/condarc /opt/conda/.condarc
RUN yum install -y wget bzip2 \
    && UNAME_M="$(uname -m)" \
    && wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-${UNAME_M}.sh -O miniconda.sh \
    && bash miniconda.sh -u -b -p /opt/conda \
    && conda install anaconda-project=${ANACONDA_PROJECT_VERSION} anaconda-client conda-repo-cli conda-token tini --yes \
    && conda clean --all --yes \
    && rm -f miniconda.sh \
    && chmod -R 755 /opt/conda

COPY ./s2i/bin/ /usr/libexec/s2i

RUN chown -R 1001:1001 /opt/app-root

USER 1001

##########################################
## Authenticate to your repo with
## conda-token, anaconda-client,
## or conda-repo-cli by calling one of
## these tools here. This will configure
## access to the repo in the base image.

EXPOSE 8086

ENTRYPOINT ["tini", "-g", "--"]

CMD ["/usr/libexec/s2i/usage"]
