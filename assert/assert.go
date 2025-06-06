//go:build !ReleaseFast

package assert

func True(condition bool) {
	if !condition {
		panic("assertion failure: value is not true")
	}
}

func False(condition bool) {
	if !condition {
		panic("assertion failure: value is not false")
	}
}

func NotNil(v any) {
	if v == nil {
		panic("assertion failure: value is nil")
	}
}

func Nil(v any) {
	if v != nil {
		panic("assertion failure: value is not nil")
	}
}
