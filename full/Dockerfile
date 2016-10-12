# devpi-server, devpi-web and devpi-client

FROM ubuntu

RUN apt-get update && apt-get install -y \
    ca-certificates \
    python-setuptools

# Useful packages.
RUN apt-get install -y \
    curl

RUN easy_install pip

RUN pip install devpi-server devpi-web devpi-client

EXPOSE 4040
VOLUME /var/lib/devpi

CMD ["devpi-server", "--host", "0.0.0.0", "--port", "4040", "--serverdir", "/var/lib/devpi"]
