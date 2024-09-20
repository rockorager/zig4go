//go:build !ReleaseFast

package assert

import (
	"log"
)

func True(condition bool) {
	if !condition {
		log.Output(2, "assertion failure: value is not true")
		panic("assertion failure: value is not true")
	}
}
