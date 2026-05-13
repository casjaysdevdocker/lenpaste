## 👋 Welcome to lenpaste 🚀  

lenpaste README  
  
  
## Install my system scripts  

```shell
 sudo bash -c "$(curl -q -LSsf "https://github.com/systemmgr/installer/raw/main/install.sh")"
 sudo systemmgr --config && sudo systemmgr install scripts  
```
  
## Automatic install/update  
  
```shell
dockermgr update lenpaste
```
  
## Install and run container
  
```shell
dockerHome="/var/lib/srv/$USER/docker/casjaysdevdocker/lenpaste/lenpaste/latest/rootfs"
mkdir -p "/var/lib/srv/$USER/docker/lenpaste/rootfs"
git clone "https://github.com/dockermgr/lenpaste" "$HOME/.local/share/CasjaysDev/dockermgr/lenpaste"
cp -Rfva "$HOME/.local/share/CasjaysDev/dockermgr/lenpaste/rootfs/." "$dockerHome/"
docker run -d \
--restart always \
--privileged \
--name casjaysdevdocker-lenpaste-latest \
--hostname lenpaste \
-e TZ=${TIMEZONE:-America/New_York} \
-v "$dockerHome/data:/data:z" \
-v "$dockerHome/config:/config:z" \
-p 80:80 \
casjaysdevdocker/lenpaste:latest
```
  
## via docker-compose  
  
```yaml
version: "2"
services:
  ProjectName:
    image: casjaysdevdocker/lenpaste
    container_name: casjaysdevdocker-lenpaste
    environment:
      - TZ=America/New_York
      - HOSTNAME=lenpaste
    volumes:
      - "/var/lib/srv/$USER/docker/casjaysdevdocker/lenpaste/lenpaste/latest/rootfs/data:/data:z"
      - "/var/lib/srv/$USER/docker/casjaysdevdocker/lenpaste/lenpaste/latest/rootfs/config:/config:z"
    ports:
      - 80:80
    restart: always
```
  
## Get source files  
  
```shell
dockermgr download src casjaysdevdocker/lenpaste
```
  
OR
  
```shell
git clone "https://github.com/casjaysdevdocker/lenpaste" "$HOME/Projects/github/casjaysdevdocker/lenpaste"
```
  
## Build container  
  
```shell
cd "$HOME/Projects/github/casjaysdevdocker/lenpaste"
buildx 
```
  
## Authors  
  
🤖 casjay: [Github](https://github.com/casjay) 🤖  
⛵ casjaysdevdocker: [Github](https://github.com/casjaysdevdocker) [Docker](https://hub.docker.com/u/casjaysdevdocker) ⛵  
