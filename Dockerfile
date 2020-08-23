#pull base image
FROM golang

ENV GOPATH="/app/go"

LABEL maintainer="lihuiguo@gmail.com"

#create source directory
WORKDIR $GOPATH/src

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download all dependencies. Dependencies will be cached if the go.mod and go.sum files are not changed
RUN go mod download

# Copy the source from the current directory to the Working Directory inside the container
COPY . .

# Build the Go application
RUN make build 

#remove the source code
RUN rm -rf $GOPATH/src

EXPOSE 3000

CMD ["../bin/goapp"]
