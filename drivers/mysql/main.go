package main

import (
	"github.com/datazip-inc/olake"
	driver "github.com/datazip-inc/olake/drivers/mysql/internal"
)

// queue test B: trivial change so a driver is detected.
func main() {
	driver := &driver.MySQL{
		CDCSupport: false,
	}
	defer driver.Close()
	olake.RegisterDriver(driver)
}
