# How to secure Imixs-Docker-Cloud

The following section describes additional security concepts of Imixs-Cloud

## Traefik

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





