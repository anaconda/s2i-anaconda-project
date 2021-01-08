FROM openshift/base-centos7

LABEL maintainer="Anaconda, Inc."

ENV CONDA_VERSION=4.9.2
ENV ANACONDA_PROJECT_VERSION=0.8.4

LABEL io.k8s.description="Run Anaconda Project commands" \
      io.k8s.display-name="Anaconda Project 0.8.4" \
      io.openshift.expose-services="8086:http" \
      io.openshift.tags="builder,anaconda-project,conda" 

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    PATH=/opt/conda/bin:$PATH 

### Install and configure miniconda
ADD https://repo.anaconda.com/miniconda/Miniconda3-py37_4.9.2-Linux-x86_64.sh miniconda.sh
RUN yum install -y bzip2 && \
    bash miniconda.sh -u -b -p /opt/conda && \
    rm -f miniconda.sh && \
    chmod -R 755 /opt/conda
COPY ./etc/condarc /opt/conda/.condarc

### Add required packages
RUN conda install anaconda-project=0.8.4 anaconda-client conda-repo-cli conda-token --yes && \
    conda clean --all --yes

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

CMD ["/usr/libexec/s2i/usage"]
