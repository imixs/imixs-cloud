# Version Control

The following section gives an example how to use a private Git repository to version the configuration of an imixs-cloud environment. 

One concept of Imixs-Cloud is a fast and easy setup of a docker-swarm environment. All concepts of Imixs-Cloud are based on clearly structured files based configuration. For that reason it is nearby to manage the configuration with the help of a version control system like Git.
Git can be used to load an existing setup on a blank manager node or push changes made on the server side back into the code repository. As the configuration files are telling a lot about the environment - also sensible information - the code repository should be private. The next section explains how to setup a git repository. 


## Init a Private Git Repositroy

A private Git repository can be setup on GitHub or on a private server. 

Information about Git can be found in the book [Pro Git book](https://git-scm.com/book/en/v2), written by Scott Chacon and Ben Straub and published by Apress, which is available [online](https://git-scm.com/book/en/v2). This book also includes information how to setup a private Git repository. Projects like [GitBucket](https://github.com/gitbucket/gitbucket) can help to setup a repository with a web interface and a lot of additional features.  We will not explain how to setup a Git private repository here and we assume that you already have a private repository running. 



### Create a new repository from the command line

Assuming that you have created the recommended file structure for your imixs-cloud locally you can init a local git repository and add the configuration into the new local repo:

	$ touch README.md
	$ git init
	$ git add README.md
	$ git commit -m "first commit"


### Push an existing repository from the command line

With the following example the local git repository, holding the imixs-cloud configuration, can be pushed into a private remote repository:
 
	$ git remote add origin http://my-private-git.com/my-cloud.git
	$ git push -u origin master
	Username for 'http://my-private-git.com': 
	Password for 'http://my-private-git.com': 

In this example a http connection is used so git will ask for username and password. If you use ssh a private ssh key is used to authenticate against the reote repository. 


## Installing Git on the Manager Server Node

Next you should install git on the manager node of your docker swarm environment.
If you want to install the Git on Linux via a binary installer, you can generally do so through the basic package-management tool that comes with your distribution. 

If you’re on a Debian-based distribution, try apt-get:

	$ sudo apt-get install git



## Clone the Environment Configuration 

After you have installed git on the server, you can now clone the configuration from your private remote repository: 


	$ git clone http://my-private-git.com/my-cloud.git
	Cloning into 'my-cloud'...
	Username for 'http://my-private-git.com': 
	Password for 'http://my-private-git.com': 
	remote: Counting objects: 26, done
	remote: Finding sources: 100% (26/26)
	remote: Getting sizes: 100% (24/24)
	Unpacking objects: 100% (26/26), done.
	remote: Total 26 (delta 1), reused 26 (delta 1)
	
	
The configuration will then be found in the project directory:

	~/my-cloud
	

## Pull the Configuration 	

After the git repo is setup you can pull changes with

	$ cd my-cloud
	$ git pull


## Push Changes 	

After you made changes you can commit and push the changes back into the remote repository

	$ cd my-cloud
	$ git add some-file
	$ git commit -m "some update"
	$ git push origin master


## Reset Changes 

In case you have tested some configuration locally on the manager node you can easily reset your changes to the latest version in your git repo: 

	$ git checkout .
	
This works if you have not yet added any changes to the index. 
 