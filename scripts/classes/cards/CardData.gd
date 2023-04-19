class_name Card

var name: String
var attack: int
var health: int

var sigils: Array
var traits: Array

enum Traits {
	RARE = 1,
	NO_SACRIFICE = 2,
	NO_HAMMER = 4,
	ACTIVE = 8,
	CONDUIT = 16
}
