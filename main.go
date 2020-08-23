package main

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

var (
	version    string
	lastcommit string
)

func versionEndpoint(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"Version": version, "lastcommitsha": lastcommit, "description": "Simple Golang Application"})
}

func setupEngine() *gin.Engine {
	r := gin.Default()
	r.GET("/version", versionEndpoint)
	return r
}

func main() {
	setupEngine().Run(":3000")
}
