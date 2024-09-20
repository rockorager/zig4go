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

func False(condition bool) {
	if !condition {
		log.Output(2, "assertion failure: value is not false")
		panic("assertion failure: value is not false")
	}
}

func NotNil(v any) {
	if v == nil {
		log.Output(2, "assertion failure: value is nil")
		panic("assertion failure: value is nil")
	}
}

func Nil(v any) {
	if v != nil {
		log.Output(2, "assertion failure: value is not nil")
		panic("assertion failure: value is not nil")
	}
}
