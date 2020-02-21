# Anaconda Project builder image

Build docker images from Anaconda Project directories.

## Usage

1. Install source-to-image
1. Clone this repo and build
```
git clone https://github.com/Anaconda-Platform/s2i-anaconda-project
cd s2i-anaconda-project
make
```
1. Build your own docker image from an Anaconda Project directory
```
s2i build <path-to-project or URL> anaconda-project-centos7 <image-name> -e CMD=<project-command>
```
    * `<image-name>` is the desired Docker image name.
    * `<project-command>` is the anaconda-project command to run when `docker run` is executed.
1. Run the docker image
```
docker run -p 8086:8086 <image-name>
```
