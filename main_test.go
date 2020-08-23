package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestVersionEndpoint(t *testing.T) {

	ts := httptest.NewServer(setupEngine())
	// defer shut down the server until all requests have gone through
	defer ts.Close()

	// make a request to our server with the /version endpoint
	resp, _ := http.Get(fmt.Sprintf("%s/version", ts.URL))
	assert.Equal(t, 200, resp.StatusCode)

	val, ok := resp.Header["Content-Type"]
	// check that the "content-type" header is actually set
	if !ok {
		t.Fatalf("Expected Content-Type header to be set")
	}

	// check that it was set as expected
	if val[0] != "application/json; charset=utf-8" {
		t.Fatalf("Expected \"application/json; charset=utf-8\", got %s", val[0])
	}
}

func TestInvalidEndpoint(t *testing.T) {
	ts := httptest.NewServer(setupEngine())
	// Shut down the server until all requests have gone through
	defer ts.Close()

	// Make a request to our server with the invalid endpoint
	resp, _ := http.Get(fmt.Sprintf("%s/", ts.URL))
	assert.Equal(t, 404, resp.StatusCode)
}
