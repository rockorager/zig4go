//go:build ReleaseFast || ReleaseSmall

package assert

func True(condition bool) {}

func False(condition bool) {}

func NotNil(v any) {}

func Nil(v any) {}
