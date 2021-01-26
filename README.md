<div align="center">

# docker-ocserv

![GitHub](https://img.shields.io/github/license/pezhvak/docker-ocserv)
![Docker Image Size (tag)](https://img.shields.io/docker/image-size/pezhvak/ocserv/latest)
![Docker Image Version (latest semver)](https://img.shields.io/docker/v/pezhvak/ocserv)
![Docker Cloud Automated build](https://img.shields.io/docker/cloud/automated/pezhvak/ocserv)
![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/pezhvak/ocserv)

</div>

## About

A lightweight Alpine based ocserv Docker image.

You can either start by using the [pre-built image](#using-built-image)
or [build your own](#build-your-own-image) for more customization.

### Table of Contents

- [Installation](#installation)
    - [Using Built Image](#using-built-image)
        - [Versioning](#versioning)
        - [Generate SSL Certificate](#step-1-generate-ssl-certificate)
        - [Running Container](#step-2-running-your-container)
            - [Using Docker Compose](#option-1-docker-compose-recommended)
            - [Using Docker Run](#option-2-docker-run-command)
    - [Build your own image](#build-your-own-image)
    - [Updating](#updating)
- [Usage](#usage)
    - [User Management](#user-management)
        - [Creating a new user](#create-a-new-user)
        - [Deleting a user](#delete-a-user)
        - [Locking a user](#lock-a-user)
        - [Unlocking a user](#unlock-a-user)
    - [Connecting To Server](#connecting-to-server)
        - [Using Terminal](#using-terminal)
        - [Using Clients](#using-clients)
- [References](#references)

# Installation

## Using Built Image

A [pre-built image](https://hub.docker.com/r/pezhvak/ocserv) is available with the best configurations out of the box.
Follow the instructions bellow to get up and running.

#### This setup includes:

- 2 Device connections for each user (`max-same-clients=2`)
- Up to 16 clients (`max-clients=16`)
- 10.10.10.0/24 as the internal IP pool
- Listens on port 1342 (can be changed by altering port mappings when you run the container)
- Tunnels DNS to the server (`tunnel-all-dns=true`)
- No-Route list configured by [CNMan/ocserv-cn-no-route](https://github.com/CNMan/ocserv-cn-no-route)

***Note:*** All limits can be increased or set to be unlimited in `ocserv.conf`
by [building your own image](#build-your-own-image).

### Versioning
By default `docker-compose.yml` and the instructions written in this document uses the `latest`
tag of the image which represents the latest commit in the `master` branch. beside that tagged commits
are also available if you want to make sure no breaking changes enters your setup, for that checkout 
[tags](https://hub.docker.com/repository/docker/pezhvak/ocserv/tags) in our docker hub repo.

However, if you like to get the cutting edge features you can always use the `next` tag
which represents the latest commit in the `develop` branch.

### STEP 1: Generate SSL Certificate

No matter what, if you want to build the image yourself, run the pre-built one with `docker run` or
with `docker-compose`, in all cases you will need an SSL certificate, It's up to you how you would like to generate it,
perhaps you already have some kind of setup for that on your server, in case you don't, use the
following [image](https://hub.docker.com/r/certbot/certbot/) to generate one:

***Note:*** You need to have a domain pointing to your server IP address and ports 80 and 443 available to be listened
by the container for letsencrypt ACME challenge verification.

```BASH
sudo docker run -it --rm --name certbot -p 80:80 -p 443:443 \
    -v $(pwd)/certs:/etc/letsencrypt certbot/certbot \
    certonly --standalone -m <email> -d <domain> -n --agree-tos
```

can't create one (most often because ports 80 and 443 are not available on your server, or you don't have a domain), a
fallback script will generate a self-signed certificate for you inside the container. The only difference is a warning
message about the certificate not being trusted (due to being self-signed) when logging in.

### STEP 2: Running Your Container

Now that we are done with the certificate, you have to run the container somehow.

***NOTE:*** If you haven't generated a certificate in the previous step, remove volume mountings to cert paths in your
chosen method. as stated previously a self-signed certificate will be generated automatically with the downside of
untrusted certificate warning at the logging phase.

#### OPTION 1: Docker Compose (Recommended)

I highly recommend you to use docker-compose for running your container, feel free to change the port by
editing `docer-compose.yml`. I highly recommend using docker-compose for running your container, feel free to change the
port by editing `docker-compose.yml`.

```BASH
wget https://raw.githubusercontent.com/Pezhvak/docker-ocserv/develop/docker-compose.yml
# IMPORTANT: Make sure you have updated the cert paths in volumes section 
# of the docker-compose.yml before running it.
docker-compose up -d
```

#### OPTION 2: Docker Run Command

If you prefer to use `docker run` all you have to do is to execute the following command:

```BASH
docker run \
    --name ocserv \
    --restart=always \
    -p 1342:443 \
    -v $(pwd)/data/ocserv:/etc/ocserv/data \
    -v $(pwd)/certs/live/<domain>/fullchain.pem:/etc/ocserv/server-cert.pem \
    -v $(pwd)/certs/live/<domain>/privkey.pem:/etc/ocserv/server-key.pem \
    pezhvak/ocserv 
```

Your ocserv should be up and running now, you will have to create a user to be able to connect.

### Updating

To update to the latest version, simply just pull the image from docker hub.

#### For Docker Compose Installations

```BASH
# this will pull the image from docker hub
docker-compose pull
# running up again will detect the newer image and recreates the container 
docker-compose up -d
```

#### For Docker Run Installations
```BASH
# pull image from docker hub
docker pull pezhvak/ocserv
# restart the container
docker restart ocserv
```

## Build Your Own Image
Although it's easier to use [pre-built image](https://hub.docker.com/r/pezhvak/ocserv),
but it has its own downsides. namely, the limitations described [here](#this-setup-includes).

If you want to change the default configurations, you will have to build the image yourself, just clone the repo and
change the files you need.

Configuration files are stored in `config` directory. you can also modify
`scripts/docker-entrypoint.sh` if needed.


1- Clone the repository to your server:

```BASH
git clone https://github.com/Pezhvak/docker-ocserv.git
cd docker-ocserv
```

2- Build the image with your own settings, feel free to change `config/ocserv.conf` to your liking:

```BASH
docker build -t <image_name> .
```

3- Follow the steps of [Using Built Image](#using-built-image) (Change `pezhvak/ocserv` to your own image name)

# Usage

## User Management

I have created a simple proxy shell (`ocuser`) in the image for easier interaction with `ocpasswd`.

### Create a new user

Remove the specified user to the password file (Password of the user will be asked)

```BASH
docker exec -it ocserv ash -c "ocuser create <username>"
```

### Delete a User

Remove the specified user from the password file:

```BASH
docker exec ocserv ash -c "ocuser delete <username>"
```

### Lock a User

Prevent the specified user from logging in:

```BASH
docker exec ocserv ash -c "ocuser lock <username>"
```

### Unlock a User

Re-enable login for the specified user

```BASH
docker exec ocserv ash -c "ocuser unlock <username>"
```

## Connecting to Server

Now that everything is set up and user is created, you can connect to server using terminal or one of the available
applications:

### Using Terminal

Make sure you have installed `openconnect` on your machine, you can do that in MacOS using `brew install openconnect`.

```BASH
echo "<PASSWORD>" | sudo openconnect <DOMAIN>:<PORT> -u <USERNAME> --passwd-on-stdin
```

You can also create an alias in your `~/.bash_profile` (or `~/.zshrc` if you're using zsh) for easier access:

```BASH
alias vpn:oc="echo <PASSWORD> | sudo openconnect <DOMAIN>:<PORT> -u <USERNAME> --passwd-on-stdin"
```

### Using Clients

- [Android (Cisco Anyconnect)](https://play.google.com/store/apps/details?id=com.cisco.anyconnect.vpn.android.avf)
- [Android (OpenConnect)](https://play.google.com/store/apps/details?id=com.github.digitalsoftwaresolutions.openconnect)
- [iOS](https://apps.apple.com/us/app/cisco-anyconnect/id1135064690)
- [MacOS](https://www.cisco.com/c/en/us/support/docs/smb/routers/cisco-rv-series-small-business-routers/smb5642-install-cisco-anyconnect-secure-mobility-client-on-a-mac-com-rev1.html)
- [Windows](https://www.cisco.com/c/en/us/support/docs/smb/routers/cisco-rv-series-small-business-routers/smb5686-install-cisco-anyconnect-secure-mobility-client-on-a-windows.html)
- [Ubuntu](https://www.cisco.com/c/en/us/support/docs/smb/routers/cisco-rv-series-small-business-routers/Kmgmt-785-AnyConnect-Linux-Ubuntu.html)

# References

I appreciate these repositories which inspired me and helped me to put the pieces together:

- [soreana/cisco-anyconnect-server-docker](https://github.com/soreana/cisco-anyconnect-server-docker)
- [TommyLau/docker-ocserv](https://github.com/TommyLau/docker-ocserv)
