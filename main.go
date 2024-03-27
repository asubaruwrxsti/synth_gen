package main

import (
	"fmt"
	"strings"

	"golang.org/x/text/cases"
	"golang.org/x/text/language"
)

func main() {
	fmt.Println(ParseServiceName("hello_world"))
}

func ParseServiceName(serviceName string) string {
	words := strings.FieldsFunc(serviceName, func(r rune) bool {
		return r == '_'
	})
	for i, word := range words {
		words[i] = cases.Title(language.English).String(word)
	}
	return strings.Join(words, "")
}
