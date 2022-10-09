# Jellyfin

[Web site](https://jellyfin.org/)  

The goal of the repository is to install docker, docker-compose ... and the container needed to have jellyfin  
You can use the [.env](.env) in order to change the settings.
You can also update [docker-compose.yml](docker-compose.yml) if needed  
> Note: Improvement could be made with nginx as reverse proxy


## INSTALLATION  

1 - 
On debian you should install Git package who is not present by default with the command   

````
apt-get update && apt-get install -y git
````

2 - Clone the Git repo  

Clone the Git repository. Here we will clone on the folder /opt/jellyfin 

````
git clone https://github.com/l-delort/jellyfin.git /opt/jellyfin
````

3 - Open the Git folder and launch the install script    

````
cd /opt/jellyfin    
chmod +x common/*.sh -R    
./common/install.sh  
````
all the need will be installed automatically and the container will be started as well.  
after the install you could access to jellyfin with the url 
> Note: http://your_domain_name   
