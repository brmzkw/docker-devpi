FROM ubuntu

RUN apt-get update && apt-get install -y \
    python-pip

RUN pip install devpi-server devpi-web

EXPOSE 4040
VOLUME /var/lib/devpi

CMD devpi-server --host 0.0.0.0 --port 4040 --serverdir /var/lib/devpi
