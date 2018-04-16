# HTTPS with Let's Encrypt

The following section describes how to configure HTTPS for the [traefik reverse proxy](http://traefik.io) installed as part of our [setup guide](./SETUP.md).

In order to configure HTTPS for traefik, you'll need a server environment as described in the [setup guide](./SETUP.md).
Traefik.io uses the _Automatic Certificate Management Environment (ACME)_ protocol which is a communications protocol for automating interactions between certificate authorities and a web server. ACME allows the automated deployment of public key infrastructure. 

## Setup: Traefik Docker Container

You'll need a web domain configured accordingly by DNS pointing to the docker swarm manager node. 
Docker containers can only communicate with each other over TCP when they share at least one network. We have already defined a proxy network named '_imixs-proxy-net_' and also the traefik configuration folder /management/traefik/. 

In the configuration directory of traefik you now need the new sub directory acme/ and a new empty file 'acme.json'

	$ mkdir -p management/traefik/acme
	$ touch management/traefik/acme/acme.json 
	$ chmod 600 management/traefik/acme/acme.json
	
The already existing docker-compose.yml file need to be extended with the SSL Port 443 and the mounted acme/ directory:

	version: '3'
	
	services:
	  app:
	     image: traefik:v1.5.4
	     volumes:
	       - /var/run/docker.sock:/var/run/docker.sock
	       - $PWD/management/traefik/traefik.toml:/etc/traefik/traefik.toml
	       - $PWD/management/traefik/acme:/etc/traefik/acme
	     ports:
	       - 80:80
	       - 443:443
	       - 8100:8080
	     deploy:
	       placement:
	         constraints:
	           - node.role == manager
	     
	networks:
	   default:
	    external:
	      name:  imixs-proxy-net

The main part of the HTTPS configuration is done by the traefik.toml file. 
 
## Setup: Traefik Configuration - traefik.toml

In the traefik.toml file some changes to the default setup are necessary in order to configure HTTPS.

The defaultEntryPoins must be extended with the https protocol: 

	defaultEntryPoints = ["https","http"]

Also a new entrypoint for https need to be defined:

	[entryPoints]
	    [entryPoints.http]
	    address = ":80"
	    [entryPoints.https]
	    address = ":443"
	    [entryPoints.https.tls]   
    
In case you want to redirect the http entrypoint to the https entrypoint, the entryPoints can be configured with an additional entryPoints.http.redirect : 

	[entryPoints]
	  [entryPoints.http]
	  address = ":80"
	    [entryPoints.http.redirect]
	    entryPoint = "https"
	  [entryPoints.https]
	  address = ":443"
	  [entryPoints.https.tls]
	
	[retry]



The Automated Certificate Management Environment (acme) configuration can be added at the end of the traefik.toml file:


	[acme]
	email = "your-email-here@my-awesome-app.org"
	storage = "/etc/traefik/acme/acme.json"
	entryPoint = "https"
	OnHostRule = true
	[acme.httpChallenge]
	entryPoint = "http"




## Verifiying Certificates

You can get a list of certificates issued for your registered domain by [searching on crt.sh](https://crt.sh/), which uses the public [Certificate Transparency](https://www.certificate-transparency.org/) logs.



