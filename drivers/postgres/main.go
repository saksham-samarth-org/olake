package main

import (
	"github.com/datazip-inc/olake"
	driver "github.com/datazip-inc/olake/drivers/postgres/internal"
)

// queue test A: trivial change so a driver is detected.
func main() {
	driver := &driver.Postgres{
		CDCSupport: false,
	}
	defer driver.CloseConnection()
	olake.RegisterDriver(driver)
}

// e2e p1 1795613013

// e2e q1 1795616188
