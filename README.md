# Anaconda Project builder image

Build docker images from Anaconda Project directories.

## Usage

1. Install [source-to-image](https://github.com/openshift/source-to-image#installation)
2. Clone this repo and build
```
git clone https://github.com/Anaconda-Platform/s2i-anaconda-project
cd s2i-anaconda-project
make
```

3. Build your own docker image from an Anaconda Project directory

```
s2i build <path-to-project or URL> anaconda-project-ubi7 <image-name> -e CMD=<project-command>
```

* `<image-name>` is the desired Docker image name.
* `<project-command>` is the anaconda-project command to run when `docker run` is executed.

4. Run the docker image
```
docker run -p 8086:8086 <image-name>
```
