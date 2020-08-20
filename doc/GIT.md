# Git

The *Imixs-Cloud* environment is hosted on Github. You can either [fork](https://guides.github.com/activities/forking/) the repo if you plan to contribute or you can create a clone if you plan to setup you own private environment.

## Create a Fork

In case you plan to contribute to *Imixs-Coud* you may create a fork on Github. Creating a “fork” is producing a personal copy and you can submit Pull Requests to help make this project better by offering your changes. Forking is at the core of social coding at GitHub.
Find details about how to fork on Github [here](https://guides.github.com/activities/forking/).


## Creating a Clone

In difference to a fork a clone can be the starting point to build you own environment based on the *Imixs-Cloud* project. In this case you don't want to push your changes into the *Imixs-Cloud* origin project. 

To create you private clone you can use the clone command form git. To 

	# create a local copy 
	$ git clone https://github.com/imixs/imixs-cloud.git
	# disconnect your repo from github
	$ cd imixs-cloud
	$ git remote rm origin

To control if you repo is still connected type:

	$ git remote -v
	

### Create a new Origin


To connect your local clone with your own Git Server run:

	$ git remote add origin <server>

For example:

	$ git remote add origin ssh://git@git.foo.com/git/my-cloud

Now your new Imixs-Cloud environment is connected to your own git repository. 




