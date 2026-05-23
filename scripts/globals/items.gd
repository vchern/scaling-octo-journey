extends RefCounted

const COIN := "coin"
const POTION := "potion"
const SWORD := "sword"

const DEFINITIONS := {
	COIN: {"display_name": "Gold", "color": Color(1.0, 0.85, 0.2)},
	POTION: {"display_name": "Potion", "color": Color(0.95, 0.3, 0.3)},
	SWORD: {"display_name": "Sword", "color": Color(0.75, 0.75, 0.85)},
}

static func color_for(id: String) -> Color:
	if DEFINITIONS.has(id):
		return DEFINITIONS[id]["color"]
	return Color.WHITE

static func display_name(id: String) -> String:
	if DEFINITIONS.has(id):
		return DEFINITIONS[id]["display_name"]
	return id
