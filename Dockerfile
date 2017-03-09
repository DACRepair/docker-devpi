# devpi docker image
FROM ubuntu:latest
MAINTAINER https://github.com/florianwilhelm/

ARG DEVPI_VERSION

ENV PIP_NO_CACHE_DIR="off"
ENV PIP_INDEX_URL="https://pypi.python.org/simple"
ENV PIP_TRUSTED_HOST="127.0.0.1"
ENV VIRTUAL_ENV /env

# create devpi user and group
RUN adduser --uid 1000 --home /data --disabled-password --disabled-login --system --group devpi

# entrypoint is written in bash
RUN apt-get update && apt-get install -y build-essential python3-pip

# create a virtual env in $VIRTUAL_ENV, ensure it respects pip version
RUN pip3 install virtualenv \
    && virtualenv $VIRTUAL_ENV \
    && $VIRTUAL_ENV/bin/pip3 install pip
ENV PATH $VIRTUAL_ENV/bin:$PATH

RUN if [ -n "${DEVPI_VERSION}" ]; then pip3 install "devpi==${DEVPI_VERSION}"; else pip3 install devpi; fi

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 3141
VOLUME /data

USER devpi
ENV HOME /data
WORKDIR /data

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["devpi"]
