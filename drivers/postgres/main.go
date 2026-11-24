package main

import (
	"github.com/datazip-inc/olake"
	driver "github.com/datazip-inc/olake/drivers/postgres/internal"
)

// queue-gate test A: trivial change so a driver is detected.
func main() {
	driver := &driver.Postgres{
		CDCSupport: false,
	}
	defer driver.CloseConnection()
	olake.RegisterDriver(driver)
}
