extends "res://main.gd"

const SIGMA_GOLD := Color("#F6C34A")
const SIGMA_CYAN := Color("#42D7E8")
const SIGMA_INK := Color("#101A2B")
const SIGMA_PANEL := Color(0.025, 0.055, 0.10, 0.94)

func _ready() -> void:
    super._ready()
    call_deferred("_apply_sigma_identity")

func _set_lobby_atmosphere() -> void:
    if graphics_environment == null:
        return
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color("#08152D")
    sky_mat.sky_horizon_color = Color("#3C6F82")
    sky_mat.ground_bottom_color = Color("#101C2C")
    sky_mat.ground_horizon_color = Color("#35515A")
    sky_mat.sun_angle_max = 8.0
    sky.sky_material = sky_mat
    graphics_environment.background_mode = Environment.BG_SKY
    graphics_environment.sky = sky
    graphics_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    graphics_environment.ambient_light_color = Color("#8BB9C8")
    graphics_environment.ambient_light_energy = 0.72
    graphics_environment.fog_enabled = true
    graphics_environment.fog_light_color = Color("#547C8B")
    graphics_environment.fog_density = 0.008
    if is_instance_valid(graphics_sun):
        graphics_sun.light_color = Color("#F6D58A")
        graphics_sun.light_energy = 0.55

func _apply_sigma_identity() -> void:
    _brand_tree(self)
    if is_instance_valid(graphics_environment):
        _set_lobby_atmosphere()

func _brand_tree(node: Node) -> void:
    if node is Label:
        var label := node as Label
        label.text = label.text.replace("PUNK", "SIGMA").replace("punk", "sigma")
        if label.text.contains("TEMPORADA"):
            label.text = "SIGMA BATTLE ROYALE  •  SOBREVIVA E DOMINE"
        if label.text.contains("Ilha SIGMA"):
            label.text = "ILHA SIGMA  •  SOLO"
        label.add_theme_color_override("font_color", Color("#F4F5F8"))
    elif node is Button:
        var button := node as Button
        button.text = button.text.replace("PUNK", "SIGMA").replace("punk", "sigma")
        var base := SIGMA_PANEL
        if button.text.contains("COMEÇAR") or button.text.contains("JOGAR"):
            base = Color("#B98222")
            button.add_theme_color_override("font_color", Color("#101522"))
            button.add_theme_font_size_override("font_size", 22)
        var normal := StyleBoxFlat.new()
        normal.bg_color = base
        normal.border_color = SIGMA_CYAN if base == SIGMA_PANEL else SIGMA_GOLD
        normal.set_border_width_all(1)
        normal.set_corner_radius_all(9)
        normal.content_margin_left = 10
        normal.content_margin_right = 10
        button.add_theme_stylebox_override("normal", normal)
        var hover := normal.duplicate() as StyleBoxFlat
        hover.bg_color = base.lightened(0.16)
        button.add_theme_stylebox_override("hover", hover)
        var pressed := normal.duplicate() as StyleBoxFlat
        pressed.bg_color = base.darkened(0.14)
        button.add_theme_stylebox_override("pressed", pressed)
    elif node is Panel:
        var panel := node as Panel
        var style := StyleBoxFlat.new()
        style.bg_color = SIGMA_PANEL
        style.border_color = Color(0.20, 0.65, 0.78, 0.85)
        style.set_border_width_all(1)
        style.set_corner_radius_all(10)
        panel.add_theme_stylebox_override("panel", style)
    for child in node.get_children():
        _brand_tree(child)
