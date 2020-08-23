TAG_COMMIT := $(shell git rev-list --abbrev-commit --tags --max-count=1)
TAG := $(shell git describe --abbrev=0 --tags ${TAG_COMMIT} 2>/dev/null || true)
COMMIT := $(shell git rev-parse --short HEAD)
DATE := $(shell git log -1 --format=%cd --date=format:"%Y%m%d")
VERSION := $(TAG:v%=%)
IMAGE_NAME := goapp_image
EXEC_NAME := ../bin/goapp
CONTAINER_NAME := goapp_container
unexport GOPATH

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

FLAGS := -ldflags "-X main.version=$(VERSION) -X main.lastcommit=$(COMMIT)"

build:
	go build $(FLAGS) -o $(EXEC_NAME) main.go

run:
	go run $(FLAGS) main.go

install:
	go install $(FLAGS)

image: 
	docker build -t $(IMAGE_NAME) .
	docker tag $(IMAGE_NAME) $(IMAGE_NAME):$(COMMIT)
    #docker tag $(IMAGE_NAME) $(IMAGE_NAME):latest
	docker images

test:
	go test  -v

testimage: 
	docker run -d --cap-drop=all --cap-add=NET_RAW --cap-add=NET_BIND_SERVICE -p 3000:3000 --name $(CONTAINER_NAME) $(IMAGE_NAME) 
	docker exec $(CONTAINER_NAME) curl http://localhost:3000/version
	
push:
	#docker login -u $(X_USERNAME) -p $(X_PASSWORD)
	docker tag $(IMAGE_NAME) $(X_USERNAME)/$(IMAGE_NAME):latest
	docker push $(X_USERNAME)/$(IMAGE_NAME)

clean: 
	-rm -f 	$(EXEC_NAME)
	-docker stop $(CONTAINER_NAME)
	-docker rm $(CONTAINER_NAME)

deepclean:	clean
	-docker rmi $(IMAGE_NAME):$(COMMIT)
	-docker rmi $(IMAGE_NAME):latest