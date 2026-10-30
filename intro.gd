extends Control

var _elapsed := 0.0

func _ready() -> void:
	_build_screen()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 2.0:
		_go_to_game()

func _build_screen() -> void:
	var art := TextureRect.new()
	art.texture = load("res://assets/punk_splash.svg")
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
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
	enter.pressed.connect(_go_to_game)
	add_child(enter)

func _go_to_game() -> void:
	if get_tree().current_scene == self:
		get_tree().change_scene_to_file("res://main.tscn")
