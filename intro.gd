extends Control

var _transitioning := false

func _ready() -> void:
	_build_screen()

func _build_screen() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Fundo explícito: a tela nunca depende do carregamento de uma imagem.
	var background := ColorRect.new()
	background.color = Color(0.018, 0.022, 0.038, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var art_resource := load("res://assets/punk_splash.svg")
	if art_resource is Texture2D:
		var art := TextureRect.new()
		art.texture = art_resource
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(art)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.28)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var title := Label.new()
	title.text = "PUNK"
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.position = Vector2(-260, -115)
	title.size = Vector2(520, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 76)
	title.add_theme_color_override("font_color", Color(1.0, 0.20, 0.30))
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 4)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "SOBREVIVA  •  LUTE  •  DOMINE"
	subtitle.set_anchors_preset(Control.PRESET_CENTER)
	subtitle.position = Vector2(-260, -12)
	subtitle.size = Vector2(520, 38)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 19)
	subtitle.add_theme_color_override("font_color", Color(0.86, 0.89, 0.95))
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)

	var enter := Button.new()
	enter.text = "ENTRAR"
	enter.anchor_left = 0.5
	enter.anchor_top = 0.78
	enter.anchor_right = 0.5
	enter.anchor_bottom = 0.78
	enter.offset_left = -150
	enter.offset_top = 0
	enter.offset_right = 150
	enter.offset_bottom = 64
	enter.add_theme_font_size_override("font_size", 24)
	enter.add_theme_color_override("font_color", Color.WHITE)
	enter.add_theme_color_override("font_hover_color", Color.WHITE)
	enter.add_theme_stylebox_override("normal", _button_style(Color(0.72, 0.055, 0.15, 0.98)))
	enter.add_theme_stylebox_override("hover", _button_style(Color(0.92, 0.08, 0.20, 1.0)))
	enter.add_theme_stylebox_override("pressed", _button_style(Color(0.48, 0.035, 0.10, 1.0)))
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
	style.border_color = Color(1.0, 0.42, 0.50, 0.95)
	return style

func _go_to_game() -> void:
	if _transitioning:
		return
	_transitioning = true
	var error := get_tree().change_scene_to_file("res://main.tscn")
	if error != OK:
		_transitioning = false
		push_error("Falha ao abrir o jogo PUNK: %s" % error)
