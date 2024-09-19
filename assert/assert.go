//go:build !ReleaseFast

package assert

import (
	"fmt"
	"log"
)

func True(condition bool, format string, v ...any) {
	if !condition {
		msg := fmt.Sprintf(format, v...)
		log.Output(2, msg)
		panic(msg)
	}
}
