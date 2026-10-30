extends Control

var _transitioning := false

func _go_to_game() -> void:
	if _transitioning:
		return
	_transitioning = true
	var error := get_tree().change_scene_to_file("res://main.tscn")
	if error != OK:
		_transitioning = false
		push_error("Falha ao abrir o jogo PUNK: %s" % error)
