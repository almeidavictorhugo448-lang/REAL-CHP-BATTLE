extends Control

var _transitioning := false

func _ready() -> void:
	var splash := TextureRect.new()
	splash.name = "SplashArtwork"
	splash.texture = load("res://assets/sigma_splash.svg")
	splash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	splash.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	splash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(splash)
	move_child(splash, 0)

	var shade := get_node_or_null("Background") as ColorRect
	if shade:
		shade.color = Color(0.006, 0.008, 0.018, 0.30)

	var title := get_node_or_null("Title") as Label
	if title:
		title.text = "SIGMA"
		title.add_theme_font_size_override("font_size", 94)
		title.add_theme_color_override("font_color", Color("#FFF1E8"))
		title.add_theme_color_override("font_outline_color", Color("#42D7E8"))
		title.add_theme_constant_override("outline_size", 7)

	var subtitle := get_node_or_null("Subtitle") as Label
	if subtitle:
		subtitle.text = "DROP  •  LOOT  •  SURVIVE"
		subtitle.add_theme_font_size_override("font_size", 22)
		subtitle.add_theme_color_override("font_color", Color("#D7EDF2"))

	var enter := get_node_or_null("Enter") as Button
	if enter:
		enter.text = "▶  ENTRAR NA ARENA"
		enter.add_theme_font_size_override("font_size", 24)
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("#B98222")
		normal.border_color = Color("#42D7E8")
		normal.set_border_width_all(2)
		normal.set_corner_radius_all(12)
		normal.content_margin_left = 24
		normal.content_margin_right = 24
		enter.add_theme_stylebox_override("normal", normal)
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color("#D8A93D")
		enter.add_theme_stylebox_override("hover", hover)
		enter.add_theme_stylebox_override("pressed", normal)

	var edition := Label.new()
	edition.text = "BATTLE ROYALE  •  SIGMA PRIVATE SERVER"
	edition.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	edition.position = Vector2(-210, -42)
	edition.size = Vector2(420, 26)
	edition.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	edition.add_theme_font_size_override("font_size", 13)
	edition.add_theme_color_override("font_color", Color("#B9DCE4"))
	edition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(edition)

func _go_to_game() -> void:
	if _transitioning:
		return
	_transitioning = true
	var error := get_tree().change_scene_to_file("res://main.tscn")
	if error != OK:
		_transitioning = false
		push_error("Falha ao abrir o Sigma Battle Royale: %s" % error)
