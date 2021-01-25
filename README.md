# docker-ocserv
Alpine based ocserv docker image


# Using Built Image
A pre-built image is available with the best configurations out of the box. Follow the instructions bellow to get up and running.

## STEP 1: Generate SSL Certificate
No matter what, if you wan to build the image yourself, run the prebuilt one with docker or with docker-compose, in all cases you will need
an SSL certificate, It's up to you how you would like to create it, perhaps you already have some kind of setup for SSL generation on your server,
in case you don't, use the following command to generate one:

***Note: You need to have a domain pointing to your server IP address and ports 80 and 443 available to be listened by the container for
letsencrypt ACME challenge verification***

```BASH
sudo docker run -it --rm --name certbot -p 80:80 -p 443:443 \
    -v $(pwd)/certs:/etc/letsencrypt certbot/certbot \
    certonly --standalone -m <email> -d <domain> -n --agree-tos
```

## STEP 2: Running Your Container
Now that you have your certificate generated, you have to run run your container somehow.

### OPTION 1: Docker Compose (Recommended)

I highly recommend you to use docker-compose for running your container, feel free to change the port by editing `docer-compose.yml`.

```BASH
wget https://raw.githubusercontent.com/Pezhvak/docker-ocserv/develop/docker-compose.yml
docker-compose up -d
```

### OPTION 2: Docker Command
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

Your ocserv should be up and running now, you will have to create a user to be able to connnect.

## User Creation
For each user you want to add, all you need to do is to run the following command:

```BASH
docker exec ocserv ocpasswd -c /etc/ocserv/ocpasswd <username>
```

# Build Your Own Image
If you want to change the default configurations, you will have to build the image yourself, just clone the repo and change the files you need.

1- Clone the repository to your server:
```BASH
git clone https://github.com/Pezhvak/docker-ocserv.git
cd docker-ocserv
```

2- Build the image with your own settings, feel free to change `ocserv.conf` to your liking:
```BASH
docker build -t myocserv:latest .
```

3- Follow the steps of [Using Built Image](#using-built-image)
