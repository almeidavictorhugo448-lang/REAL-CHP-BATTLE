extends Node

func _ready() -> void:
    call_deferred("_fix_runtime")

func _process(_delta: float) -> void:
    _fix_runtime()

func _fix_runtime() -> void:
    var root := get_parent()
    if root == null:
        return

    var layer := root.get_node_or_null("UI_LAYER") as CanvasLayer
    if layer == null:
        layer = CanvasLayer.new()
        layer.name = "UI_LAYER"
        layer.layer = 100
        root.add_child(layer)

    var current_ui = root.get("ui")
    if current_ui != null and is_instance_valid(current_ui):
        if current_ui.get_parent() != layer:
            current_ui.reparent(layer)
        current_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var cam := root.get_node_or_null("LobbyCamera") as Camera3D
    if cam != null:
        cam.current = true
