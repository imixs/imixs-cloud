# How to secure Imixs-Cloud

The following section describes additional security concepts of Imixs-Cloud

## Traefik: Setup Basic Authentication 

The traefik web front-end (8080) is accessible to anonymous per default. To secure the front-end follow these steps:

**1. Generate a password**

To generate a password you can use the commadline tool 'htpasswd' which is part of the apache2-utils. Run the command to generate a password for the user admin:

	htpasswd -n admin
	New password: 
	Re-type new password: 
	admin:$apr1$tm23...................9uz570

**2. Update the traefik.toml file**

Copy the result of the user/password string into the section _[web.auth.basic]_ of the traefik.toml file:

	...
	[web.auth.basic]
	users = ["admin:$apr1$tm23...................9uz570"]
	...

you can add several user entries by comma separated. 

**3. Restart the Treafik Service**

Reload the traefik service from the swarmpit UI.




## Secure a Service with Basic Authentication

Most services (e.g. WordPress) offer their own authentication mechanism. If your service does not provide a authentication (e.g. Prometheus) you can 
configure a basic authentication easily with trafic.io. 

First you need to generate again a password with the 'htpasswd' command from the apache2-util package. 

The result user/password string can be added directly in the docker-compose.yml file. See the following example with a service configuration with basic authentication via traefik.io:

	....
	services:
	  app:
	     image: prom/prometheus
	     deploy:
	       labels:
	         traefik.port: "9090"
	         traefik.frontend.rule: "Host:myhost.com"
	         traefik.frontend.auth.basic.users: "admin:$$a3451$$MhabbIEpI$$m544Ai23455q42iC00"
	....


**NOTE:** In the password string, you need to replace all '$' by '$$'

Multiple user/password combinations can be separated by ','. You can find more information about traefik.io security [here](https://docs.traefik.io/configuration/backends/docker/#security-considerations).

### Provide a general password file

As an alternative of defining user/password strings in each service configuration you can also generate password file and link this file with your service:


	...
	traefik.frontend.auth.basic.usersFile=/path/.htpasswd
	...



## Docker Registry: Setup Basic Authentication 

The HTTP Rest API of the docker registry can be secured with [basic authentication](https://docs.docker.com/registry/configuration/#htpasswd) using an Apache htpasswd file. The only supported password format is bcrypt. Entries with other hash types are ignored. The htpasswd file is loaded once, at startup. If the file is invalid, the registry will display an error and will not start.

you can follow these steps:

**1. Generate a password**

Generate a folder _management/registry/_ to store htpasswd file

	mkdir -p ./management/registry/auth			   

Create a password file for a user (e.g. admin) 

	htpasswd -cB htpasswd admin

To add additional users run	
	
	htpasswd -B htpasswd user1

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


### Deploy Stack from Private Registry.

If you start a stack form your private registry which is secured via basic authentication you need to run:

	$ deploy -c docker-compose.yml MYTAG --with-registry-auth


# Using Docker Swarm Secrets

[Docker-Swarm Secrets](https://docs.docker.com/engine/swarm/secrets/) can be used in docker swarm to provide sensitive data in a secret way. For example if you want to avoid that a password is stored in an environment variable, a docker secret can be a solution.

To create for example a password you can run:

	echo "my secret..."| docker secret create my_password -

This password is than available in the internal Docker Swarm Raft log. 	
Now you can use the secret instead of an environment variable in a docker-compose.yml file. See the following example for a Postgres Database server:


	version: '3.1'
	services:
	  db:
	    image: postgres:9.6.1
	    environment:
	       POSTGRES_PASSWORD_FILE: "/run/secrets/my_password"
	       ....
	  secrets:
	    - my_password
	...
	secrets:
	  my_password:
	     external: true
	...


The environment variable POSTGRES\_PASSWORD\_FILE points to the location where the password is stored inside the container. The directory /run/secrets/ is the place where docker stores the secrets. 
The new option 'secrets:' inside the service description injects the password into the file "/run/secrets/my_password" of the running container. 
With the 'secrets' declaration, the secret 'my_password' is mapped into the stack. 

Now the docker-compose.yml file is no longer showing the password which is also hidden from docker commands like a _docker inspect_.

**Note:** You need to set the version of the docker-compose.yml file to '3.1' or higher if you want to use Docker Secrets!


## How to access Docker Swarm Secrets from a script

With the following example script the password can be read by a bash script running inside a container. 
The function 'file_env()' is form the [official postgres docker image](https://github.com/docker-library/postgres/tree/master/9.6) and automatically maps a envirnment variable with the prefix '\_FILE' to the corresponding secret:

	#!/bin/bash
	....
	......
	# usage: file_env VAR [DEFAULT]
	#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
	# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
	#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
	file_env() {
		local var="$1"
		local fileVar="${var}_FILE"
		local def="${2:-}"
		if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
			echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
			exit 1
		fi
		local val="$def"
		if [ "${!var:-}" ]; then
			val="${!var}"
		elif [ "${!fileVar:-}" ]; then
			val="$(< "${!fileVar}")"
		fi
		export "$var"="$val"
		unset "$fileVar"
	}
	....
	......
	# Now we map the environment variable POSTGRES_PASSWORD_FILE to the corresponding docker secret.....
	file_env 'POSTGRES_PASSWORD'
    # now the variable POSTGRES_PASSWORD is set to 'my secret...'
    ....
    ......

The script declares the function 'file\_env()' which is a helper method to extract the secret form the given file location. The convention here is that the environment variable is ending to '\_FILE', which is a best practice using Docker Swarm Secrets. 
The prefix '\_FILE' is the indicator for the function 'file\_env()'  to read the secret from the file stored in /run/secrets/. The function 'file\_env()' is also supporting the environment variable without the \_FILE prefix, so that both variants are possible. This can be useful during development where you typically not dealing with a Docker Swarm.  
	

## Why You Should Use Swarm Secrets Instead of Environment Variables

A secret stored in the docker-compose.yml as a normal environment variable is visible inside that file, which should also be checked into a version control where others can see the values in that file, and it will be also visible in commands like a _docker inspect_ on your containers. 
A docker secret conversely will encrypt the secret on disk on the managers, only store it in memory on the workers that need the secret (the file visible in the containers is a _tmpfs_ that is stored in ram), and it is not visible in the docker inspect output.
The key part here is that you are keeping your secret outside of your version control system.  Therefore, it's feasible to prevent the secret from being read by an attacker that breaches an application inside a container, which would be less trivial with an environment variable.


