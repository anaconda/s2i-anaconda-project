# anaconda-project-centos7
FROM openshift/base-centos7

# TODO: Put the maintainer name in the image metadata
LABEL maintainer="Anaconda, Inc."

# TODO: Rename the builder environment variable to inform users about application you provide them
ENV CONDA_VERSION=4.7.12.1
ENV ANACONDA_PROJECT_VERSION=0.8.4

# Set labels used in OpenShift to describe the builder images
LABEL io.k8s.description="Run Anaconda Project commands" \
      io.k8s.display-name="Anaconda Project 0.8.4" \
      io.openshift.expose-services="8086:http" \
      io.openshift.tags="builder,anaconda-project,conda" 

ADD https://repo.anaconda.com/miniconda/Miniconda3-4.7.12.1-Linux-x86_64.sh miniconda.sh

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    PATH=/opt/conda/bin:$PATH 

COPY ./etc/condarc .

RUN yum install -y bzip2 && \
    bash miniconda.sh -b -p /opt/conda && \
    conda config --set auto_update_conda False --set notify_outdated_conda false --system && \
    cp condarc /opt/conda/.condarc && \
    conda install -c defusco anaconda-project=0.8.4+59 --yes && \
    conda clean --all --yes && \
    rm -f condarc miniconda.sh && \
    chmod -R 755 /opt/conda

# TODO (optional): Copy the builder files into /opt/app-root
# COPY ./<builder_folder>/ /opt/app-root/

# TODO: Copy the S2I scripts to /usr/libexec/s2i, since openshift/base-centos7 image
# sets io.openshift.s2i.scripts-url label that way, or update that label
COPY ./s2i/bin/ /usr/libexec/s2i

# TODO: Drop the root user and make the content of /opt/app-root owned by user 1001
RUN chown -R 1001:1001 /opt/app-root

# This default user is created in the openshift/base-centos7 image
USER 1001

# TODO: Set the default port for applications built using this image
EXPOSE 8086

# TODO: Set the default CMD for the image
CMD ["/usr/libexec/s2i/usage"]
