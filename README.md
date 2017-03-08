docker-devpi
============

This repository contains a Dockerfile for [devpi pypi server](http://doc.devpi.net/latest/).

You can use this container to speed up the `pip install` parts of your docker
builds. This is done by adding an optional cache of your requirement python
packages and speed up docker. The outcome is faster development without
breaking builds.

Getting started
---------------

Build the docker image with:

```bash
docker build -t devpi .
```
    

or specify a devpi version as well as a proxy set with:

```bash
docker build -t devpi \
    --build-arg DEVPI_VERSION=2.2 \
    --build-arg http_proxy="http://proxy.mobile.rz:3128" \
    --build-arg https_proxy="http://proxy.mobile.rz:3128" .
```


Now run the docker container from the image with:

```bash
docker run --name devpi -i -t --publish 3141:3141 \
    --volume /srv/docker/devpi:/data --restart always \
    --env=DEVPI_PASSWORD=changemetoyourlongsecret devpi
```

or with proxy settings:

```bash
docker run --name devpi -i -t --publish 3141:3141 \
    --volume /srv/docker/devpi:/data --restart always \
    --env=DEVPI_PASSWORD=changemetoyourlongsecret \
    --env="http_proxy=http://proxy.mobile.rz:3128" \
    --env="https_proxy=http://proxy.mobile.rz:3128" \
    --env="no_proxy=127.0.0.1,localhost" \
    devpi
```

Please set `DEVPI_PASSWORD` to a secret otherwise an attacker can *execute arbitrary code*.

Client side usage
-----------------

### Local

In order to use the devpi cache create a file `~/.pip/pip.conf` containing::

```ini
# $HOME/.pip/pip.conf
[global]
index-url = http://localhost:3141/root/pypi/+simple/

[search]
index = http://localhost:3141/root/pypi/
```
Having set this further usages of `pip` will automatically use the devpi server.

### Web

Since devpi-web is also installed, any browser can be directed to `http://localhost:3141`
in order to have a nice web interface.

### Docker

To use this devpi cache to speed up your dockerfile builds, add the code below
in your dockerfiles. This will add the devpi container an optional cache for
pip. The docker containers will try using port 3141 on the docker host first
and fall back on the normal pypi servers without breaking the build by adding
to the Dockerfile::

```dockerfile
# Install netcat for ip route
RUN apt-get update \
 && apt-get install -y netcat \
 && rm -rf /var/lib/apt/lists/*

 # Use an optional pip cache to speed development
RUN export HOST_IP=$(ip route| awk '/^default/ {print $3}') \
 && mkdir -p ~/.pip \
 && echo [global] >> ~/.pip/pip.conf \
 && echo extra-index-url = http://$HOST_IP:3141/app/dev/+simple >> ~/.pip/pip.conf \
 && echo [install] >> ~/.pip/pip.conf \
 && echo trusted-host = $HOST_IP >> ~/.pip/pip.conf \
 && cat ~/.pip/pip.conf
```

Uploading python packages files
-------------------------------

You need to upload your python requirement to get any benefit from the devpi
container. You can upload them using the bash code below a similar build
environment.

```bash
pip wheel --download=packages --wheel-dir=wheelhouse -r requirements.txt
pip install "devpi-client>=2.3.0" \
&& export HOST_IP=$(ip route| awk '/^default/ {print $3}') \
&& if devpi use http://$HOST_IP:3141>/dev/null; then \
       devpi use http://$HOST_IP:3141/root/public --set-cfg \
    && devpi login root --password=$DEVPI_PASSWORD  \
    && devpi upload --from-dir --formats=* ./wheelhouse ./packages; \
else \
    echo "No started devpi container found at http://$HOST_IP:3141"; \
fi
```

Persistence
-----------

For devpi to preserve its state across container shutdown and startup you
should mount a volume at `/data`. The `docker run` command above already includes this.

Security
--------

Devpi creates a user named root by default, its password should be set with
`DEVPI_PASSWORD` environment variable. Please set it, otherwise attackers can
*execute arbitrary code* in your application by uploading modified packages.

For additional security the argument `--restrict-modify root` has been added so
only the root may create users and indexes.
