# dockerfiles
A repository to create a docker image for OS Robotics course

To download the course solution code
```sh
./update-sourcecode.sh
```
To build the docker image
```sh
docker-compose build
```
To create a bash session in the container that contained the built image
```sh
./execute-container.sh
```
References:
1. https://github.com/NVIDIA/nvidia-docker
2. https://github.com/jessfraz/dockerfiles/issues/329
