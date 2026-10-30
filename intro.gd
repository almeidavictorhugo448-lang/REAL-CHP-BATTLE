extends Control

var _transitioning := false

func _ready() -> void:
	_build_screen()

func _build_screen() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var art := TextureRect.new()
	var splash := load("res://assets/punk_splash.svg") as Texture2D
	if splash:
		art.texture = splash
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)

	var enter := Button.new()
	enter.text = "ENTRAR"
	enter.anchor_left = 0.5
	enter.anchor_top = 0.84
	enter.anchor_right = 0.5
	enter.anchor_bottom = 0.84
	enter.offset_left = -150
	enter.offset_top = 0
	enter.offset_right = 150
	enter.offset_bottom = 64
	enter.add_theme_font_size_override("font_size", 24)
	enter.add_theme_color_override("font_color", Color.WHITE)
	enter.add_theme_color_override("font_hover_color", Color.WHITE)
	enter.add_theme_stylebox_override("normal", _button_style(Color(0.035, 0.38, 0.30, 0.96)))
	enter.add_theme_stylebox_override("hover", _button_style(Color(0.06, 0.52, 0.40, 1.0)))
	enter.add_theme_stylebox_override("pressed", _button_style(Color(0.025, 0.25, 0.21, 1.0)))
	enter.pressed.connect(_go_to_game)
	add_child(enter)
	enter.grab_focus()

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.24, 0.95, 0.76, 0.9)
	return style

func _go_to_game() -> void:
	if _transitioning:
		return
	_transitioning = true
	var error := get_tree().change_scene_to_file("res://main.tscn")
	if error != OK:
		_transitioning = false
		push_error("Falha ao abrir o jogo PUNK: %s" % error)
