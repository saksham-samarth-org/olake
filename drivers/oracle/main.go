package main

import (
	"github.com/datazip-inc/olake"
	driver "github.com/datazip-inc/olake/drivers/oracle/internal"
)

// queue test D: trivial change so a driver is detected.
func main() {
	driver := &driver.Oracle{
		CDCSupport: false,
	}
	defer driver.Close()
	olake.RegisterDriver(driver)
}
