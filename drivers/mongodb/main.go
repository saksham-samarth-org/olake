package main

import (
	"context"

	"github.com/datazip-inc/olake"
	driver "github.com/datazip-inc/olake/drivers/mongodb/internal"
)

// queue test C: trivial change so a driver is detected.
func main() {
	driver := &driver.Mongo{
		CDCSupport: false,
	}
	defer driver.Close(context.Background())
	olake.RegisterDriver(driver)
}
