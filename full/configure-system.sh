#!/bin/sh

# Configure system to use the local devpi server.

devpi use http://localhost:4040

devpi login root --password ''
devpi user -m root password=root

devpi index -c myindex bases=root/pypi volatile=True

devpi use root/myindex --set-cfg

cat<<EOF > ~/.pypirc
[distutils]
index-servers =
    devpi

[devpi]
username = root
password = root
repository = http://<devpi_loadbalancer>/root/myindex/
EOF
