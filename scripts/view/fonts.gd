## Two bundled OFL fonts: Exo 2 for titles, Inter for numbers and body text.
class_name Fonts
extends RefCounted

static var _cache: Dictionary = {}

static func display(weight: int = 800) -> Font:
	return _font_for("res://fonts/Exo2.ttf", weight)

static func data(weight: int = 600) -> Font:
	return _font_for("res://fonts/Inter.ttf", weight)

static func _font_for(path: String, weight: int) -> Font:
	var key := "%s:%d" % [path, weight]
	if _cache.has(key):
		return _cache[key]
	var fv := FontVariation.new()
	fv.base_font = load(path)
	var ts := TextServerManager.get_primary_interface()
	fv.variation_opentype = {ts.name_to_tag("wght"): weight}
	_cache[key] = fv
	return fv
