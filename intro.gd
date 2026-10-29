extends Control

var _elapsed := 0.0

func _ready() -> void:
	_build_screen()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 3.5:
		_go_to_game()

func _build_screen() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.025, 0.025, 0.035, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var glow := ColorRect.new()
	glow.color = Color(0.16, 0.025, 0.035, 0.45)
	glow.anchor_left = 0.0
	glow.anchor_top = 0.55
	glow.anchor_right = 1.0
	glow.anchor_bottom = 1.0
	add_child(glow)

	var center := VBoxContainer.new()
	center.anchor_left = 0.08
	center.anchor_top = 0.20
	center.anchor_right = 0.92
	center.anchor_bottom = 0.82
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 18)
	add_child(center)

	var title := Label.new()
	title.text = "PUNK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 112)
	title.add_theme_color_override("font_color", Color(0.95, 0.08, 0.12))
	center.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "SOBREVIVA. LUTE. DOMINE."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color(0.88, 0.88, 0.9))
	center.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 28
	center.add_child(spacer)

	var loading := Label.new()
	loading.text = "PREPARANDO CAMPO DE BATALHA..."
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading.add_theme_font_size_override("font_size", 15)
	loading.add_theme_color_override("font_color", Color(0.68, 0.68, 0.72))
	center.add_child(loading)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(300, 8)
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	center.add_child(bar)

	var enter := Button.new()
	enter.text = "ENTRAR NO JOGO"
	enter.custom_minimum_size = Vector2(260, 58)
	enter.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	enter.add_theme_font_size_override("font_size", 20)
	enter.pressed.connect(_go_to_game)
	center.add_child(enter)

func _go_to_game() -> void:
	if get_tree().current_scene == self:
		get_tree().change_scene_to_file("res://main.tscn")
