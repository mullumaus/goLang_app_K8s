package main

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

//the value is assigned by ldflags in Makefile
var (
	version    string
	lastcommit string
)

//create '/version' endpoint content
func versionEndpoint(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"Version": version, "lastcommitsha": lastcommit, "description": "Simple Golang Application"})
}

//set up engine server
func setupEngine() *gin.Engine {
	r := gin.Default()
	r.GET("/version", versionEndpoint)
	return r
}

//main function
func main() {
	setupEngine().Run(":3000")
}
