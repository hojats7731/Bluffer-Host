extends Node

const WESTERN := "0123456789"
const PERSIAN := "۰۱۲۳۴۵۶۷۸۹"

func to_persian_digits(value) -> String:
	var text := str(value)
	for i in WESTERN.length():
		text = text.replace(WESTERN[i], PERSIAN[i])
	return text
