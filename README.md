# Introduction
This is a simple GO application which has a single '/version' endpoint containing basic information about the application in JSON format, such as:
```
{
  "Version": "1.0-05ccc57-20200823",
  "Lastcommitsha": "05ccc57",
  "Description": "Simple Golang Application"
}
```
This repository has two parts:
1. the source code, unit test suite, CI pipeline, and docker file to containerise the application into a single docker image
2. the Kubernetes manifests to demostrate how to deploy the application on Kubernetes

All deployment steps are encapsulated in Makefile
# Setup
  You'll need to install docker, Golang, as well as the git, curl, make and jq commands.
  Open terminal window, clone this repository and cd into it.
  ```
  git clone https://github.com/mullumaus/test_goLang.git
  cd test_goLang
  ```
# File structure
  test_goLang directory contains following files:
  
  Dockerfile: docker file to build docker image
  
  Makefile: Golang makefile to build executable file, docker image,  unit test, deploy image, push image to docker hub and versioning.
  
  go.mod		go.sum : go dependencies packages
  
  main.go: the Golang main file
  
  main_test.go: Golang unit test suite
  
  .github/workflows/test1.yml: Github CI workflow file
  
  test2_k8s directory includes yaml files to deploy the application in Kubernetes
  
# Versioning in Makefile
  The respository has tag 1.0. A minor version number is generated for each commit. The version number is consist of $(VERSION)-$(COMMIT)-$(DATE). If the respository does 
  not have tag, then the version number is $(COMMIT)-$(DATE). 
  ```
TAG_COMMIT := $(shell git rev-list --abbrev-commit --tags --max-count=1)
TAG := $(shell git describe --abbrev=0 --tags ${TAG_COMMIT} 2>/dev/null || true)
COMMIT := $(shell git rev-parse --short HEAD)
DATE := $(shell git log -1 --format=%cd --date=format:"%Y%m%d")
VERSION := $(TAG:v%=%)

ifeq ($(VERSION),)
	VERSION := $(COMMIT)-$(DATE)
else
	ifneq ($(COMMIT), $(TAG_COMMIT))
		VERSION := $(VERSION)-$(COMMIT)-$(DATE)
	else
		ifneq ($(shell git status --porcelain),)
			VERSION := $(VERSION)-dirty
		endif
	endif
endif
```

# Build source code
Run below command to generate the go executable file in ../bin/goapp.
```
make build
```
# Install the application
Run command
```
make install
```
# Run executable file
Use below command to run the application
```
make run
```
Open another terminal, and run curl command:
```
curl http://localhost:3000/version | jq '.'
```
The output is something like:
```
{
  "Version": "1.0-65bfb95-20200823",
  "description": "Simple Golang Application",
  "lastcommitsha": "65bfb95"
}
```
# Run unit test
Below command will run the test cases defined in main_test.go
```
make test
```
The output is
```
go test  -v
=== RUN   TestVersionEndpoint
[GIN-debug] [WARNING] Creating an Engine instance with the Logger and Recovery middleware already attached.

[GIN-debug] [WARNING] Running in "debug" mode. Switch to "release" mode in production.
 - using env:	export GIN_MODE=release
 - using code:	gin.SetMode(gin.ReleaseMode)

[GIN-debug] GET    /version                  --> testApp.versionEndpoint (3 handlers)
[GIN] 2020/08/23 - 18:49:01 | 200 |     126.126µs |       127.0.0.1 | GET      "/version"
--- PASS: TestVersionEndpoint (0.00s)
=== RUN   TestInvalidEndpoint
[GIN-debug] [WARNING] Creating an Engine instance with the Logger and Recovery middleware already attached.

[GIN-debug] [WARNING] Running in "debug" mode. Switch to "release" mode in production.
 - using env:	export GIN_MODE=release
 - using code:	gin.SetMode(gin.ReleaseMode)

[GIN-debug] GET    /version                  --> testApp.versionEndpoint (3 handlers)
[GIN] 2020/08/23 - 18:49:01 | 404 |         376ns |       127.0.0.1 | GET      "/"
--- PASS: TestInvalidEndpoint (0.00s)
PASS
ok  	testApp	0.389s
```
# The Dockerfile
The simple docker file uses a golang base image, it builds the executable, which writes to /app/go/bin, and then deletes the source code and test file. Expose port 3000.
```
#pull base image
FROM golang
ENV GOPATH="/app/go"
#create source directory
WORKDIR $GOPATH/src
# Copy go mod and sum files
COPY go.mod go.sum ./
# Download all dependencies. Dependencies will be cached if the go.mod and go.sum files are not changed
RUN go mod download
# Copy the source from the current directory to the Working Directory inside the container
COPY . .
# Build the Go app
RUN make build 
#remove the source code
RUN rm -rf $GOPATH/src
EXPOSE 3000
CMD ["../bin/goapp"]
```

# Build docker image
Run 'make image' command to generate docker image, the image name is 'goapp_image' and tagged with commit SHA
```
make image
```
This is the docker image generated in my local repository
```
$ docker images 
REPOSITORY                                TAG                 IMAGE ID            CREATED             SIZE
goapp_image                               65bfb95             2016d8bdd3b0        9 hours ago         990MB
```

# Deploy and test docker image
The command will start a container in detach mode with 'goapp_image' image and run curl command to get '/version' endpoint
```
make testimage
```
The Makefile called below docker commands:
```
testimage: 
	docker run -d --cap-drop=all --cap-add=NET_RAW --cap-add=NET_BIND_SERVICE -p 3000:3000 --name $(CONTAINER_NAME)  $(IMAGE_NAME) 
	docker exec $(CONTAINER_NAME) curl http://localhost:3000/version
```
The output looks like: 
```
{"Version":"1.0-2e68053-20200823","description":"Simple Golang Application","lastcommitsha":"2e68053"}
```
  

# Push docker image to docker hub
First, log in docker hub with your username and password
```
docker login -u $(X_USERNAME) -p $(X_PASSWORD)
```
Then, push the image
```
make push
```

# Clean up
Delete the executable file, stop and remove docker container
```
make clean
```

# Deep clean up
Do previous clean up and delete images from local repository as well. But you'd better not to run this command now, because we'll use the image to deploy the application on Kubernetes later.
```
make deepclean
```
# Docker security
Docker container shares the kernel as host, containers are isolated using namespace in linux kernel. By default, Docker starts containers with a restricted set of capabilities. Container should be run with least privilege.  In this application, we drop all capabilities and just add NET_RAW and NET_BIND_SERVICE back 

```
docker run -d --cap-drop=all --cap-add=NET_RAW --cap-add=NET_BIND_SERVICE -p 3000:3000 
	--name $(CONTAINER_NAME) $(IMAGE_NAME) 
	
```	
# CI Pipeline
The CI pileline is defined in .github/workflows/test1.yml. You can view the workflow by clicking "Actions" label. The CI pipeline will be triggered automatically when code changes are pushed to the repository

```
name: CI

# Controls when the action will run. Triggers the workflow on push or pull request
# events but only for the master branch
on:
  push:
    branches: [ master ]
  pull_request:
    branches: [ master ]

# A workflow run is made up of one or more jobs that can run sequentially or in parallel
jobs:
  # This workflow contains a single job called "build"
  build:
    # The type of runner that the job will run on
    runs-on: ubuntu-latest

    # Steps represent a sequence of tasks that will be executed as part of the job
    steps:
    # Checks-out your repository under $GITHUB_WORKSPACE, so your job can access it
    - uses: actions/checkout@v2
    - run: git fetch --prune --unshallow

    # build the source code
    - name: build code
      run: make build

    # build docker image
    - name: build image
      run:  make image

    # run unit test
    - name: unit test
      run: make test

    # deploy and test docker image
    - name: test docker image
      run: make testimage
```
# Test2: Deploy on Kubernetes
This section shows you how to deploy the application on Kubenetes. 

First, setup Kubernetes cluster, I am using minikube on VirtualBox on my laptop. Then, use the image created by test1 to deploy on Kubernetes

If you haven't push the image to docker hub, you can run below command to use the image in the local docker respository
```
eval $(minikube docker-env) 
```

Make sure your Kubernetes cluster has started. If you are running minikube on VirtualBox, to start a minikube cluster, run
```
minikube start --driver=virtualbox
```
then cd into test2_k8s directory
```
cd test2_k8s
chmod +x run.sh
```

# File structure
run.sh : use this shell script to setup the deployment on Kubernetes.

deployment.yaml: the yaml file to create a kubernetes deployment using 'goapp_image' image with 2 replicas

service.yaml: create a service 'goapp-service' to expose the deployment on node port 30008

pv.yaml: create a persistent volume 'log-volume' for application log

pvc.yaml: create a persistent volume claim to bound the log volume

Makefile : An optional file, if your test environment comes with make command, you can also use this makefile to create deployment. I prefer Makefile when testing in sandbox

'./run.sh' prints the usage of the script
```
$ chmod +x run.sh
$ ./run.sh 
Use this script to deploy go application on Kubernetes

./run.sh
	-h --help:   print this usage
	-d --deploy: deploy the application on Kubernetes
	-l --list:   list all resource in the namespace
	-t --test:   test the deployment
	-c --clean:  delete all resources in the namespace
```
# Create Deployment
The deployment can be created by command:
```
./run -d
```
or
```
make deploy
``` 
The command creates below resources:
1. namespace technical-test
2. a deployment with 2 pods (2 replicas), 
3. a service named 'goapp-service' to expose the deployment on node port 30008
4. a persistent volume
5. a persistent volume claim which is bound to the persistent volume and mounted to /var/log/goapp in container

It invokes following kubectl commands:
```
deploy:
	kubectl create namespace  $(NAMESPACE)
	kubectl create -f pv.yaml
	kubectl create -f pvc.yaml
	kubectl create -f deployment.yaml
	kubectl create -f service.yaml
```  
# List resources in the namespace
Run command:
```
./run -l
```
or
```
make list
```
The output looks like:
```
kubectl get all --namespace=technical-test
NAME                                    READY   STATUS    RESTARTS   AGE
pod/goapp-deployment-6bbb78fd4c-lwb7w   1/1     Running   0          20s
pod/goapp-deployment-6bbb78fd4c-rxcxr   1/1     Running   0          20s

NAME                    TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
service/goapp-service   NodePort   10.104.169.223   <none>        3000:30008/TCP   20s

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/goapp-deployment   2/2     2            2           20s

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/goapp-deployment-6bbb78fd4c   2         2         2       20s
```

# Test 
Run command './run -t' to test your deployment
```
./run -t
```
or
```
make test
```
The script called curl command to get application version information:
```
test:
	curl $(NODEIP):$(NODEPORT)/version
```  
If you see the output looks like as below, your deployment is successful:
```
{"Version":"1.0-65bfb95-20200823","description":"Simple Golang Application","lastcommitsha":"65bfb95"}
```

# Clean up
Remove all resources in the namespace 'technical-test'
```
./run -c
```
or
```
make clean
```
