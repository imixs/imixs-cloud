# How to secure Imixs-Cloud

The following section describes additional security concepts of Imixs-Cloud

## Traefik: Setup Basic Authentication 

The traefik web frontend (8080) is accessabel to anonymous per default. To secure the frontend follow these steps:

**1. Generate a password**

Generate a password with the htpasswd command for the user admin

	$ htpasswd -n admin
	New password: 
	Re-type new password: 
	admin:$apr1$tm23...................9uz570

**2. Update the traefik.toml file**

Copy the result into the traefik.toml file into the section _[web.auth.basic]_

	...
	[web.auth.basic]
	users = ["admin:$apr1$tm23...................9uz570"]
	...

you can add several user entries by comma separated. 

**3. Restart the Treafik Service**

Reload the traefik service from the swarmpit UI.



## Docker Registry: Setup Basic Authentication 

The HTTP Rest API of the docker registry can be secured with [basic authentication](https://docs.docker.com/registry/configuration/#htpasswd) using an Apache htpasswd file. The only supported password format is bcrypt. Entries with other hash types are ignored. The htpasswd file is loaded once, at startup. If the file is invalid, the registry will display an error and will not start.

you can follow these steps:

**1. Generate a password**

Generate a folder _management/registry/_ to store htpasswd file

	$ mkdir -p ./management/registry/auth			   

Create a password file for a user (e.g. admin) 

	$ htpasswd -cB htpasswd admin

To add additional users run	
	
	$ htpasswd -B htpasswd user1

Now copy file or content into ./management/registry/auth
	
	
**2. Update the registry docker-compose.yml file**	
	
Add the following environment entries:

	   ...
	   environment:
	      REGISTRY_HTTP_TLS_CERTIFICATE: /certs/domain.cert 
	      REGISTRY_HTTP_TLS_KEY: /certs/domain.key
	      REGISTRY_AUTH: htpasswd
	      REGISTRY_AUTH_HTPASSWD_REALM: Registry Realm
	      REGISTRY_AUTH_HTPASSWD_PATH: /auth/htpasswd
	   ...
	   volumes:
         - $PWD/management/registry/certs:/certs:ro
         - $PWD/management/registry/auth/passwd:/auth/htpasswd:ro
	   ....

**3. Redeploy the registry**

Finally you can redeploy the registry service from the swarmpit UI.	