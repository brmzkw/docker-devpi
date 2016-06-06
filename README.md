This [docker-compose] [compose] file can be used to create your local Pypi
mirror using [devpi] [devpi].

It can be used to have a local cache of [pypi.python.org] and to push your
private packages.

**As stated in the [documentation] [devpi security], it is not safe to expose
devpi-server to the internet. Use it in your local, trusted network.**


[compose]: http://doc.devpi.net/latest/
[devpi]: http://doc.devpi.net/latest/
[pypi]: http://pypi.python.org
[devpi security]: http://doc.devpi.net/latest/adminman/security.html


Setup
=====

We assume docker-compose is installed and up to date.

Create the Docker volume which will contain your packages:

```bash
$> docker volume create --name=devpi_packages
```

Build and launch the containers:

```bash
$> docker-compose build
$> docker-compose up -d
```

You can check the containers are correctly started:

```bash
$> docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                  PORTS               NAMES
e3bc0fcc741b        devpi_lb            "nginx -g 'daemon off"   1 seconds ago       Up 1 seconds            80/tcp, 443/tcp     devpi_lb
38f2f5fe6d2e        devpi_server        "/bin/sh -c 'devpi-se"   1 seconds ago       Up 1 seconds            4040/tcp            devpi_server
```

To get the load balancer IP address, execute `docker inspect --format '{{
.NetworkSettings.Networks.devpi_default.IPAddress }}' devpi_lb`. The web
interface is available at `http://<devpi_loadbalancer>`.

If you are using [docker machine] [docker machine] (probably because you're on
OSX), uncomment the `ports` section of
[docker-compose.yml](docker-compose.yml). In this case, the web interface is
available at `http://$(docker-machine ip)`.


[docker machine]: https://docs.docker.com/machine/


Server administration
=====================

Devpi comes with a [client] [devpi client] that can be used to manage your
server, create users, and so on.

This section explains how to:

* Use devpi client.
* Configure the root account.
* Manage users.
* Create a new index to hold your company's private Python packages.
* Give permissions to push packages on your company's index.

[devpi client]: http://doc.devpi.net/latest/userman/devpi_concepts.html#the-devpi-client


### Use devpi-client

Install the client on your local computer:

```bash
### OPTIONAL ###
$> virtualenv my-venv
$> source my-venv/bin/activate
################

$> pip install devpi-client
```

Alternatively, you can administrate your server through a Docker container by
using [client/Dockerfile](client/Dockerfile):

```bash
$> cd client
$> docker build -t devpi-client .
$> docker run --rm -ti devpi-client bash
```

Configure devpi-client to use your server:

```bash
$> devpi use http://<devpi loadbalancer>
```

*Note: this command updates the devpi configuration file located at
`~/.devpi/client/current.json`.*


### Configure the root account

Login as root:

```bash
$> devpi login root --password ''
```

And change the default empty root password:

```bash
$> devpi user -m root password=123
```


### Manage users

*(requires to be logged as root)*

Create a user:

```bash
$> devpi user -c <username> email=email@domain.tld password=1234
```

Get user details:

```bash
$> devpi getjson /<username>
```

Remove user:

```
$> devpi user <username> -y --delete
```


### Create a new index to hold your company's private Python packages

*(requires to be logged as root)*

Create the index:

```bash
$> devpi index -c <company_name> bases=root/pypi volatile=False
```

This index will be used by your users, as explained in the next section, to:

* Download Python packages.
* Push their private packages.

`bases=root/pypi` is used so any unknown package will be downloaded from
[http://pypi.python.org](https://pypi.python.org/pypi).

With `volatile=False`:

* Your index can not be deleted.
* A project created in the index can not be deleted.
* If a project verison is uploaded, it can not be removed or overriden.


The webpage of the index is located at
`http://<devpi_loadbalancer>/root/<company_name>`. You can also use the client:

```bash
$> devpi getjson /root/<username>
```


### Give permissions to push packages on your company's index

*(requires to be logged as root)*

**You can't append a user to the permissions list. Get the list of users who
can upload packages with `devpi index root/<company_name>` before!**

```bash
$> devpi index /root/<company name> acl_upload=<username1>,<username2>,...
```


Using the devpi mirror
======================

### Generate configuration files

To use your devpi server, you need to give some configuration files to Python.
Most of these files can be created with `devpi use root/<company_name>
--set-cfg` when you are logged as your user (with `devpi use
http://<devpi_loadbalancer>` then `devpi login <username>`) but from then, we
will assume you don't have the devpi client as it is not necessary to use the
mirror.

* Create `~/.pydistutils.cfg` with:

```bash
[easy_install]
index_url = http://<devpi_loadbalancer>/root/<company_name>/+simple/
```

This file is used by [distutils](https://docs.python.org/2/distutils/).

* Create `~/.pip/pip.conf` with:

```bash
[global]
index_url = http://<devpi loadbalancer>/root/scaleway/+simple/
[search]
index = http://<devpi loadbalancer>/root/scaleway/
```

This file is used by `pip install` and `pip search`.

* Create `~/.pypirc` with:

```bash
[distutils]
index-servers =
    pypi
    devpi

[pypi]
username = <pypi.python.org username>
password = <pypi.python.org password>
repository = https://pypi.python.org/pypi

[devpi]
username = <devpi username>
password = <devpi password>
# Keep the trailing slash!
repository = http://<devpi_loadbalancer>/root/<company_name>/
```

This file is used to upload packages (as explained below) to your devpi mirror.
The *pypi* section is used to upload packages on
[pypi.python.org](https://pypi.python.org).


### Download packages

If your configuration files are correctly set, you should be able to download packages with:

```bash
$> pip install <package_name> --trusted-host <devpi_loadbalancer>
```

**NOTE**: `--trusted-host` is required because, for now, the docker-compose.yml
doesn't setup SSL for the devpi mirror, which is required by pip.


### Upload packages

When you're in the directory of your `setup.py` file, you first need to
register your package (need to be done only once):

```bash
$> python setup.py register -r devpi
```

Then, you can upload your new version:

```bash
$> python setup.py sdist upload -r devpi
$> python setup.py bdist_egg upload -r devpi
$> python setup.py bidst_wheel upload -r devpi
```
