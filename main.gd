extends Node3D

# PUNK v1 — protótipo 3D em desenvolvimento.
# Original assets and gameplay. Third-person mobile camera/control style.

const MAX_HP := 200.0
const MAX_ENERGY := 200.0
const MAG := 30
const MAP := 210.0
const START_TIME := 420.0

var mode := "lobby"
var selected := "Kosmos"
var skin := "Original"
var wardrobe_category := "Conjuntos"
var wardrobe_equipped := {"Conjuntos":"Conjunto Dragão Neon","Cabeças":"Cabelo Espinhos","Máscaras":"Máscara Tática","Peitorais":"Jaqueta Eclipse","Calças":"Calça Angelical Cósmica","Sapatos":"Tênis Azul Elétrico","Emotes":"Dança da Vitória"}
var wardrobe_categories := ["Conjuntos","Cabeças","Máscaras","Peitorais","Calças","Sapatos","Emotes"]
var royale_tab := "Destaques"
var royale_items := ["Guardião Carmesim","Anjo Cósmico","Lenda Neon","Dragão Abissal","UMP Tempestade","XM8 Prisma","Emote Vitória Suprema"]

# Arsenal PUNK
var active_weapon := "UMP"
var weapon_damage := {"UMP":28.0,"XM8":30.0,"Águia do Deserto":48.0,"M1014":22.0,"MP40":19.0}
var weapon_cadence := {"UMP":0.13,"XM8":0.15,"Águia do Deserto":0.38,"M1014":0.48,"MP40":0.075}
var weapon_mag := {"UMP":30,"XM8":30,"Águia do Deserto":7,"M1014":6,"MP40":32}
var weapon_reload := {"UMP":1.5,"XM8":1.7,"Águia do Deserto":1.25,"M1014":1.9,"MP40":1.4}
var weapon_spread := {"UMP":0.012,"XM8":0.009,"Águia do Deserto":0.018,"M1014":0.055,"MP40":0.032}
var weapon_catalog := ["UMP", "XM8", "Águia do Deserto", "M1014", "MP40"]
var weapon_skin_catalog := ["Original", "Dragão de Fogo", "Gelo Eterno", "Ouro Imperial", "Neon Roxo"]
var weapon_skin_owned := {
    "UMP": ["Original"],
    "XM8": ["Original"],
    "Águia do Deserto": ["Original"],
    "M1014": ["Original"],
    "MP40": ["Original"]
}
var weapon_skin_equipped := {
    "UMP": "Original",
    "XM8": "Original",
    "Águia do Deserto": "Original",
    "M1014": "Original",
    "MP40": "Original"
}
var player: CharacterBody3D
var camera: Camera3D
var bots: Array[CharacterBody3D] = []
var bot_hp: Dictionary = {}
var bot_inventory: Dictionary = {}
var bot_t: Dictionary = {}
var loot: Array[Area3D] = []
var hp := MAX_HP
var shield := 0.0
var energy := MAX_ENERGY
var ammo := MAG
var reserve_ammo := 120
var weapon_ammo: Dictionary = {}
var kills := 0
var matches_played := 0
var wins := 0
var losses := 0
var total_kills := 0
var best_kills := 0
var coins := 250
var time_left := START_TIME
var overtime_started := false
var zone := MAP
var zone_tick := 0.0
var shot_tick := 0.0
var reload_tick := 0.0
var reload_total := 0.0
var ability_tick := 0.0
var ability_cd := 0.0
var aim_assist_tick := 0.0
var medkits := 3
var match_done := false
var match_paused := false
var pause_panel:Panel
var match_phase := "lobby_aircraft"
var boarding_time := 20.0
var boarding_label:Label
var jump_button:Button
var yaw := 0.0
var pitch := -0.18
var recoil_kick := 0.0
var joy_id := -1
var joy_start := Vector2.ZERO
var joy_pos := Vector2.ZERO
var look_id := -1
var fire_held := false
var aim_held := false
var current_scope := "Geral"
var sensitivities := {"Geral":100.0,"Ponto vermelho":95.0,"2x":90.0,"4x":80.0,"AWM":50.0,"Olhadinha":100.0}
var graphics_quality := "Padrão"
var fps_mode := "Alto"
var graphics_environment: Environment
var graphics_sun: DirectionalLight3D

var ui: Control
var battle_ui: Control
var hp_text: Label
var ammo_text: Label
var reload_text: Label
var hit_marker: Label
var hit_marker_tick := 0.0
var top_text: Label
var zone_text: Label
var toast: Label
var joy_base: Panel
var joy_knob: Panel
var fire: Button
var aim: Button
var reload: Button
var ability: Button
var medkit: Button
var switch_weapon: Button
var gloo_button: Button
var gloo_charges := 12
var airdrop_spawned := false
var active_gloo_walls: Array[StaticBody3D] = []

var chars := {
    "Kosmos": {"color":Color(0.12,0.32,0.95),"hp":250.0,"ability":"Dragão: 250 HP + 90 escudo / 30s","cd":120.0},
    "Lucas": {"color":Color(0.08,0.75,0.90),"hp":200.0,"ability":"Pulso: rivais próximos ficam lentos","cd":60.0},
    "Cuíca": {"color":Color(0.95,0.55,0.10),"hp":200.0,"ability":"Precisão: dano aumenta com kills","cd":90.0},
    "Danilo": {"color":Color(0.12,0.75,0.30),"hp":250.0,"ability":"Rush: velocidade +50 HP","cd":90.0},
    "Marli": {"color":Color(0.76,0.20,0.62),"hp":200.0,"ability":"Pulso: dano dos rivais reduzido","cd":90.0}
}
var skins := {
    "Kosmos":["Original","Prata","Dragão Negro"],
    "Lucas":["Original","Neon","Gelo"],
    "Cuíca":["Original","Fogo","Ouro"],
    "Danilo":["Original","Verde","Titã"],
    "Marli":["Original","Rosa","Imperial"]
}

func _notification(what:int) -> void:
    if what != NOTIFICATION_WM_CLOSE_REQUEST:
        return
    if mode == "battle" and not match_done:
        # Fechar/sair durante uma partida conta como abandono e derrota.
        if match_phase == "airborne" or match_phase == "landed":
            _end(false)
        _lobby()
        get_tree().set_auto_accept_quit(false)
    else:
        get_tree().quit()

func _ready() -> void:
    get_tree().set_auto_accept_quit(false)
    _load_settings()
    _load_profile()
    _world_lighting()
    _lobby()

func _process(delta:float) -> void:
    if mode == "lobby" or mode == "wardrobe" or mode == "characters":
        var showcase := get_node_or_null("LobbyShowcase/LobbyCharacter") as Node3D
        if showcase:
            showcase.rotation.y += delta * 0.20

func _load_settings() -> void:
    var config := ConfigFile.new()
    if config.load("user://punk_settings.cfg") != OK:
        return
    for name in sensitivities.keys():
        sensitivities[name] = clampf(float(config.get_value("sensitivities", name, sensitivities[name])), 0.0, 200.0)
    graphics_quality = String(config.get_value("graphics", "quality", graphics_quality))
    fps_mode = String(config.get_value("graphics", "fps", fps_mode))
    if not graphics_quality in ["Suave", "Padrão", "Ultra"]:
        graphics_quality = "Padrão"
    if not fps_mode in ["Normal", "Alto", "Ultra"]:
        fps_mode = "Alto"

func _load_profile() -> void:
    var config := ConfigFile.new()
    if config.load("user://punk_profile.cfg") != OK:
        return
    coins = maxi(0, int(config.get_value("profile", "coins", coins)))
    matches_played = maxi(0, int(config.get_value("profile", "matches_played", matches_played)))
    wins = maxi(0, int(config.get_value("profile", "wins", wins)))
    losses = maxi(0, int(config.get_value("profile", "losses", losses)))
    total_kills = maxi(0, int(config.get_value("profile", "total_kills", total_kills)))
    best_kills = maxi(0, int(config.get_value("profile", "best_kills", best_kills)))
    var saved_character := String(config.get_value("profile", "selected", selected))
    if chars.has(saved_character):
        selected = saved_character
    skin = String(config.get_value("profile", "skin", skin))
    if skins.has(selected) and not skin in skins[selected]:
        skin = skins[selected][0]
    active_weapon = String(config.get_value("profile", "active_weapon", active_weapon))
    if not active_weapon in weapon_catalog:
        active_weapon = weapon_catalog[0]
    var saved_royale = config.get_value("profile", "wardrobe_equipped", wardrobe_equipped)
    if saved_royale is Dictionary:
        for category in wardrobe_categories:
            if saved_royale.has(category):
                wardrobe_equipped[category] = String(saved_royale[category])
    var saved_owned = config.get_value("profile", "weapon_skin_owned", weapon_skin_owned)
    if saved_owned is Dictionary:
        for weapon in weapon_catalog:
            if saved_owned.has(weapon) and saved_owned[weapon] is Array:
                weapon_skin_owned[weapon] = saved_owned[weapon].duplicate()
    var saved_equipped = config.get_value("profile", "weapon_skin_equipped", weapon_skin_equipped)
    if saved_equipped is Dictionary:
        for weapon in weapon_catalog:
            if saved_equipped.has(weapon) and saved_equipped[weapon] in weapon_skin_owned[weapon]:
                weapon_skin_equipped[weapon] = String(saved_equipped[weapon])

func _save_profile() -> void:
    var config := ConfigFile.new()
    config.set_value("profile", "coins", coins)
    config.set_value("profile", "matches_played", matches_played)
    config.set_value("profile", "wins", wins)
    config.set_value("profile", "losses", losses)
    config.set_value("profile", "total_kills", total_kills)
    config.set_value("profile", "best_kills", best_kills)
    config.set_value("profile", "selected", selected)
    config.set_value("profile", "skin", skin)
    config.set_value("profile", "active_weapon", active_weapon)
    config.set_value("profile", "wardrobe_equipped", wardrobe_equipped)
    config.set_value("profile", "weapon_skin_owned", weapon_skin_owned)
    config.set_value("profile", "weapon_skin_equipped", weapon_skin_equipped)
    var error := config.save("user://punk_profile.cfg")
    if error != OK:
        push_warning("Não foi possível salvar o perfil: %s" % error)

func _save_settings() -> void:
    var config := ConfigFile.new()
    for name in sensitivities.keys():
        config.set_value("sensitivities", name, sensitivities[name])
    config.set_value("graphics", "quality", graphics_quality)
    config.set_value("graphics", "fps", fps_mode)
    var error := config.save("user://punk_settings.cfg")
    if error != OK:
        push_warning("Não foi possível salvar as configurações: %s" % error)

func _ensure_lobby_camera() -> void:
    var lobby_camera := get_node_or_null("LobbyCamera") as Camera3D
    if lobby_camera == null:
        lobby_camera = Camera3D.new()
        lobby_camera.name = "LobbyCamera"
        lobby_camera.position = Vector3(0, 3.0, 8.0)
        lobby_camera.rotation_degrees = Vector3(-10.0, 0.0, 0.0)
        lobby_camera.fov = 70.0
        add_child(lobby_camera)
    lobby_camera.current = true
    camera = lobby_camera

func _world_lighting() -> void:
    var e := WorldEnvironment.new()
    var env := Environment.new()
    # Céu atmosférico leve: substitui o fundo chapado sem depender de texturas externas.
    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.12, 0.30, 0.48)
    sky_material.sky_horizon_color = Color(0.72, 0.78, 0.76)
    sky_material.ground_bottom_color = Color(0.12, 0.18, 0.16)
    sky_material.ground_horizon_color = Color(0.48, 0.55, 0.48)
    sky_material.sun_angle_max = 18.0
    sky_material.sun_curve = 0.12
    sky.sky_material = sky_material
    env.background_mode = Environment.BG_SKY
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = 0.85
    env.fog_enabled = true
    env.fog_light_color = Color(0.62, 0.72, 0.76)
    env.fog_density = 0.0018
    e.name = "WorldEnvironment"
    e.environment = env
    graphics_environment = env
    add_child(e)
    var sun := DirectionalLight3D.new()
    sun.name = "Sun"
    sun.rotation_degrees = Vector3(-50,-28,0)
    sun.light_energy = 1.4
    # Sombras dinâmicas podem causar tela cinza/preta em alguns drivers mobile.
    sun.shadow_enabled = false
    graphics_sun = sun
    add_child(sun)
    _apply_graphics_settings()

func _reset_ui() -> void:
    # A interface de batalha é recriada ao trocar de tela; descarte referências antigas.
    toast = null
    battle_ui = null
    hp_text = null
    ammo_text = null
    top_text = null
    zone_text = null
    if ui and is_instance_valid(ui):
        var old_layer := ui.get_parent()
        if old_layer and is_instance_valid(old_layer):
            old_layer.queue_free()
    var layer := CanvasLayer.new()
    layer.name = "GameUI"
    layer.layer = 10
    add_child(layer)
    ui = Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(ui)

func _bg(color:Color) -> ColorRect:
    var c := ColorRect.new()
    c.color = color
    c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    c.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(c)
    return c

func _txt(parent:Control, text:String, pos:Vector2, size:Vector2, font:=20) -> Label:
    var l := Label.new()
    l.text=text; l.position=pos; l.size=size
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    l.add_theme_font_size_override("font_size",font)
    l.add_theme_color_override("font_color",Color.WHITE)
    l.add_theme_color_override("font_shadow_color",Color(0,0,0,0.9))
    l.add_theme_constant_override("shadow_offset_x",2)
    l.add_theme_constant_override("shadow_offset_y",2)
    parent.add_child(l)
    return l

func _btn(parent:Control, text:String, pos:Vector2, size:Vector2, color:=Color(0.10,0.40,0.34)) -> Button:
    var b:=Button.new()
    b.text=text; b.position=pos; b.size=size
    b.add_theme_font_size_override("font_size",17)
    b.add_theme_stylebox_override("normal",_style(color,color.lightened(0.35),16))
    b.add_theme_stylebox_override("hover",_style(color.lightened(0.12),Color.WHITE,16))
    b.add_theme_stylebox_override("pressed",_style(color.darkened(0.18),Color.WHITE,16))
    parent.add_child(b)
    return b

func _style(bg:Color,border:Color,r:=16) -> StyleBoxFlat:
    var s:=StyleBoxFlat.new(); s.bg_color=bg; s.border_color=border; s.set_border_width_all(2); s.set_corner_radius_all(r)
    return s

func _lobby() -> void:
    mode = "lobby"
    _clear_world()
    _ensure_lobby_camera()
    _build_lobby_showcase()
    _reset_ui()
    var viewport_size := get_viewport().get_visible_rect().size
    var width:float = viewport_size.x
    var height:float = viewport_size.y
    _bg(Color(0.025, 0.035, 0.045, 0.10))

    # Barra superior: perfil, nível e moedas.
    var top := Panel.new()
    top.position = Vector2(0, 0)
    top.size = Vector2(width, 58)
    top.add_theme_stylebox_override("panel", _style(Color(0.025,0.035,0.045,0.90), Color(0.70,0.49,0.20), 0))
    ui.add_child(top)
    var avatar := Panel.new()
    avatar.position = Vector2(16,7)
    avatar.size = Vector2(44,44)
    avatar.add_theme_stylebox_override("panel",_style(Color(0.13,0.20,0.24),Color(0.95,0.68,0.22),8))
    top.add_child(avatar)
    _txt(avatar,selected.substr(0,1).to_upper(),Vector2(0,2),Vector2(44,38),27).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _txt(top,selected.to_upper(),Vector2(70,7),Vector2(180,23),17)
    _txt(top,"NÍVEL 01  •  %d XP" % (matches_played*120),Vector2(70,30),Vector2(200,18),11).add_theme_color_override("font_color",Color(0.72,0.78,0.80))
    var currency := _txt(top,"🪙 %d     ♦  0" % coins,Vector2(width-235,12),Vector2(215,32),18)
    currency.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

    # Menu lateral compacto, mantendo o personagem livre no centro.
    var left_x := 14.0
    var side_y := 94.0
    var side_h := 43.0
    var side_gap := 9.0
    var left_items := [["EVENTOS","✦"],["LOJA","▣"],["PERSONAGENS","♙"],["COLEÇÃO","▤"]]
    for i in range(left_items.size()):
        var item:Array = left_items[i]
        var b := _btn(ui,str(item[1])+"  "+str(item[0]),Vector2(left_x,side_y+i*(side_h+side_gap)),Vector2(150,side_h),Color(0.035,0.065,0.075,0.88))
        b.add_theme_font_size_override("font_size",14)
        if i == 2: b.pressed.connect(_characters)
        elif i == 3: b.pressed.connect(_royale)
        else: b.pressed.connect(_royale)

    # Painel de modo no lado direito e botão de partida em destaque.
    var right_w := 194.0
    var right_x := width-right_w-14.0
    var mode_panel := Panel.new()
    mode_panel.position = Vector2(right_x, height-184.0)
    mode_panel.size = Vector2(right_w, 112)
    mode_panel.add_theme_stylebox_override("panel",_style(Color(0.035,0.055,0.065,0.92),Color(0.82,0.55,0.17),10))
    ui.add_child(mode_panel)
    _txt(mode_panel,"MODO CLÁSSICO",Vector2(12,9),Vector2(right_w-24,25),17).add_theme_color_override("font_color",Color(1.0,0.78,0.32))
    _txt(mode_panel,"BATTLE ROYALE",Vector2(12,38),Vector2(right_w-24,22),14)
    _txt(mode_panel,"Ilha PUNK  •  Solo",Vector2(12,68),Vector2(right_w-24,20),12).add_theme_color_override("font_color",Color(0.72,0.79,0.80))
    var play := _btn(ui,"▶  COMEÇAR",Vector2(right_x,height-65.0),Vector2(right_w,54),Color(0.88,0.43,0.055))
    play.add_theme_font_size_override("font_size",22)
    play.pressed.connect(_start)

    # Acesso rápido a arsenal e configurações no alto à direita.
    var quick_y := 78.0
    var quick_items := [["ARSENAL",Callable(self,"_inventory")],["CONFIG.",Callable(self,"_settings")]]
    for i in range(quick_items.size()):
        var item:Array = quick_items[i]
        var b := _btn(ui,str(item[0]),Vector2(width-116.0,quick_y+i*43.0),Vector2(102,36),Color(0.035,0.065,0.075,0.88))
        b.add_theme_font_size_override("font_size",12)
        b.pressed.connect(item[1])

    # Navegação inferior em faixa translúcida.
    var nav := Panel.new()
    nav.position = Vector2(0,height-54.0)
    nav.size = Vector2(width-right_w-36.0,54)
    nav.add_theme_stylebox_override("panel",_style(Color(0.025,0.035,0.045,0.86),Color(0.32,0.39,0.40),0))
    ui.add_child(nav)
    var nav_names := ["INÍCIO","COLEÇÃO","PERSONAGEM","ARMAS"]
    var nav_actions := [Callable(self,"_lobby"),Callable(self,"_royale"),Callable(self,"_characters"),Callable(self,"_inventory")]
    var nav_w:float = nav.size.x/float(nav_names.size())
    for i in range(nav_names.size()):
        var b := _btn(nav,nav_names[i],Vector2(i*nav_w+3,7),Vector2(nav_w-6,40),Color(0.08,0.12,0.14,0.92) if i==0 else Color(0.035,0.055,0.065,0.92))
        b.add_theme_font_size_override("font_size",12)
        b.pressed.connect(nav_actions[i])

    var notice := _txt(ui,"TEMPORADA PUNK  •  SOBREVIVA E DOMINE",Vector2(18,height-82.0),Vector2(330,22),12)
    notice.add_theme_color_override("font_color",Color(1.0,0.78,0.34))


func _set_lobby_atmosphere() -> void:
    if graphics_environment == null:
        return
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.012,0.018,0.055)
    sky_mat.sky_horizon_color = Color(0.16,0.055,0.075)
    sky_mat.ground_bottom_color = Color(0.018,0.012,0.025)
    sky_mat.ground_horizon_color = Color(0.075,0.035,0.045)
    sky_mat.sun_angle_max = 0.0
    sky.sky_material = sky_mat
    graphics_environment.background_mode = Environment.BG_SKY
    graphics_environment.sky = sky
    graphics_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    graphics_environment.ambient_light_color = Color(0.20,0.16,0.28)
    graphics_environment.ambient_light_energy = 0.52
    graphics_environment.fog_enabled = true
    graphics_environment.fog_light_color = Color(0.20,0.10,0.16)
    graphics_environment.fog_density = 0.012
    if is_instance_valid(graphics_sun):
        graphics_sun.light_color = Color(0.34,0.30,0.52)
        graphics_sun.light_energy = 0.16

func _set_battle_atmosphere() -> void:
    if graphics_environment == null:
        return
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.12,0.30,0.48)
    sky_mat.sky_horizon_color = Color(0.72,0.78,0.76)
    sky_mat.ground_bottom_color = Color(0.12,0.18,0.16)
    sky_mat.ground_horizon_color = Color(0.48,0.55,0.48)
    sky_mat.sun_angle_max = 18.0
    sky_mat.sun_curve = 0.12
    sky.sky_material = sky_mat
    graphics_environment.background_mode = Environment.BG_SKY
    graphics_environment.sky = sky
    graphics_environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    graphics_environment.ambient_light_energy = 0.85
    graphics_environment.fog_light_color = Color(0.62,0.72,0.76)
    graphics_environment.fog_density = 0.0018
    if is_instance_valid(graphics_sun):
        graphics_sun.light_color = Color.WHITE
        graphics_sun.light_energy = 1.4

func _build_lobby_showcase() -> void:
    var old := get_node_or_null("LobbyShowcase")
    if old:
        old.queue_free()
    _set_lobby_atmosphere()
    var stage := Node3D.new()
    stage.name = "LobbyShowcase"
    add_child(stage)

    # Arena costeira futurista: sem a mansão/decoração de Halloween do protótipo.
    var ocean_mat := _mat(Color("#071D32"),0.28,0.22)
    var island_mat := _mat(Color("#182C38"),0.92,0.0)
    var dark_metal := _mat(Color("#101B2A"),0.34,0.72)
    var panel_mat := _mat(Color("#20394A"),0.38,0.55)
    var gold_mat := _mat(Color("#F6C34A"),0.30,0.48)
    var cyan_mat := StandardMaterial3D.new()
    cyan_mat.albedo_color = Color("#42D7E8")
    cyan_mat.emission_enabled = true
    cyan_mat.emission = Color("#159CB7")
    cyan_mat.emission_energy_multiplier = 1.15

    var ocean := MeshInstance3D.new()
    var ocean_mesh := PlaneMesh.new()
    ocean_mesh.size = Vector2(180,180)
    ocean_mesh.material = ocean_mat
    ocean.mesh = ocean_mesh
    ocean.position = Vector3(0,-1.35,-24)
    stage.add_child(ocean)

    var island := MeshInstance3D.new()
    var island_mesh := CylinderMesh.new()
    island_mesh.top_radius = 25.0
    island_mesh.bottom_radius = 29.0
    island_mesh.height = 2.4
    island_mesh.radial_segments = 64
    island_mesh.material = island_mat
    island.mesh = island_mesh
    island.position = Vector3(0,-0.35,-12)
    stage.add_child(island)

    # Plataforma central circular com anéis luminosos.
    var base := MeshInstance3D.new()
    var base_mesh := CylinderMesh.new()
    base_mesh.top_radius = 5.4
    base_mesh.bottom_radius = 5.8
    base_mesh.height = 0.42
    base_mesh.radial_segments = 64
    base_mesh.material = dark_metal
    base.mesh = base_mesh
    base.position = Vector3(0,0.72,0.2)
    stage.add_child(base)
    var deck := MeshInstance3D.new()
    var deck_mesh := CylinderMesh.new()
    deck_mesh.top_radius = 5.05
    deck_mesh.bottom_radius = 5.05
    deck_mesh.height = 0.08
    deck_mesh.radial_segments = 64
    deck_mesh.material = panel_mat
    deck.mesh = deck_mesh
    deck.position = Vector3(0,0.96,0.2)
    stage.add_child(deck)

    for radius in [4.55,5.25]:
        var ring := MeshInstance3D.new()
        var ring_mesh := TorusMesh.new()
        ring_mesh.inner_radius = radius-0.035
        ring_mesh.outer_radius = radius+0.035
        ring_mesh.rings = 8
        ring_mesh.ring_segments = 64
        ring_mesh.material = cyan_mat if radius < 5.0 else gold_mat
        ring.mesh = ring_mesh
        ring.position = Vector3(0,1.02,0.2)
        stage.add_child(ring)

    # Painéis e pilares de uma base militar tecnológica ao fundo.
    for side in [-1.0,1.0]:
        var pillar := _box(stage,Vector3(0.48,5.2,0.55),Vector3(side*8.2,2.55,-13.5),dark_metal)
        pillar.rotation.z = side*0.06
        _box(stage,Vector3(3.4,0.18,0.32),Vector3(side*6.5,4.9,-13.1),gold_mat)
        _box(stage,Vector3(2.5,2.5,0.22),Vector3(side*6.3,2.5,-13.0),panel_mat)
        _box(stage,Vector3(0.08,2.0,0.08),Vector3(side*6.3,2.5,-12.86),cyan_mat)

    var gateway := _box(stage,Vector3(7.2,0.32,0.42),Vector3(0,5.35,-13.3),dark_metal)
    gateway.rotation.z = 0.0
    _box(stage,Vector3(5.6,0.08,0.12),Vector3(0,5.15,-13.02),cyan_mat)

    # Montanhas ao horizonte para dar profundidade à ilha.
    for i in range(9):
        var mountain := MeshInstance3D.new()
        var mountain_mesh := CylinderMesh.new()
        mountain_mesh.top_radius = 0.0
        mountain_mesh.bottom_radius = 7.0+float(i%3)*2.0
        mountain_mesh.height = 11.0+float(i%4)*2.0
        mountain_mesh.radial_segments = 5
        mountain_mesh.material = _mat(Color("#142D40") if i%2==0 else Color("#1B3B4B"),0.95)
        mountain.mesh = mountain_mesh
        mountain.position = Vector3(-34.0+float(i)*8.5,3.5,-43.0-float(i%3)*2.0)
        stage.add_child(mountain)

    # Palmeiras estilizadas nas laterais, deixando o personagem livre no centro.
    for side in [-1.0,1.0]:
        for i in range(3):
            var px := side*(11.0+float(i%2)*4.0)
            var pz := -3.0-float(i)*6.0
            var trunk := MeshInstance3D.new()
            var trunk_mesh := CylinderMesh.new()
            trunk_mesh.top_radius = 0.16
            trunk_mesh.bottom_radius = 0.34
            trunk_mesh.height = 5.8
            trunk_mesh.radial_segments = 10
            trunk_mesh.material = _mat(Color("#594B3B"),0.95)
            trunk.mesh = trunk_mesh
            trunk.position = Vector3(px,2.9,pz)
            trunk.rotation.z = -side*0.10
            stage.add_child(trunk)
            for leaf in range(5):
                var frond := MeshInstance3D.new()
                var frond_mesh := SphereMesh.new()
                frond_mesh.radius = 1.0
                frond_mesh.height = 0.22
                frond_mesh.radial_segments = 10
                frond_mesh.rings = 5
                frond_mesh.material = _mat(Color("#167B70"),0.8)
                frond.mesh = frond_mesh
                frond.scale = Vector3(1.8,0.48,0.42)
                frond.position = Vector3(px+cos(float(leaf)*TAU/5.0)*1.25,5.65,pz+sin(float(leaf)*TAU/5.0)*1.25)
                frond.rotation.y = -float(leaf)*TAU/5.0
                frond.rotation.z = side*0.22
                stage.add_child(frond)

    # Luzes de pista e pequenos terminais laterais.
    for side in [-1.0,1.0]:
        for i in range(4):
            var z := 2.0-float(i)*3.0
            _box(stage,Vector3(0.12,0.7,0.12),Vector3(side*6.8,1.2,z),dark_metal)
            _box(stage,Vector3(0.32,0.08,0.32),Vector3(side*6.8,1.58,z),cyan_mat)
        _box(stage,Vector3(1.2,1.8,0.65),Vector3(side*9.0,0.95,-1.5),panel_mat)
        _box(stage,Vector3(0.08,1.1,0.08),Vector3(side*8.35,1.0,-1.5),gold_mat)

    # Personagem em primeiro plano, com iluminação de recorte.
    var model := Node3D.new()
    model.name = "LobbyCharacter"
    model.position = Vector3(0,1.02,0.28)
    model.scale = Vector3(1.72,1.72,1.72)
    stage.add_child(model)
    _build_player_armor(model)
    _build_weapon_model(model)

    var key_light := OmniLight3D.new()
    key_light.position = Vector3(0,4.2,4.0)
    key_light.light_color = Color("#FFE1B0")
    key_light.light_energy = 2.1
    key_light.omni_range = 13.0
    stage.add_child(key_light)
    var rim_light := OmniLight3D.new()
    rim_light.position = Vector3(-4.5,4.0,-4.0)
    rim_light.light_color = Color("#42D7E8")
    rim_light.light_energy = 2.6
    rim_light.omni_range = 14.0
    stage.add_child(rim_light)
    var warm_light := OmniLight3D.new()
    warm_light.position = Vector3(5.0,3.0,-8.0)
    warm_light.light_color = Color("#F6C34A")
    warm_light.light_energy = 1.5
    warm_light.omni_range = 12.0
    stage.add_child(warm_light)

    var lobby_camera := get_node_or_null("LobbyCamera") as Camera3D
    if lobby_camera:
        lobby_camera.position = Vector3(0,2.15,6.7)
        lobby_camera.look_at(Vector3(0,1.75,-3.0),Vector3.UP)
        lobby_camera.fov = 52

func _royale() -> void:
    mode = "royale"
    _reset_ui()
    _bg(Color(0.025,0.008,0.025))
    _txt(ui,"ROYALE  •  GIRO PREMIADO",Vector2(24,18),Vector2(700,42),30).add_theme_color_override("font_color",Color(1.0,0.70,0.22))
    _txt(ui,"RECOMPENSAS VISUAIS ORIGINAIS",Vector2(26,60),Vector2(700,25),14)
    var tabs := ["Destaques","Roupas","Emotes","Armas"]
    for i in range(tabs.size()):
        var b := _btn(ui,tabs[i],Vector2(18+i*(get_viewport().size.x-36)/4,100),Vector2((get_viewport().size.x-48)/4,43),Color(0.48,0.20,0.08) if royale_tab==tabs[i] else Color(0.13,0.12,0.20))
        b.pressed.connect(_royale_select_tab.bind(tabs[i]))
    for i in range(6):
        var item:String = royale_items[(i+tabs.find(royale_tab)*2)%royale_items.size()]
        var x: float = 22.0 + float(i % 2) * (get_viewport().size.x / 2.0)
        var y := 170+int(i/2)*125
        var card:=Panel.new()
        card.position=Vector2(x,y); card.size=Vector2(get_viewport().size.x/2-34,108)
        card.add_theme_stylebox_override("panel",_style(Color(0.12,0.045,0.12),Color(0.85,0.48,0.16),12)); ui.add_child(card)
        _txt(card,"✦  "+item,Vector2(10,12),Vector2(card.size.x-20,45),15)
        var buy:=_btn(card,"RESGATAR • 100 MOEDAS",Vector2(10,65),Vector2(card.size.x-20,34),Color(0.52,0.25,0.07))
        buy.pressed.connect(_royale_claim.bind(item))
    var back:=_btn(ui,"← LOBBY",Vector2(24,get_viewport().size.y-58),Vector2(140,42),Color(0.18,0.20,0.24))
    back.pressed.connect(_lobby)

func _royale_select_tab(tab:String) -> void:
    royale_tab=tab
    _royale()

func _royale_claim(item:String) -> void:
    if coins < 100:
        _toast("MOEDAS INSUFICIENTES")
        return
    coins -= 100
    wardrobe_equipped["Conjuntos" if royale_tab=="Roupas" else ("Emotes" if royale_tab=="Emotes" else "Conjuntos")] = item
    _save_profile()
    _toast("RECOMPENSA DESBLOQUEADA: "+item)
    _royale()

func _characters() -> void:
    mode="characters"; _reset_ui(); _bg(Color(0.012,0.022,0.036))
    _txt(ui,"PERSONAGENS",Vector2(28,24),Vector2(500,50),34).add_theme_color_override("font_color",Color(0.30,0.95,0.82))
    _txt(ui,"Escolha personagem e skin para a próxima partida",Vector2(30,70),Vector2(700,30),16)
    for i in range(chars.keys().size()):
        var n:String=chars.keys()[i]; var b:=_btn(ui,n,Vector2(24+i*134,116),Vector2(124,50),chars[n]["color"]*0.72); b.pressed.connect(_pick_char.bind(n))
    var card:=Panel.new(); card.position=Vector2(25,188); card.size=Vector2(get_viewport().size.x-50,220); card.add_theme_stylebox_override("panel",_style(Color(0.03,0.055,0.08),Color(0.20,0.50,0.52),20)); ui.add_child(card)
    var portrait:=TextureRect.new()
    portrait.position=Vector2(18,12)
    portrait.size=Vector2(150,194)
    portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
    var portrait_key:String = String({"Kosmos":"kosmos","Lucas":"lucas","Cuíca":"cuica","Danilo":"danilo","Marli":"marli"}.get(selected,"kosmos"))
    portrait.texture=load("res://assets/skins/"+portrait_key+".svg")
    portrait.modulate=Color(1.0,1.0,1.0) if skin=="Original" else (Color(0.78,0.90,1.0) if skin in ["Prata","Gelo"] else (Color(1.0,0.82,0.62) if skin in ["Fogo","Ouro","Dragão Negro"] else Color(0.90,0.76,1.0)))
    card.add_child(portrait)
    var nm:=_txt(card,selected,Vector2(190,28),Vector2(400,42),30); nm.add_theme_color_override("font_color",chars[selected]["color"])
    _txt(card,"HP base: %d"%int(chars[selected]["hp"]),Vector2(180,78),Vector2(400,30),18)
    _txt(card,chars[selected]["ability"],Vector2(180,116),Vector2(650,55),16)
    _txt(ui,"SKINS",Vector2(30,435),Vector2(200,35),22)
    for i in range(skins[selected].size()):
        var s:String=skins[selected][i]; var b:=_btn(ui,s,Vector2(30+i*155,480),Vector2(142,52),Color(0.12,0.17,0.23)); b.pressed.connect(_pick_skin.bind(s))
    var back:=_btn(ui,"← VOLTAR",Vector2(30,get_viewport().size.y-72),Vector2(150,50),Color(0.18,0.20,0.24)); back.pressed.connect(_lobby)
    var go:=_btn(ui,"▶ JOGAR COM "+selected,Vector2(get_viewport().size.x-310,get_viewport().size.y-72),Vector2(280,50),Color(0.08,0.50,0.37)); go.pressed.connect(_start)

func _pick_char(n:String) -> void: selected=n; skin=skins[n][0]; _save_profile(); _characters()
func _pick_skin(s:String) -> void: skin=s; _save_profile(); _characters()

func _inventory() -> void:
    mode = "inventory"
    _reset_ui()
    _bg(Color(0.012, 0.02, 0.03))
    _txt(ui, "PUNK • ARSENAL E SKINS", Vector2(25, 18), Vector2(700, 45), 29)
    _txt(ui, "Moedas: %d" % coins, Vector2(28, 62), Vector2(350, 30), 19)
    _txt(ui, "ESCOLHA SUA ARMA", Vector2(28, 101), Vector2(400, 30), 18)

    var width: float = get_viewport().size.x
    for i in range(weapon_catalog.size()):
        var w: String = weapon_catalog[i]
        var bw: float = width / 5.0 - 8.0
        var b := _btn(ui, w, Vector2(8 + i * width / 5.0, 139), Vector2(bw, 46), Color(0.08, 0.50, 0.37) if active_weapon == w else Color(0.12, 0.25, 0.32))
        b.pressed.connect(_select_weapon.bind(w))

    _txt(ui, "SKINS • " + active_weapon.to_upper(), Vector2(25, 199), Vector2(500, 32), 21)
    for i in range(weapon_skin_catalog.size()):
        var sn: String = weapon_skin_catalog[i]
        var owned: bool = sn in weapon_skin_owned[active_weapon]
        var equipped: bool = weapon_skin_equipped[active_weapon] == sn
        var y := 239 + i * 66
        var panel := Panel.new()
        panel.position = Vector2(24, y)
        panel.size = Vector2(width - 48, 57)
        var tint := Color(0.04, 0.08, 0.10)
        match sn:
            "Dragão de Fogo":
                tint = Color(0.30, 0.07, 0.045)
            "Gelo Eterno":
                tint = Color(0.045, 0.18, 0.32)
            "Ouro Imperial":
                tint = Color(0.30, 0.22, 0.045)
            "Neon Roxo":
                tint = Color(0.20, 0.055, 0.30)
        panel.add_theme_stylebox_override("panel", _style(tint, Color(0.20, 0.50, 0.52), 12))
        ui.add_child(panel)
        _txt(panel, sn, Vector2(12, 12), Vector2(240, 32), 17)
        var label := "EQUIPADA" if equipped else ("EQUIPAR" if owned else "COMPRAR • 100 MOEDAS")
        var btn := _btn(panel, label, Vector2(width - 260, 6), Vector2(220, 44), Color(0.08, 0.50, 0.37) if owned else Color(0.42, 0.24, 0.08))
        btn.disabled = equipped
        btn.pressed.connect(_weapon_skin_action.bind(sn))

    var back := _btn(ui, "VOLTAR", Vector2(25, get_viewport().size.y - 62), Vector2(145, 45), Color(0.18, 0.20, 0.24))
    back.pressed.connect(_lobby)

func _select_weapon(w: String) -> void:
    active_weapon = w
    _save_profile()
    _inventory()

func _weapon_skin_action(sn: String) -> void:
    if sn in weapon_skin_owned[active_weapon]:
        weapon_skin_equipped[active_weapon] = sn
        _save_profile()
        _refresh_weapon_model()
        _inventory()
    elif coins >= 100:
        coins -= 100
        weapon_skin_owned[active_weapon].append(sn)
        weapon_skin_equipped[active_weapon] = sn
        _save_profile()
        _refresh_weapon_model()
        _inventory()
    else:
        _toast("MOEDAS INSUFICIENTES!")
        _inventory()


func _settings() -> void:
    mode="settings"; _reset_ui(); _bg(Color(0.012,0.018,0.028))
    _txt(ui,"CONFIGURAÇÕES",Vector2(24,16),Vector2(600,44),30)
    _txt(ui,"SENSIBILIDADE  •  AJUSTE DE 0 A 200",Vector2(26,62),Vector2(700,28),16)
    var names := ["Geral","Ponto vermelho","2x","4x","AWM","Olhadinha"]
    var width := get_viewport().get_visible_rect().size.x
    for i in range(names.size()):
        var name:String = names[i]
        var y := 105.0 + i*66.0
        var label := _txt(ui,name.to_upper()+"  •  "+str(int(sensitivities[name])),Vector2(26,y),Vector2(width-52,24),16)
        var slider := HSlider.new()
        slider.min_value=0; slider.max_value=200; slider.step=1; slider.value=sensitivities[name]
        slider.position=Vector2(24,y+27); slider.size=Vector2(width-48,28)
        slider.value_changed.connect(_set_sensitivity.bind(name,label))
        ui.add_child(slider)
    _txt(ui,"MIRA GRUDADA: assistência ao mirar nos rivais próximos",Vector2(26,510),Vector2(width-52,28),13)
    _txt(ui,"GRÁFICOS",Vector2(26,542),Vector2(170,26),16).add_theme_color_override("font_color",Color(1.0,0.78,0.30))
    var quality_label := _txt(ui,"QUALIDADE",Vector2(26,572),Vector2(130,28),14)
    var quality_option := OptionButton.new()
    quality_option.position = Vector2(150,568)
    quality_option.size = Vector2(180,38)
    for option in ["Suave","Padrão","Ultra"]:
        quality_option.add_item(option)
    quality_option.select(["Suave","Padrão","Ultra"].find(graphics_quality))
    quality_option.item_selected.connect(_set_graphics_quality)
    ui.add_child(quality_option)
    _txt(ui,"FPS",Vector2(width*0.56,572),Vector2(60,28),14)
    var fps_option := OptionButton.new()
    fps_option.position = Vector2(width*0.56+58,568)
    fps_option.size = Vector2(150,38)
    for option in ["Normal","Alto","Ultra"]:
        fps_option.add_item(option)
    fps_option.select(["Normal","Alto","Ultra"].find(fps_mode))
    fps_option.item_selected.connect(_set_fps_mode)
    ui.add_child(fps_option)
    _txt(ui,"Suave prioriza desempenho • Ultra prioriza efeitos visuais",Vector2(26,612),Vector2(width-52,24),12).add_theme_color_override("font_color",Color(0.70,0.76,0.80))
    var back:=_btn(ui,"← VOLTAR",Vector2(24,get_viewport().size.y-62),Vector2(150,46),Color(0.18,0.20,0.24)); back.pressed.connect(_lobby)

func _set_graphics_quality(index:int) -> void:
    graphics_quality = ["Suave","Padrão","Ultra"][clampi(index,0,2)]
    _apply_graphics_settings()
    _save_settings()
    _toast("GRÁFICOS: "+graphics_quality.to_upper())

func _set_fps_mode(index:int) -> void:
    fps_mode = ["Normal","Alto","Ultra"][clampi(index,0,2)]
    _apply_graphics_settings()
    _save_settings()
    _toast("LIMITE DE FPS: "+fps_mode.to_upper())

func _apply_graphics_settings() -> void:
    var low := graphics_quality == "Suave"
    var ultra := graphics_quality == "Ultra"
    Engine.max_fps = 30 if fps_mode == "Normal" else (120 if fps_mode == "Ultra" else 60)
    var viewport := get_viewport()
    if viewport:
        viewport.scaling_3d_scale = 0.72 if low else (1.0 if ultra else 0.88)
    if graphics_environment:
        graphics_environment.ambient_light_energy = 0.78 if low else (1.05 if ultra else 0.9)
        graphics_environment.fog_enabled = ultra
        graphics_environment.fog_light_color = Color(0.48,0.60,0.65)
        graphics_environment.fog_density = 0.0018 if ultra else 0.0
        graphics_environment.glow_enabled = ultra
    if graphics_sun:
        graphics_sun.shadow_enabled = ultra
        graphics_sun.light_energy = 1.15 if low else (1.55 if ultra else 1.4)

func _set_sensitivity(value:float,name:String,label:Label) -> void:
    sensitivities[name]=clampf(value,0.0,200.0)
    label.text=name.to_upper()+"  •  "+str(int(sensitivities[name]))
    _save_settings()

func _start() -> void:
    # Cada partida começa com estado limpo; perfil e moedas ficam persistidos.
    fire_held=false
    aim_held=false
    match_done=false
    match_paused=false
    pause_panel=null
    match_phase="lobby_aircraft"
    boarding_time=20.0
    kills=0
    gloo_charges=12
    active_gloo_walls.clear()
    airdrop_spawned=false
    hp=_max_player_hp()
    shield=0
    energy=MAX_ENERGY
    medkits=3
    reserve_ammo=120
    weapon_ammo.clear()
    ammo=_mag_size()
    weapon_ammo[active_weapon]=ammo
    time_left=START_TIME
    overtime_started=false
    zone=MAP
    zone_tick=0.0
    shot_tick=0.0
    reload_tick=0.0
    reload_total=0.0
    ability_tick=0.0
    ability_cd=0.0
    mode = "battle"
    _reset_ui()
    _clear_world()
    _build_map()
    _set_battle_atmosphere()
    _player()
    ammo=_mag_size()
    reserve_ammo=120
    _battle_ui()
    _bots()
    _loot()
    _layout_battle()
    _build_aircraft_lobby()
    _hud()
    _toast("EMBARQUE CONCLUÍDO — AGUARDE O SALTO")

func _build_aircraft_lobby() -> void:
    # Cabine simples do avião de transporte ao redor do jogador.
    var cabin:=Node3D.new()
    cabin.name="AircraftCabin"
    cabin.position=player.global_position
    add_child(cabin)
    _box(cabin,Vector3(5.2,0.22,12.0),Vector3(0,-0.12,0),_mat(Color(0.12,0.15,0.19),0.55,0.45))
    _box(cabin,Vector3(5.2,0.18,12.0),Vector3(0,3.1,0),_mat(Color(0.08,0.11,0.15),0.5,0.35))
    for side in [-1.0,1.0]:
        _box(cabin,Vector3(0.18,3.1,12.0),Vector3(side*2.55,1.45,0),_mat(Color(0.20,0.25,0.30),0.5,0.4))
        for z in [-4.0,-1.5,1.0,3.5]:
            _box(cabin,Vector3(0.08,1.0,1.5),Vector3(side*2.43,2.0,z),_mat(Color(0.12,0.42,0.58),0.25,0.25))
    var title:=_txt(battle_ui,"AVIÃO DE TRANSPORTE",Vector2(0,90),Vector2(get_viewport().size.x,42),25)
    title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_color_override("font_color",Color(0.35,0.92,1.0))
    boarding_label=_txt(battle_ui,"DECOLAGEM EM 20",Vector2(0,140),Vector2(get_viewport().size.x,48),30)
    boarding_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    jump_button=_btn(battle_ui,"🪂  SALTAR DO AVIÃO",Vector2.ZERO,Vector2(250,58),Color(0.08,0.48,0.34))
    jump_button.position=Vector2(get_viewport().size.x/2-125,get_viewport().size.y*0.72)
    jump_button.disabled=true
    jump_button.pressed.connect(_jump_from_aircraft)
    for control in [fire,switch_weapon,reload,ability,medkit,aim,gloo_button,joy_base,joy_knob]:
        control.visible=false

func _jump_from_aircraft() -> void:
    if match_phase!="ready_to_jump":
        return
    match_phase="airborne"
    if is_instance_valid(jump_button): jump_button.queue_free()
    if is_instance_valid(boarding_label): boarding_label.queue_free()
    var cabin=get_node_or_null("AircraftCabin")
    if cabin: cabin.queue_free()
    player.global_position=Vector3(randf_range(-185.0,185.0),34.0,randf_range(-185.0,185.0))
    player.velocity=Vector3(0,-1.0,0)
    var canopy:=MeshInstance3D.new()
    canopy.name="ParachuteCanopy"
    var canopy_mesh:=SphereMesh.new()
    canopy_mesh.radius=2.1
    canopy_mesh.height=1.25
    canopy_mesh.radial_segments=20
    canopy_mesh.rings=8
    canopy.mesh=canopy_mesh
    canopy.position=Vector3(0,4.0,0)
    canopy.scale=Vector3(1.0,0.38,1.0)
    canopy.material_override=_mat(Color(0.92,0.18,0.12))
    player.add_child(canopy)
    for control in [fire,switch_weapon,reload,ability,medkit,aim]:
        control.visible=false
    joy_base.visible=true
    joy_knob.visible=true
    _toast("PARAQUEDAS ABERTO — USE O JOYSTICK PARA DIRECIONAR")

func _clear_world() -> void:
    # Limpa também objetos temporários de fases interrompidas.
    var cabin=get_node_or_null("AircraftCabin")
    if cabin: cabin.queue_free()
    if player and is_instance_valid(player):
        var canopy=player.get_node_or_null("ParachuteCanopy")
        if canopy: canopy.queue_free()
        player.queue_free()
    if pause_panel and is_instance_valid(pause_panel): pause_panel.queue_free()
    pause_panel=null
    match_paused=false
    for b in bots: if is_instance_valid(b): b.queue_free()
    for l in loot: if is_instance_valid(l): l.queue_free()
    bots.clear(); loot.clear(); bot_hp.clear(); bot_t.clear(); bot_inventory.clear()
    var map=get_node_or_null("Map"); if map: map.queue_free()

func _build_map() -> void:
    # Ilha PUNK: mapa 420 x 420, com nove áreas urbanas e estradas conectando as cidades.
    var map:=Node3D.new()
    map.name="Map"
    add_child(map)

    # Oceano ao redor da ilha para dar profundidade ao horizonte.
    var ocean := MeshInstance3D.new()
    ocean.name = "Ocean"
    var ocean_mesh := PlaneMesh.new()
    ocean_mesh.size = Vector2(900, 900)
    var ocean_material := _mat(Color(0.035, 0.20, 0.29), 0.22, 0.18)
    ocean_material.metallic = 0.12
    ocean_material.roughness = 0.24
    ocean_mesh.material = ocean_material
    ocean.mesh = ocean_mesh
    ocean.position.y = -1.15
    map.add_child(ocean)

    # Faixa de areia costeira em quatro lados da ilha.
    var beach_material := _mat(Color(0.62, 0.53, 0.35), 0.96)
    _box(map, Vector3(420, 0.08, 7), Vector3(0, 0.015, -205), beach_material)
    _box(map, Vector3(420, 0.08, 7), Vector3(0, 0.015, 205), beach_material)
    _box(map, Vector3(7, 0.08, 406), Vector3(-205, 0.015, 0), beach_material)
    _box(map, Vector3(7, 0.08, 406), Vector3(205, 0.015, 0), beach_material)

    # Rochas costeiras de baixa contagem de polígonos.
    for i in range(28):
        var angle := TAU * float(i) / 28.0
        var rock := MeshInstance3D.new()
        var rock_mesh := SphereMesh.new()
        rock_mesh.radius = randf_range(2.0, 4.0)
        rock_mesh.height = randf_range(2.0, 4.5)
        rock_mesh.radial_segments = 7
        rock_mesh.rings = 4
        rock_mesh.material = _mat(Color(0.30, 0.35, 0.34), 1.0)
        rock.mesh = rock_mesh
        rock.position = Vector3(cos(angle) * 207.0, 0.4, sin(angle) * 207.0)
        rock.scale = Vector3(1.4, 0.7, 1.0)
        map.add_child(rock)

    var floor:=StaticBody3D.new()
    floor.name="Terrain"
    map.add_child(floor)
    var pm:=PlaneMesh.new()
    pm.size=Vector2(420,420)
    pm.subdivide_width=32
    pm.subdivide_depth=32
    pm.material=_mat(Color(0.19,0.34,0.19))
    var ground:=MeshInstance3D.new()
    ground.mesh=pm
    floor.add_child(ground)
    var ground_collision:=CollisionShape3D.new()
    var ground_shape:=BoxShape3D.new()
    ground_shape.size=Vector3(420,0.5,420)
    ground_collision.shape=ground_shape
    ground_collision.position.y=-0.25
    floor.add_child(ground_collision)

    # Rodovias principais e vias secundárias.
    var asphalt:=_mat(Color(0.105,0.12,0.13),0.94)
    var road_line:=_mat(Color(0.94,0.78,0.28),0.6)
    _box(map,Vector3(15,0.045,410),Vector3.ZERO,asphalt)
    _box(map,Vector3(410,0.045,15),Vector3.ZERO,asphalt)
    for z in range(-198,199,12):
        _box(map,Vector3(0.22,0.055,5.0),Vector3(0,0.06,z),road_line)
    for x in range(-198,199,12):
        _box(map,Vector3(5.0,0.055,0.22),Vector3(x,0.06,0),road_line)

    # Cidades e locais de pouso distribuídos por toda a ilha.
    var towns=[
        {"name":"NOVA AURORA","pos":Vector2(-145,-145),"wall":Color(0.68,0.62,0.49),"roof":Color(0.30,0.16,0.13)},
        {"name":"PORTO BRAVO","pos":Vector2(0,-155),"wall":Color(0.54,0.66,0.69),"roof":Color(0.13,0.24,0.31)},
        {"name":"VALE VERDE","pos":Vector2(145,-145),"wall":Color(0.57,0.68,0.49),"roof":Color(0.22,0.28,0.15)},
        {"name":"VILA RUBRA","pos":Vector2(-155,0),"wall":Color(0.72,0.51,0.39),"roof":Color(0.38,0.14,0.11)},
        {"name":"CENTRO PUNK","pos":Vector2(0,0),"wall":Color(0.57,0.61,0.67),"roof":Color(0.12,0.15,0.22)},
        {"name":"CIDADE ALTA","pos":Vector2(155,0),"wall":Color(0.64,0.62,0.52),"roof":Color(0.25,0.20,0.15)},
        {"name":"SANTA NEVE","pos":Vector2(-145,145),"wall":Color(0.67,0.73,0.76),"roof":Color(0.22,0.32,0.39)},
        {"name":"DESERTO 9","pos":Vector2(0,155),"wall":Color(0.76,0.62,0.40),"roof":Color(0.43,0.25,0.13)},
        {"name":"BAÍA SOMBRIA","pos":Vector2(145,145),"wall":Color(0.48,0.59,0.59),"roof":Color(0.12,0.19,0.23)}
    ]
    for town in towns:
        _build_town(map,town["name"],town["pos"],town["wall"],town["roof"])

    # Vilarejos menores e postos de combate entre as cidades.
    var outposts=[Vector2(-75,-90),Vector2(78,-85),Vector2(-82,82),Vector2(82,88),Vector2(0,-78),Vector2(-78,0),Vector2(78,0),Vector2(0,82)]
    for i in range(outposts.size()):
        var center:=Vector3(outposts[i].x,0,outposts[i].y)
        for j in range(3):
            var offset:=Vector3(float(j-1)*8.0,0,float((j%2)*9-4))
            _house(map,center+offset,Vector3(7.0,3.8,6.5),Color(0.56,0.57,0.49),Color(0.24,0.20,0.16))

    # Vegetação e cobertura em áreas rurais, sem bloquear os centros das cidades.
    var foliage_count:int = 110 if graphics_quality == "Suave" else (360 if graphics_quality == "Ultra" else 220)
    for i in range(foliage_count):
        var pos:=Vector3(randf_range(-202,202),0,randf_range(-202,202))
        var near_road:bool = abs(pos.x)<10.0 or abs(pos.z)<10.0
        var near_town:bool = false
        for town in towns:
            var c:Vector2=town["pos"]
            if Vector2(pos.x,pos.z).distance_to(c)<25.0:
                near_town=true
                break
        if near_road or near_town:
            continue
        if randf()<0.78:
            _tree(map,pos)
        else:
            _crate(map,pos,randf_range(0.8,1.7))

    # Limites físicos da ilha.
    _wall(map,Vector3(-210,1,0),Vector3(1.5,2.5,420))
    _wall(map,Vector3(210,1,0),Vector3(1.5,2.5,420))
    _wall(map,Vector3(0,1,-210),Vector3(420,2.5,1.5))
    _wall(map,Vector3(0,1,210),Vector3(420,2.5,1.5))

func _build_town(parent:Node3D,town_name:String,center:Vector2,wall_color:Color,roof_color:Color)->void:
    var town:=Node3D.new()
    town.name=town_name.replace(" ","_")
    town.position=Vector3(center.x,0,center.y)
    parent.add_child(town)

    # Placa de identificação visível durante a aproximação.
    var sign:=Label3D.new()
    sign.text=town_name
    sign.position=Vector3(0,11,0)
    sign.font_size=52
    sign.pixel_size=0.012
    sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED
    sign.modulate=Color(0.9,0.96,1.0)
    town.add_child(sign)

    var road_mat:=_mat(Color(0.12,0.13,0.14),0.95)
    _box(town,Vector3(8,0.04,62),Vector3.ZERO,road_mat)
    _box(town,Vector3(62,0.04,8),Vector3.ZERO,road_mat)

    var positions=[
        Vector3(-19,0,-18),Vector3(18,0,-19),Vector3(-19,0,18),Vector3(19,0,18),
        Vector3(-34,0,0),Vector3(34,0,0),Vector3(0,0,-34),Vector3(0,0,34)
    ]
    for i in range(positions.size()):
        var pos:Vector3=positions[i]
        var height:=randf_range(4.0,7.0) if i<4 else randf_range(3.5,5.0)
        var size:=Vector3(randf_range(8.0,11.0),height,randf_range(8.0,11.0))
        var roof:=roof_color.lerp(Color(0.12,0.15,0.19),randf_range(0.0,0.22))
        _house(town,pos,size,wall_color,roof)
        if i%2==0:
            _crate(town,pos+Vector3(6,0,5),1.3)

    # Torres, postes e caixas dão silhueta própria a cada região.
    _box(town,Vector3(2.2,13.0,2.2),Vector3(-27,6.5,-27),_mat(Color(0.25,0.30,0.34),0.45,0.35))
    _box(town,Vector3(5.0,0.8,5.0),Vector3(-27,13.2,-27),_mat(Color(0.85,0.55,0.16),0.35,0.3))

func _mat(c:Color,r:=0.8,m:=0.0)->StandardMaterial3D:
    var x:=StandardMaterial3D.new(); x.albedo_color=c; x.roughness=r; x.metallic=m; return x
func _box(parent:Node,size:Vector3,pos:Vector3,mat:Material)->MeshInstance3D:
    var m:=MeshInstance3D.new(); var b:=BoxMesh.new(); b.size=size; b.material=mat; m.mesh=b; m.position=pos; parent.add_child(m); return m
func _wall(parent:Node,pos:Vector3,size:Vector3)->void:
    var b:=StaticBody3D.new(); b.position=pos; parent.add_child(b); _box(b,size,Vector3.ZERO,_mat(Color(0.35,0.39,0.39))); var c:=CollisionShape3D.new(); var s:=BoxShape3D.new(); s.size=size; c.shape=s; b.add_child(c)
func _house(parent:Node,pos:Vector3,size:Vector3,wall:Color,roof:Color)->void:
    # Construção modular: paredes separadas deixam portas e janelas realmente vazadas.
    var building:=Node3D.new()
    building.position=pos
    parent.add_child(building)
    var half_x:=size.x*0.5
    var half_z:=size.z*0.5
    var h:=size.y
    var t:=0.34
    var wall_mat:=_mat(wall,0.88)
    var roof_mat:=_mat(roof,0.82)
    var trim_mat:=_mat(roof.lightened(0.22),0.72)
    var dark_mat:=_mat(Color(0.075,0.085,0.09),0.28)
    var glass_mat:=StandardMaterial3D.new()
    glass_mat.albedo_color=Color(0.10,0.43,0.58,0.72)
    glass_mat.metallic=0.18
    glass_mat.roughness=0.16
    glass_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA

    # Fundo e laterais com colisão independente.
    _house_wall(building,Vector3(size.x,h,t),Vector3(0,h*0.5,-half_z),wall_mat)
    _house_wall(building,Vector3(t,h,size.z),Vector3(-half_x,h*0.5,0),wall_mat)
    _house_wall(building,Vector3(t,h,size.z),Vector3(half_x,h*0.5,0),wall_mat)

    # Fachada frontal com vão de porta central e duas janelas.
    var door_w:=minf(1.55,size.x*0.24)
    var door_h:=minf(2.25,h*0.78)
    var side_w:=(size.x-door_w)*0.5
    _house_wall(building,Vector3(side_w,h,t),Vector3(-half_x+side_w*0.5,h*0.5,half_z),wall_mat)
    _house_wall(building,Vector3(side_w,h,t),Vector3(half_x-side_w*0.5,h*0.5,half_z),wall_mat)
    _house_wall(building,Vector3(door_w,h-door_h,t),Vector3(0,door_h+(h-door_h)*0.5,half_z),wall_mat)

    # Piso, telhado e beiral.
    _box(building,Vector3(size.x,0.22,size.z),Vector3(0,0.02,0),_mat(Color(0.30,0.29,0.25),0.95))
    _box(building,Vector3(size.x+0.9,0.42,size.z+0.9),Vector3(0,h+0.18,0),roof_mat)
    _box(building,Vector3(size.x+1.05,0.13,0.18),Vector3(0,h+0.43,half_z+0.35),trim_mat)
    _box(building,Vector3(size.x+1.05,0.13,0.18),Vector3(0,h+0.43,-half_z-0.35),trim_mat)
    _box(building,Vector3(0.18,0.13,size.z+0.7),Vector3(-half_x-0.35,h+0.43,0),trim_mat)
    _box(building,Vector3(0.18,0.13,size.z+0.7),Vector3(half_x+0.35,h+0.43,0),trim_mat)

    # Porta, moldura e degrau frontal.
    _box(building,Vector3(door_w+0.28,0.12,0.16),Vector3(0,door_h+0.04,half_z+0.22),trim_mat)
    _box(building,Vector3(0.13,door_h,0.16),Vector3(-door_w*0.5-0.06,door_h*0.5,half_z+0.22),trim_mat)
    _box(building,Vector3(0.13,door_h,0.16),Vector3(door_w*0.5+0.06,door_h*0.5,half_z+0.22),trim_mat)
    _box(building,Vector3(door_w*0.82,door_h*0.88,0.08),Vector3(0,door_h*0.46,half_z+0.10),dark_mat)
    _box(building,Vector3(0.08,0.08,0.04),Vector3(door_w*0.27,door_h*0.48,half_z+0.16),trim_mat)
    _box(building,Vector3(door_w+0.45,0.22,0.95),Vector3(0,0.11,half_z+0.52),_mat(Color(0.43,0.42,0.36)))

    # Janelas laterais da fachada com peitoril e molduras metálicas.
    for side in [-1.0,1.0]:
        var wx:float=side*(door_w*0.5+side_w*0.5)
        var ww:=minf(1.65,side_w*0.48)
        var wy:=h*0.57
        _box(building,Vector3(ww+0.28,1.05,0.12),Vector3(wx,wy,half_z+0.20),trim_mat)
        _box(building,Vector3(ww,0.78,0.045),Vector3(wx,wy,half_z+0.275),glass_mat)
        _box(building,Vector3(0.07,0.92,0.06),Vector3(wx,wy,half_z+0.31),dark_mat)
        _box(building,Vector3(ww+0.35,0.10,0.28),Vector3(wx,wy-0.56,half_z+0.30),trim_mat)

    # Janelas menores nas laterais e detalhes de fachada.
    for side in [-1.0,1.0]:
        var sx:float=side*(half_x+0.19)
        _box(building,Vector3(0.05,0.92,1.35),Vector3(sx,h*0.58,0),glass_mat)
        _box(building,Vector3(0.12,1.08,0.12),Vector3(sx*1.015,h*0.58,-0.72),trim_mat)
        _box(building,Vector3(0.12,1.08,0.12),Vector3(sx*1.015,h*0.58,0.72),trim_mat)

    # Acabamento de canto, luminária e ventilação no telhado.
    for x in [-half_x,half_x]:
        for z in [-half_z,half_z]:
            _box(building,Vector3(0.16,h+0.12,0.16),Vector3(x,h*0.5,z),trim_mat)
    _box(building,Vector3(0.34,0.42,0.18),Vector3(0, h-0.35, half_z+0.18),_mat(Color(0.92,0.70,0.28),0.25))
    _box(building,Vector3(1.1,0.5,0.8),Vector3(-half_x*0.55,h+0.62,-half_z*0.45),_mat(Color(0.28,0.31,0.32),0.55))
    for i in range(3):
        _box(building,Vector3(0.72,0.055,0.10),Vector3(-half_x*0.55,h+0.88,-half_z*0.45-0.22+i*0.20),dark_mat)

    # Interior: balcão, armário e iluminação simples para dar escala ao ambiente.
    _box(building,Vector3(minf(2.4,size.x*0.35),0.95,0.62),Vector3(half_x*0.48,0.48,-half_z*0.35),_mat(Color(0.30,0.20,0.13),0.92))
    _box(building,Vector3(0.9,1.35,0.42),Vector3(-half_x*0.55,0.68,-half_z*0.50),_mat(Color(0.22,0.25,0.26),0.7))
    _box(building,Vector3(0.12,0.12,0.12),Vector3(0,h-0.12,0),_mat(Color(1.0,0.78,0.43),0.25))

func _house_wall(parent:Node3D,size:Vector3,pos:Vector3,material:Material)->void:
    var body:=StaticBody3D.new()
    body.position=pos
    parent.add_child(body)
    _box(body,size,Vector3.ZERO,material)
    var collision:=CollisionShape3D.new()
    var shape:=BoxShape3D.new()
    shape.size=size
    collision.shape=shape
    body.add_child(collision)

func _tree(parent:Node,pos:Vector3)->void:
    _box(parent,Vector3(0.55,2.2,0.55),pos+Vector3(0,1.1,0),_mat(Color(0.28,0.16,0.08))); var m:=MeshInstance3D.new(); var s:=SphereMesh.new(); s.radius=1.4; s.height=2.3; s.material=_mat(Color(0.08,0.34,0.12)); m.mesh=s; m.position=pos+Vector3(0,2.7,0); parent.add_child(m)
func _crate(parent:Node,pos:Vector3,side:float)->void:
    var b:=StaticBody3D.new(); b.position=pos+Vector3(0,side/2,0); parent.add_child(b); _box(b,Vector3(side,side,side),Vector3.ZERO,_mat(Color(0.42,0.25,0.12))); var c:=CollisionShape3D.new(); var s:=BoxShape3D.new(); s.size=Vector3(side,side,side); c.shape=s; b.add_child(c)


func _build_player_armor(parent:Node3D)->void:
    # Personagem com anatomia arredondada e proporções humanas.
    var base:Color=chars[selected]["color"]
    var dark:=base.darkened(0.48)
    var accent:=Color("#F6C34A")
    if skin=="Dragão de Fogo": accent=Color("#F0442E")
    elif skin=="Gelo Eterno": accent=Color("#55DDF5")
    elif skin=="Ouro Imperial": accent=Color("#F4C34A")
    elif skin=="Neon Roxo": accent=Color("#B45CFA")
    var cloth:=_mat(dark,0.92,0.0)
    var armor:=_mat(base,0.48,0.12)
    var trim:=_mat(accent,0.34,0.42)
    var black:=_mat(Color("#17212B"),0.38,0.32)
    var skin_mat:=_mat(Color("#9B684D"),0.82,0.0)

    # Tronco e colete anatômicos.
    var torso:=MeshInstance3D.new()
    var torso_mesh:=CapsuleMesh.new()
    torso_mesh.radius=0.30
    torso_mesh.height=0.92
    torso_mesh.radial_segments=24
    torso_mesh.rings=12
    torso_mesh.material=cloth
    torso.mesh=torso_mesh
    torso.position=Vector3(0,0.02,0)
    torso.scale=Vector3(1.08,1.0,0.72)
    parent.add_child(torso)
    var chest:=MeshInstance3D.new()
    var chest_mesh:=SphereMesh.new()
    chest_mesh.radius=0.39
    chest_mesh.height=0.72
    chest_mesh.radial_segments=24
    chest_mesh.rings=16
    chest_mesh.material=armor
    chest.mesh=chest_mesh
    chest.position=Vector3(0,0.19,-0.015)
    chest.scale=Vector3(1.0,0.92,0.78)
    parent.add_child(chest)

    # Placas curvas, bolsos e emblema.
    for side in [-1.0,1.0]:
        var plate:=MeshInstance3D.new()
        var pm:=SphereMesh.new()
        pm.radius=0.19
        pm.height=0.42
        pm.radial_segments=20
        pm.rings=12
        pm.material=black
        plate.mesh=pm
        plate.position=Vector3(side*0.15,0.16,-0.285)
        plate.scale=Vector3(0.9,1.0,0.32)
        parent.add_child(plate)
        var pouch:=MeshInstance3D.new()
        var pouch_mesh:=CapsuleMesh.new()
        pouch_mesh.radius=0.075
        pouch_mesh.height=0.22
        pouch_mesh.radial_segments=16
        pouch_mesh.material=black
        pouch.mesh=pouch_mesh
        pouch.position=Vector3(side*0.25,-0.10,-0.27)
        pouch.scale=Vector3(1.0,1.0,0.42)
        parent.add_child(pouch)
    var badge:=MeshInstance3D.new()
    var bm:=SphereMesh.new()
    bm.radius=0.075
    bm.height=0.11
    bm.material=trim
    badge.mesh=bm
    badge.position=Vector3(0,0.31,-0.31)
    badge.scale=Vector3(1.0,0.55,0.25)
    parent.add_child(badge)

    # Braços com ombros, bíceps, cotovelos, antebraços e luvas.
    for side in [-1.0,1.0]:
        var shoulder:=MeshInstance3D.new()
        var sm:=SphereMesh.new()
        sm.radius=0.205
        sm.height=0.30
        sm.radial_segments=20
        sm.rings=12
        sm.material=armor
        shoulder.mesh=sm
        shoulder.position=Vector3(side*0.43,0.32,0)
        parent.add_child(shoulder)
        var upper:=MeshInstance3D.new()
        var um:=CapsuleMesh.new()
        um.radius=0.125
        um.height=0.52
        um.radial_segments=20
        um.rings=12
        um.material=cloth
        upper.mesh=um
        upper.position=Vector3(side*0.49,0.02,0.015)
        upper.rotation.z=side*0.10
        parent.add_child(upper)
        var elbow:=MeshInstance3D.new()
        var em:=SphereMesh.new()
        em.radius=0.13
        em.height=0.15
        em.material=black
        elbow.mesh=em
        elbow.position=Vector3(side*0.51,-0.22,-0.005)
        parent.add_child(elbow)
        var forearm:=MeshInstance3D.new()
        var fm:=CapsuleMesh.new()
        fm.radius=0.105
        fm.height=0.40
        fm.radial_segments=20
        fm.rings=12
        fm.material=armor
        forearm.mesh=fm
        forearm.position=Vector3(side*0.52,-0.39,-0.015)
        parent.add_child(forearm)
        var glove:=MeshInstance3D.new()
        var gm:=SphereMesh.new()
        gm.radius=0.12
        gm.height=0.15
        gm.material=black
        glove.mesh=gm
        glove.position=Vector3(side*0.52,-0.61,-0.04)
        parent.add_child(glove)

        # Coxas, joelheiras, canelas e botas.
        var thigh:=MeshInstance3D.new()
        var tm:=CapsuleMesh.new()
        tm.radius=0.145
        tm.height=0.60
        tm.radial_segments=20
        tm.rings=12
        tm.material=cloth
        thigh.mesh=tm
        thigh.position=Vector3(side*0.18,-0.68,0.015)
        parent.add_child(thigh)
        var knee:=MeshInstance3D.new()
        var km:=SphereMesh.new()
        km.radius=0.15
        km.height=0.17
        km.material=trim
        knee.mesh=km
        knee.position=Vector3(side*0.18,-0.89,-0.035)
        knee.scale=Vector3(1.0,0.7,0.75)
        parent.add_child(knee)
        var boot:=MeshInstance3D.new()
        var boot_mesh:=CapsuleMesh.new()
        boot_mesh.radius=0.14
        boot_mesh.height=0.48
        boot_mesh.radial_segments=20
        boot_mesh.rings=12
        boot_mesh.material=black
        boot.mesh=boot_mesh
        boot.position=Vector3(side*0.18,-1.08,-0.005)
        boot.scale=Vector3(1.0,0.72,1.0)
        parent.add_child(boot)

    # Mochila arredondada.
    var pack:=MeshInstance3D.new()
    var pack_mesh:=CapsuleMesh.new()
    pack_mesh.radius=0.22
    pack_mesh.height=0.62
    pack_mesh.radial_segments=20
    pack_mesh.rings=12
    pack_mesh.material=black
    pack.mesh=pack_mesh
    pack.position=Vector3(0,0.12,0.25)
    pack.scale=Vector3(0.82,1.0,0.62)
    parent.add_child(pack)

    # Pescoço, crânio, mandíbula e orelhas.
    var neck:=MeshInstance3D.new()
    var nm:=CylinderMesh.new()
    nm.top_radius=0.105
    nm.bottom_radius=0.12
    nm.height=0.18
    nm.radial_segments=20
    nm.material=skin_mat
    neck.mesh=nm
    neck.position=Vector3(0,0.51,0)
    parent.add_child(neck)
    var head:=MeshInstance3D.new()
    var hm:=SphereMesh.new()
    hm.radius=0.205
    hm.height=0.43
    hm.radial_segments=24
    hm.rings=16
    hm.material=skin_mat
    head.mesh=hm
    head.position=Vector3(0,0.72,-0.005)
    head.scale=Vector3(0.88,1.0,0.90)
    parent.add_child(head)
    var jaw:=MeshInstance3D.new()
    var jm:=SphereMesh.new()
    jm.radius=0.14
    jm.height=0.17
    jm.material=skin_mat
    jaw.mesh=jm
    jaw.position=Vector3(0,0.62,-0.09)
    jaw.scale=Vector3(0.9,0.62,0.75)
    parent.add_child(jaw)
    for side in [-1.0,1.0]:
        var ear:=MeshInstance3D.new()
        var ear_mesh:=SphereMesh.new()
        ear_mesh.radius=0.052
        ear_mesh.height=0.085
        ear_mesh.material=skin_mat
        ear.mesh=ear_mesh
        ear.position=Vector3(side*0.18,0.72,-0.005)
        ear.scale=Vector3(0.65,1.0,0.65)
        parent.add_child(ear)

    # Capacete curvo e viseira.
    var helmet:=MeshInstance3D.new()
    var helmet_mesh:=SphereMesh.new()
    helmet_mesh.radius=0.235
    helmet_mesh.height=0.29
    helmet_mesh.radial_segments=24
    helmet_mesh.rings=16
    helmet_mesh.material=black
    helmet.mesh=helmet_mesh
    helmet.position=Vector3(0,0.84,0.015)
    helmet.scale=Vector3(1.04,0.72,1.0)
    parent.add_child(helmet)
    var visor:=MeshInstance3D.new()
    var vm:=SphereMesh.new()
    vm.radius=0.17
    vm.height=0.075
    vm.material=trim
    visor.mesh=vm
    visor.position=Vector3(0,0.76,-0.18)
    visor.scale=Vector3(1.18,0.55,0.25)
    parent.add_child(visor)

func _build_weapon_model(parent:Node3D)->void:
    var weapon:=Node3D.new()
    weapon.name="WeaponModel"
    weapon.position=Vector3(0.43,0.26,-0.48)
    parent.add_child(weapon)
    var metal:=Color(0.055,0.065,0.075)
    var accent:=Color(0.95,0.48,0.10)
    var equipped_skin:String=String(weapon_skin_equipped.get(active_weapon,"Original"))
    if equipped_skin=="Dragão de Fogo":
        accent=Color(1.0,0.12,0.025)
    elif equipped_skin=="Gelo Eterno":
        accent=Color(0.25,0.86,1.0)
    elif equipped_skin=="Ouro Imperial":
        accent=Color(1.0,0.72,0.12)
        metal=Color(0.22,0.16,0.055)
    elif equipped_skin=="Neon Roxo":
        accent=Color(0.78,0.18,1.0)
    match active_weapon:
        "XM8": accent=accent.lerp(Color(0.15,0.8,0.72),0.35)
        "Águia do Deserto": accent=accent.lerp(Color(0.8,0.72,0.5),0.35)
        "M1014": accent=accent.lerp(Color(0.65,0.3,0.12),0.35)
        "MP40": accent=accent.lerp(Color(0.35,0.55,0.9),0.35)
    var body_length:=0.78
    var barrel_length:=0.48
    var magazine_height:=0.28
    match active_weapon:
        "XM8":
            body_length=0.92
            barrel_length=0.62
            magazine_height=0.34
        "Águia do Deserto":
            body_length=0.48
            barrel_length=0.28
            magazine_height=0.18
        "M1014":
            body_length=1.05
            barrel_length=0.78
            magazine_height=0.20
        "MP40":
            body_length=0.62
            barrel_length=0.38
            magazine_height=0.42
    var receiver:=_mat(metal,0.28,0.72)
    var skin_mat:=_mat(accent,0.30,0.5)
    _box(weapon,Vector3(0.15,0.16,body_length),Vector3(0,0,-0.10),receiver)
    _box(weapon,Vector3(0.17,0.09,body_length*0.48),Vector3(0,0.10,0.08),skin_mat)
    _box(weapon,Vector3(0.12,0.19,0.20),Vector3(0,-0.16,0.10),receiver)
    _box(weapon,Vector3(0.07,magazine_height,0.17),Vector3(0,-0.24,0.02),receiver)
    _box(weapon,Vector3(0.045,0.045,barrel_length),Vector3(0,0.025,-0.62),receiver)
    _box(weapon,Vector3(0.12,0.075,0.17),Vector3(0,0.12,-0.28),skin_mat)
    # Mira, trilho superior, guarda-mão, empunhadura e coronha.
    _box(weapon,Vector3(0.055,0.045,body_length*0.72),Vector3(0,0.115,-0.12),receiver)
    _box(weapon,Vector3(0.10,0.055,0.12),Vector3(0,0.20,-0.30),skin_mat)
    _box(weapon,Vector3(0.08,0.12,0.10),Vector3(0,-0.13,-0.31),receiver)
    _box(weapon,Vector3(0.09,0.20,0.12),Vector3(0,-0.17,0.29),receiver)
    _box(weapon,Vector3(0.10,0.07,0.24),Vector3(0,0.02,0.37),receiver)
    _box(weapon,Vector3(0.09,0.055,0.08),Vector3(0,0.11,0.43),skin_mat)
    # Cano com ponta reforçada e pequenas ranhuras laterais.
    _box(weapon,Vector3(0.085,0.085,0.10),Vector3(0,0.025,-0.91),receiver)
    for side in [-1.0,1.0]:
        _box(weapon,Vector3(0.018,0.07,0.30),Vector3(side*0.085,0.015,-0.18),skin_mat)

func _player() -> void:
    player=CharacterBody3D.new(); player.name="Player"; player.position=Vector3(0,1,16); add_child(player)
    var c:=CollisionShape3D.new(); var s:=CapsuleShape3D.new(); s.height=1.8; s.radius=0.34; c.shape=s; player.add_child(c)
    _build_player_armor(player)
    _build_weapon_model(player)
    var lobby_camera := get_node_or_null("LobbyCamera") as Camera3D
    if lobby_camera:
        lobby_camera.current = false
    camera=Camera3D.new(); camera.name="BattleCamera"; camera.position=Vector3(0,2.35,5.8); camera.rotation.x=pitch; camera.fov=72; camera.current=true; player.add_child(camera)
    hp=chars[selected]["hp"]; shield=0; energy=MAX_ENERGY; ammo=_mag_size(); kills=0; time_left=START_TIME; zone=MAP; zone_tick=0; ability_cd=0; ability_tick=0; medkits=3; match_done=false

func _bots() -> void:
    var points=[Vector3(-145,1,-145),Vector3(0,1,-155),Vector3(145,1,-145),Vector3(-155,1,0),Vector3(0,1,0),Vector3(155,1,0),Vector3(-145,1,145),Vector3(0,1,155),Vector3(145,1,145),Vector3(-75,1,-90),Vector3(78,1,88),Vector3(82,1,-85)]
    for i in range(points.size()):
        var b:=CharacterBody3D.new(); b.name="Rival_%02d"%(i+1); b.position=points[i]; add_child(b)
        var c:=CollisionShape3D.new(); var s:=CapsuleShape3D.new(); s.height=1.8; s.radius=0.36; c.shape=s; b.add_child(c)
        var m:=MeshInstance3D.new(); var bm:=CapsuleMesh.new(); bm.height=1.5; bm.radius=0.37; bm.material=_mat([Color(0.78,0.14,0.10),Color(0.85,0.42,0.08),Color(0.58,0.15,0.30)][i%3]); m.mesh=bm; m.position.y=0.04; b.add_child(m)
        var bot_id:=b.get_instance_id()
        bot_hp[bot_id]=100.0
        bot_inventory[bot_id]={"MUNIÇÃO":randi_range(0,60),"KIT":randi_range(0,2),"COLETE":randi_range(0,1),"GELO":randi_range(0,2),"ENERGIA":randi_range(0,2)}
        bot_t[bot_id]=randf_range(0.7,2.0)
        bots.append(b)

func _loot() -> void:
    var kinds=["MUNIÇÃO","COLETE","KIT","GELO","ENERGIA"]
    var spots=[Vector3(-145,0,-145),Vector3(-137,0,-151),Vector3(-155,0,-137),Vector3(0,0,-155),Vector3(9,0,-148),Vector3(-8,0,-164),Vector3(145,0,-145),Vector3(153,0,-139),Vector3(137,0,-153),Vector3(-155,0,0),Vector3(-147,0,8),Vector3(-163,0,-7),Vector3(0,0,0),Vector3(8,0,7),Vector3(-8,0,-8),Vector3(155,0,0),Vector3(147,0,8),Vector3(163,0,-7),Vector3(-145,0,145),Vector3(0,0,155),Vector3(145,0,145),Vector3(-75,0,-90),Vector3(78,0,-85),Vector3(-82,0,82),Vector3(82,0,88)]
    for i in range(spots.size()):
        var kind:String = kinds[i%kinds.size()]
        var amount := 30 if kind=="MUNIÇÃO" else (35 if kind=="COLETE" else (1 if kind=="KIT" else (20 if kind=="GELO" else 70)))
        _spawn_ground_loot(spots[i],kind,amount)

func _spawn_ground_loot(spot:Vector3,kind:String,amount:int) -> void:
    if amount<=0: return
    var a:=Area3D.new()
    a.name="Loot_"+kind
    a.position=Vector3(spot.x,0.10,spot.z)
    a.set_meta("kind",kind)
    a.set_meta("amount",amount)
    add_child(a)
    var c:=CollisionShape3D.new()
    var shape:=SphereShape3D.new()
    shape.radius=1.0
    c.shape=shape
    a.add_child(c)
    var m:=MeshInstance3D.new()
    var mesh:=BoxMesh.new()
    mesh.size=Vector3(0.24,0.07,0.12) if kind=="MUNIÇÃO" else Vector3(0.30,0.10,0.24)
    mesh.material=_mat({"MUNIÇÃO":Color(0.95,0.72,0.12),"COLETE":Color(0.18,0.48,0.92),"KIT":Color(0.12,0.82,0.30),"GELO":Color(0.20,0.88,1.0),"ENERGIA":Color(0.72,0.25,0.95)}.get(kind,Color.WHITE))
    m.mesh=mesh
    m.position.y=-0.035
    a.add_child(m)
    loot.append(a)

func _spawn_airdrop() -> void:
    var spots=[Vector3(-145,0,-145),Vector3(0,0,-155),Vector3(145,0,-145),Vector3(-155,0,0),Vector3(0,0,0),Vector3(155,0,0),Vector3(-145,0,145),Vector3(0,0,155),Vector3(145,0,145)]
    var spot:Vector3=spots[randi_range(0,spots.size()-1)]
    _drop_death_loot(spot,{"MUNIÇÃO":90,"KIT":2,"COLETE":2,"GELO":4,"ENERGIA":100})
    var crate:Area3D=null
    for item in loot:
        if is_instance_valid(item) and item.name=="Caixa_de_Loot" and item.global_position.distance_to(spot)<0.5:
            crate=item
    if crate:
        crate.name="Suprimento_PUNK"
        crate.set_meta("airdrop",true)
        var box_mesh:=crate.get_node_or_null("MeshInstance3D") as MeshInstance3D
        if box_mesh:
            box_mesh.scale=Vector3(1.65,1.35,1.65)
            box_mesh.position.y=0.15
            var box:=box_mesh.mesh as BoxMesh
            if box:
                box.material=_mat(Color(0.82,0.16,0.10))
        var beacon:=MeshInstance3D.new()
        beacon.name="Sinal_Vermelho"
        var beam:=CylinderMesh.new()
        beam.top_radius=0.10
        beam.bottom_radius=0.22
        beam.height=5.5
        var glow:=StandardMaterial3D.new()
        glow.albedo_color=Color(1.0,0.04,0.02,0.72)
        glow.emission_enabled=true
        glow.emission=Color(1.0,0.02,0.01)
        glow.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
        beacon.mesh=beam
        beacon.material_override=glow
        beacon.position=Vector3(0,3.0,0)
        crate.add_child(beacon)
    _toast("🚁 SUPRIMENTO AÉREO CHEGOU! PROCURE O SINAL VERMELHO")

func _drop_death_loot(spot:Vector3,contents:Dictionary) -> void:
    var has_items:=false
    for value in contents.values():
        if int(value)>0:
            has_items=true
            break
    if not has_items:
        return
    var crate:=Area3D.new()
    crate.name="Caixa_de_Loot"
    crate.position=Vector3(spot.x,0.16,spot.z)
    crate.set_meta("contents",contents.duplicate(true))
    crate.set_meta("kind","CAIXA")
    add_child(crate)
    var c:=CollisionShape3D.new()
    var shape:=SphereShape3D.new()
    shape.radius=1.35
    c.shape=shape
    crate.add_child(c)
    var m:=MeshInstance3D.new()
    var box:=BoxMesh.new()
    box.size=Vector3(0.62,0.30,0.46)
    box.material=_mat(Color(0.48,0.30,0.12))
    m.mesh=box
    crate.add_child(m)
    loot.append(crate)

func _battle_ui() -> void:
    battle_ui=Control.new(); battle_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); battle_ui.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(battle_ui)
    hp_text=_txt(battle_ui,"",Vector2(18,18),Vector2(700,35),18); ammo_text=_txt(battle_ui,"",Vector2(18,52),Vector2(350,30),18); reload_text=_txt(battle_ui,"",Vector2.ZERO,Vector2(260,28),16); reload_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; reload_text.visible=false
    top_text=_txt(battle_ui,"",Vector2(0,18),Vector2(320,30),17); zone_text=_txt(battle_ui,"",Vector2(0,48),Vector2(320,28),15); top_text.position.x=get_viewport().size.x/2-160; zone_text.position.x=get_viewport().size.x/2-160; top_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; zone_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    var cross:=_txt(battle_ui,"+",Vector2(get_viewport().size.x/2-20,get_viewport().size.y/2-22),Vector2(40,40),30); cross.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hit_marker=_txt(battle_ui,"",Vector2(get_viewport().size.x/2-20,get_viewport().size.y/2-22),Vector2(40,40),30); hit_marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hit_marker.add_theme_color_override("font_color",Color(1.0,0.28,0.20)); hit_marker.visible=false
    joy_base=Panel.new(); joy_base.size=Vector2(132,132); joy_base.add_theme_stylebox_override("panel",_style(Color(0.04,0.09,0.12,0.45),Color(0.5,0.85,0.8,0.65),70)); joy_base.mouse_filter=Control.MOUSE_FILTER_IGNORE; battle_ui.add_child(joy_base)
    joy_knob=Panel.new(); joy_knob.size=Vector2(58,58); joy_knob.add_theme_stylebox_override("panel",_style(Color(0.25,0.85,0.80,0.75),Color.WHITE,40)); joy_knob.mouse_filter=Control.MOUSE_FILTER_IGNORE; battle_ui.add_child(joy_knob)
    fire=_btn(battle_ui,"ATIRAR",Vector2.ZERO,Vector2(112,112),Color(0.72,0.10,0.10)); switch_weapon=_btn(battle_ui,"TROCAR",Vector2.ZERO,Vector2(104,46),Color(0.24,0.30,0.42)); reload=_btn(battle_ui,"RECARREGAR",Vector2.ZERO,Vector2(145,50),Color(0.16,0.28,0.36)); ability=_btn(battle_ui,"DRAGÃO",Vector2.ZERO,Vector2(155,58),Color(0.10,0.46,0.38)); medkit=_btn(battle_ui,"KIT +50",Vector2.ZERO,Vector2(105,48),Color(0.14,0.38,0.24)); aim=_btn(battle_ui,"MIRA",Vector2.ZERO,Vector2(82,48),Color(0.20,0.28,0.40)); gloo_button=_btn(battle_ui,"GELO 12",Vector2.ZERO,Vector2(105,48),Color(0.08,0.42,0.58))
    switch_weapon.pressed.connect(_switch_weapon)
    fire.button_down.connect(func(): fire_held=true; _shoot())
    fire.button_up.connect(func(): fire_held=false)
    reload.pressed.connect(_reload); ability.pressed.connect(_ability); medkit.pressed.connect(_medkit); gloo_button.pressed.connect(_deploy_gloo_wall); aim.button_down.connect(func():aim_held=true; current_scope="Ponto vermelho"; camera.fov=48); aim.button_up.connect(func():aim_held=false; camera.fov=72)
    var leave:=_btn(battle_ui,"Ⅱ",Vector2(18,92),Vector2(52,48),Color(0.12,0.15,0.18)); leave.pressed.connect(_toggle_pause)
    _layout_battle()

func _layout_battle() -> void:
    if not battle_ui: return
    var s:=get_viewport().get_visible_rect().size
    top_text.position=Vector2(s.x/2-160,12); zone_text.position=Vector2(s.x/2-160,42); reload_text.position=Vector2(s.x/2-130,s.y*0.68)
    joy_base.position=Vector2(24,s.y-164); joy_knob.position=joy_base.position+Vector2(37,37)
    fire.position=Vector2(s.x-126,s.y-148)
    switch_weapon.position=Vector2(s.x-250,s.y-218)
    reload.position=Vector2(s.x-274,s.y-66)
    ability.position=Vector2(s.x-292,s.y-132)
    medkit.position=Vector2(s.x-420,s.y-66)
    aim.position=Vector2(s.x-218,s.y-194)
    gloo_button.position=Vector2(s.x-420,s.y-132)
    # Evita que os botoes laterais invadam o joystick em telas estreitas.
    if s.x<760:
        medkit.position.x=maxf(s.x*0.48, s.x-420)
        reload.position.x=maxf(s.x*0.57, s.x-274)
        ability.position.x=maxf(s.x*0.54, s.x-292)
        aim.position.x=maxf(s.x*0.68, s.x-218)

func _deploy_gloo_wall() -> void:
    if mode != "battle" or match_done or match_phase != "landed" or gloo_charges <= 0:
        return
    if not is_instance_valid(player):
        return
    gloo_charges -= 1
    if active_gloo_walls.size() >= 3:
        var oldest: StaticBody3D = active_gloo_walls.pop_front()
        if is_instance_valid(oldest):
            oldest.queue_free()
    var forward := -player.global_transform.basis.z
    var wall := StaticBody3D.new()
    wall.name = "PUNK_Gelo_" + str(Time.get_ticks_msec())
    wall.position = player.global_position + forward * 2.2 + Vector3.UP * 1.15
    wall.rotation.y = player.rotation.y
    add_child(wall)
    var mesh := MeshInstance3D.new()
    var slab := SphereMesh.new()
    slab.radius = 1.0
    slab.height = 2.0
    slab.radial_segments = 32
    slab.rings = 16
    var ice := StandardMaterial3D.new()
    ice.albedo_color = Color(0.88, 0.97, 1.0, 0.94)
    ice.roughness = 0.18
    ice.metallic = 0.08
    ice.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    ice.clearcoat_enabled = true
    ice.clearcoat = 0.7
    slab.material = ice
    mesh.mesh = slab
    mesh.scale = Vector3(2.1, 1.15, 0.22)
    wall.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = 1.0
    collision.shape = shape
    collision.scale = Vector3(2.1, 1.15, 0.30)
    wall.add_child(collision)
    active_gloo_walls.append(wall)
    gloo_button.text = "GELO %d" % gloo_charges
    gloo_button.disabled = gloo_charges <= 0
    _toast("PAREDE DE GELO ATIVADA • 60s")
    _expire_gloo_wall(wall)

func _expire_gloo_wall(wall:StaticBody3D) -> void:
    await get_tree().create_timer(60.0).timeout
    if is_instance_valid(wall):
        wall.queue_free()
    active_gloo_walls.erase(wall)

func _abandon_match() -> void:
    if mode=="battle" and not match_done:
        if match_phase=="airborne" or match_phase=="landed":
            _end(false)
    _lobby()

func _toggle_pause() -> void:
    if mode!="battle" or match_done:
        return
    match_paused=not match_paused
    if match_paused:
        pause_panel=Panel.new()
        pause_panel.position=Vector2(get_viewport().size.x/2-170,get_viewport().size.y/2-145)
        pause_panel.size=Vector2(340,290)
        pause_panel.add_theme_stylebox_override("panel",_style(Color(0.015,0.03,0.05,0.98),Color(0.25,0.85,0.75),18))
        battle_ui.add_child(pause_panel)
        var title:=_txt(pause_panel,"PARTIDA PAUSADA",Vector2(0,28),Vector2(340,44),25)
        title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
        var resume:=_btn(pause_panel,"CONTINUAR",Vector2(45,100),Vector2(250,52),Color(0.08,0.48,0.34))
        resume.pressed.connect(_toggle_pause)
        var quit:=_btn(pause_panel,"SAIR PARA O LOBBY",Vector2(45,170),Vector2(250,52),Color(0.45,0.12,0.12))
        quit.pressed.connect(_abandon_match)
    else:
        if is_instance_valid(pause_panel):
            pause_panel.queue_free()
        pause_panel=null

func _physics_process(delta:float) -> void:
    if mode!="battle" or not player or match_done or match_paused: return
    if match_phase=="lobby_aircraft":
        # O avião percorre o mapa durante o embarque; jogador e cabine viajam juntos.
        var flight_step := Vector3(0.0, 0.0, -delta * 2.8)
        player.global_position += flight_step
        var aircraft := get_node_or_null("AircraftCabin")
        if aircraft is Node3D:
            aircraft.global_position += flight_step
        boarding_time=maxf(0.0,boarding_time-delta)
        if is_instance_valid(boarding_label):
            boarding_label.text="AGUARDE O SALTO  •  %02d" % int(ceil(boarding_time))
        if boarding_time<=0.0:
            match_phase="ready_to_jump"
            if is_instance_valid(boarding_label): boarding_label.text="PORTAS ABERTAS — ESCOLHA QUANDO SALTAR!"
            if is_instance_valid(jump_button): jump_button.disabled=false
        return
    if match_phase=="ready_to_jump":
        return
    if match_phase=="airborne":
        var steer:=Vector2.ZERO
        if joy_id!=-1:
            steer=(joy_pos-joy_start).limit_length(58)/58
        var forward:= -player.global_transform.basis.z
        var right:= player.global_transform.basis.x
        var glide:=right*steer.x+forward*(-steer.y)
        glide.y=0.0
        if glide.length()>1.0: glide=glide.normalized()
        player.velocity.x=glide.x*5.0
        player.velocity.z=glide.z*5.0
        player.velocity.y=-4.2
        player.move_and_slide()
        if player.is_on_floor() or player.global_position.y<=1.05:
            player.global_position.y=1.0
            player.velocity=Vector3.ZERO
            match_phase="landed"
            var canopy=player.get_node_or_null("ParachuteCanopy")
            if canopy: canopy.queue_free()
            for control in [fire,switch_weapon,reload,ability,medkit,aim,gloo_button,joy_base,joy_knob]:
                control.visible=true
            _toast("POUSO CONCLUÍDO — BOA PARTIDA!")
        return
    shot_tick=maxf(0,shot_tick-delta)
    hit_marker_tick=maxf(0,hit_marker_tick-delta)
    if hit_marker_tick<=0:
        hit_marker.visible=false
    recoil_kick=maxf(0,recoil_kick-delta*0.045)
    camera.rotation.x=clampf(pitch-recoil_kick,-0.82,0.28)
    ability_cd=maxf(0,ability_cd-delta)
    ability_tick=maxf(0,ability_tick-delta)
    time_left=maxf(0.0,time_left-delta)
    if time_left<=0.0 and not overtime_started:
        overtime_started=true
        _toast("TEMPO ESGOTADO — ELIMINE TODOS OS RIVAIS!")
    zone_tick+=delta
    energy=minf(MAX_ENERGY,energy+delta*4)
    # Disparo continuo ao manter o botao pressionado, respeitando o intervalo da arma.
    if fire_held and reload_tick<=0:
        _shoot()
    if reload_tick>0:
        reload_tick-=delta
        if reload_tick<=0:
            var needed:=_mag_size()-ammo
            var loaded:=mini(needed,reserve_ammo)
            ammo+=loaded
            reserve_ammo-=loaded
            weapon_ammo[active_weapon]=ammo
    if not airdrop_spawned and time_left <= START_TIME - 90.0:
        airdrop_spawned=true
        _spawn_airdrop()
    var zone_interval:float = 5.0 if overtime_started else 12.0
    if zone_tick>zone_interval:
        zone_tick=0
        zone=maxf(5.0,zone-(3.2 if overtime_started else 1.6))
    _move(delta); _update_bots(delta); _aim_assist(delta); _pickup(); _hud()
    if player.global_position.length()>zone: _damage(5*delta)

func _move(delta:float) -> void:
    var input:=Vector2.ZERO
    if Input.is_action_pressed("move_left"): input.x-=1
    if Input.is_action_pressed("move_right"): input.x+=1
    if Input.is_action_pressed("move_forward"): input.y-=1
    if Input.is_action_pressed("move_back"): input.y+=1
    if joy_id!=-1:
        var stick=(joy_pos-joy_start).limit_length(58)/58
        if stick.length()<0.13: stick=Vector2.ZERO
        input=stick
    # Mantém a velocidade diagonal igual à velocidade em linha reta.
    input=input.limit_length(1.0)
    var f:Vector3=-player.global_transform.basis.z
    var r:Vector3=player.global_transform.basis.x
    var d:=r*input.x+f*(-input.y)
    d.y=0
    if d.length()>1.0: d=d.normalized()
    var sp:=6.3; if selected=="Danilo" and ability_tick>0: sp=9.2
    player.velocity.x=d.x*sp; player.velocity.z=d.z*sp
    if not player.is_on_floor(): player.velocity.y-=20*delta
    else: player.velocity.y=0
    player.move_and_slide(); player.global_position.x=clampf(player.global_position.x,-MAP,MAP); player.global_position.z=clampf(player.global_position.z,-MAP,MAP)

func _update_bots(delta:float) -> void:
    for b in bots.duplicate():
        if not is_instance_valid(b):
            bots.erase(b)
            continue
        var id: int = b.get_instance_id()
        var offset: Vector3 = player.global_position - b.global_position
        var flat := Vector3(offset.x, 0.0, offset.z)
        var dist: float = flat.length()
        var to_player := flat.normalized() if dist > 0.01 else Vector3.ZERO

        # IA simples de combate: aproxima, recua quando pressionada e muda
        # ligeiramente de lado para não avançar em linha reta como um alvo parado.
        if (dist < 38.0 or overtime_started) and dist > 0.01:
            var strafe_sign := 1.0 if int(id % 2) == 0 else -1.0
            var strafe := Vector3(-to_player.z, 0.0, to_player.x) * strafe_sign
            var move_dir := Vector3.ZERO
            if dist > 10.0:
                move_dir = to_player * 0.82 + strafe * 0.38
            elif dist < 6.5:
                move_dir = -to_player + strafe * 0.28
            else:
                move_dir = strafe * 0.52
            move_dir = move_dir.normalized()
            var speed:float = 4.0 if overtime_started else 2.9
            if selected == "Lucas" and ability_tick > 0:
                speed = 1.45
            b.velocity.x = move_dir.x * speed
            b.velocity.z = move_dir.z * speed
            b.rotation.y = atan2(-to_player.x, -to_player.z)
            b.move_and_slide()
        else:
            b.velocity.x = move_toward(b.velocity.x, 0.0, delta * 5.0)
            b.velocity.z = move_toward(b.velocity.z, 0.0, delta * 5.0)
            b.move_and_slide()

        bot_t[id] = float(bot_t.get(id, 1.4)) - delta
        if dist >= 30.0 or float(bot_t[id]) > 0.0:
            continue

        # Paredes e construções bloqueiam o tiro dos rivais.
        var eye: Vector3 = b.global_position + Vector3.UP * 1.15
        var target: Vector3 = player.global_position + Vector3.UP * 0.95
        var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(eye, target)
        query.exclude = [b]
        var sight: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
        if sight.is_empty() or sight.get("collider") != player:
            continue

        bot_t[id] = randf_range(0.85, 1.45)
        var enemy_damage := randf_range(5.0, 8.0) if dist < 12.0 else randf_range(3.0, 5.5)
        if selected == "Marli" and ability_tick > 0:
            enemy_damage *= 0.55
        _damage(enemy_damage)

func _unhandled_input(e:InputEvent) -> void:
    if mode!="battle": return
    if e is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT): _look(e.relative)
    elif e is InputEventMouseButton and e.button_index==MOUSE_BUTTON_LEFT and e.pressed: _shoot()
    elif e is InputEventScreenTouch:
        if e.pressed:
            var w: float = get_viewport().size.x
            if e.position.x<w*0.42: joy_id=e.index; joy_start=e.position; joy_pos=e.position
            elif e.position.x>w*0.76 and e.position.y>get_viewport().size.y*0.45: _shoot()
            else: look_id=e.index
        else:
            if e.index==joy_id: joy_id=-1; joy_knob.position=joy_base.position+Vector2(37,37)
            if e.index==look_id: look_id=-1
    elif e is InputEventScreenDrag:
        if e.index==joy_id: joy_pos=joy_start+(e.position-joy_start).limit_length(58); joy_knob.position=joy_pos-Vector2(29,29)
        elif e.index==look_id: _look(e.relative)

func _look(r:Vector2) -> void:
    if not player or not camera: return
    # Sensibilidade proporcional à escala da tela, com limite vertical para não inverter a câmera.
    var scale_factor=clampf(get_viewport().get_visible_rect().size.y/720.0,0.75,1.35)
    yaw-=r.x*0.0036*scale_factor*(sensitivities.get(current_scope,100.0)/100.0)
    pitch=clampf(pitch-r.y*0.0030*scale_factor*(sensitivities.get(current_scope,100.0)/100.0),-0.82,0.28)
    player.rotation.y=yaw
    camera.rotation.x=clampf(pitch-recoil_kick,-0.82,0.28)

func _aim_assist(delta:float) -> void:
    if not aim_held or bots.is_empty() or not is_instance_valid(camera): return
    aim_assist_tick -= delta
    if aim_assist_tick > 0.0:
        return
    # A busca de alvos usa raycasts em frequência limitada para poupar CPU mobile.
    aim_assist_tick = 0.08
    var forward:Vector3=-camera.global_transform.basis.z
    var best:CharacterBody3D=null
    var best_distance:=INF
    for rival in bots:
        if not is_instance_valid(rival): continue
        var offset:Vector3=(rival.global_position+Vector3.UP*0.45)-camera.global_position
        var distance:=offset.length()
        if distance>32.0 or distance<0.1: continue
        if forward.dot(offset.normalized())<0.78: continue
        # A assistência não atravessa paredes ou construções.
        var sight_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(camera.global_position, rival.global_position + Vector3.UP * 0.45)
        sight_query.exclude=[player]
        var sight_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(sight_query)
        if sight_hit.is_empty() or sight_hit.get("collider") != rival:
            continue
        if distance<best_distance:
            best=rival
            best_distance=distance
    if best==null: return
    var to_target:Vector3=(best.global_position+Vector3.UP*0.45)-camera.global_position
    var desired_yaw:=atan2(-to_target.x,-to_target.z)
    var desired_pitch:=atan2(to_target.y,Vector2(to_target.x,to_target.z).length())
    var strength:=clampf(delta*22.0,0.0,0.22)
    yaw=lerp_angle(yaw,desired_yaw,strength)
    pitch=lerpf(pitch,clampf(desired_pitch,-0.82,0.28),strength)
    player.rotation.y=yaw
    camera.rotation.x=clampf(pitch-recoil_kick,-0.82,0.28)

func _shoot() -> void:
    if shot_tick>0 or reload_tick>0 or match_done: return
    if ammo<=0:
        _reload()
        return
    shot_tick=float(weapon_cadence.get(active_weapon,0.13))
    var kick:=0.012
    match active_weapon:
        "Águia do Deserto": kick=0.045
        "M1014": kick=0.055
        "MP40": kick=0.008
        "XM8": kick=0.010
    recoil_kick=minf(0.12,recoil_kick+kick)
    camera.rotation.x=clampf(pitch-recoil_kick,-0.82,0.28)
    ammo-=1
    weapon_ammo[active_weapon]=ammo
    var origin:=camera.global_position
    var direction:Vector3=-camera.global_transform.basis.z
    var spread:=float(weapon_spread.get(active_weapon,0.012))
    direction=(direction+Vector3(randf_range(-spread,spread),randf_range(-spread,spread),0)).normalized()
    var query:=PhysicsRayQueryParameters3D.create(origin,origin+direction*110.0)
    query.exclude=[player]
    var hit:=get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return
    var target: Object = hit.get("collider")
    if target == null or not bots.has(target):
        return
    hit_marker.visible=true; hit_marker.text="✕"; hit_marker_tick=0.16
    var id: int = target.get_instance_id()
    var damage:=float(weapon_damage.get(active_weapon,28.0))
    if active_weapon=="M1014":
        damage*=maxf(0.35,1.0-origin.distance_to(target.global_position)/32.0)
    if selected=="Kosmos" and ability_tick>0: damage=39
    if selected=="Cuíca" and ability_tick>0: damage=34+kills*2
    # Acerto na parte superior da cápsula causa dano crítico.
    var impact:Vector3=hit.get("position",target.global_position)
    var headshot: bool = impact.y > target.global_position.y + 0.55
    if headshot:
        damage*=1.5
        hit_marker.text="✕ HS"
        hit_marker.add_theme_color_override("font_color",Color(1.0,0.12,0.10))
        hit_marker_tick=0.35
    else:
        hit_marker.text="✕"
        hit_marker.add_theme_color_override("font_color",Color(1.0,0.82,0.08))
        hit_marker_tick=0.16
    bot_hp[id]=float(bot_hp.get(id,100.0))-damage
    if bot_hp[id]<=0:
        kills+=1
        total_kills+=1
        coins+=10
        _save_profile()
        _drop_death_loot(target.global_position,bot_inventory.get(id,{}))
        bot_inventory.erase(id)
        bots.erase(target)
        bot_hp.erase(id)
        bot_t.erase(id)
        target.queue_free()
        _toast("ELIMINAÇÃO +10 🪙")
        if bots.is_empty() and not match_done:
            _end(true)

func _refresh_weapon_model() -> void:
    if not is_instance_valid(player): return
    var old_model=player.get_node_or_null("WeaponModel")
    if old_model: old_model.free()
    _build_weapon_model(player)

func _mag_size() -> int:
    return int(weapon_mag.get(active_weapon,MAG))

func _switch_weapon() -> void:
    if weapon_catalog.is_empty() or not is_instance_valid(player) or match_done or reload_tick>0.0:
        return
    # Cada arma conserva a munição que já estava no carregador.
    weapon_ammo[active_weapon]=ammo
    var index: int = weapon_catalog.find(active_weapon)
    active_weapon=weapon_catalog[(index+1)%weapon_catalog.size()]
    if weapon_ammo.has(active_weapon):
        ammo=int(weapon_ammo[active_weapon])
    else:
        ammo=mini(_mag_size(),reserve_ammo)
        reserve_ammo-=ammo
        weapon_ammo[active_weapon]=ammo
    _refresh_weapon_model()
    _save_profile()
    _hud()
    _toast("ARMA: "+active_weapon)

func _reload() -> void:
    if reload_tick>0 or ammo>=_mag_size() or reserve_ammo<=0 or match_done:
        return
    fire_held=false
    reload_tick=float(weapon_reload.get(active_weapon,1.5))
    reload_total=reload_tick
    _toast("RECARREGANDO "+active_weapon+"...")
func _max_player_hp() -> float:
    return float(chars.get(selected, chars["Kosmos"]).get("hp", MAX_HP))

func _medkit() -> void:
    var max_hp := _max_player_hp()
    if medkits > 0 and hp < max_hp and not match_done:
        medkits -= 1
        hp = minf(max_hp, hp + 50.0)
        _toast("KIT MÉDICO +50")
func _ability() -> void:
    if ability_cd>0 or match_done: return
    match selected:
        "Kosmos": hp=minf(_max_player_hp(),hp+50.0); shield=90; ability_tick=30
        "Danilo": hp=minf(_max_player_hp(),hp+50.0); ability_tick=30
        "Cuíca": ability_tick=20
        "Lucas": ability_tick=8
        "Marli": ability_tick=15
    ability_cd=chars[selected]["cd"]; _toast("HABILIDADE ATIVADA — "+selected)
func _damage(amount:float) -> void:
    var rest:=amount
    if shield>0:
        var a:=minf(shield,rest)
        shield-=a
        rest-=a
    hp=maxf(0,hp-rest)
    if hp<=0 and not match_done: _end(false)
func _pickup() -> void:
    # Prioridade automática: cura, munição, proteção, gelo e energia.
    var priority := {"KIT":0,"MUNIÇÃO":1,"COLETE":2,"GELO":3,"ENERGIA":4,"CAIXA":5}
    var nearby:Array[Area3D]=[]
    for item in loot.duplicate():
        if not is_instance_valid(item):
            loot.erase(item)
            continue
        if player.global_position.distance_to(item.global_position)<1.7:
            nearby.append(item)
    nearby.sort_custom(func(a:Area3D,b:Area3D) -> bool:
        var pa:=int(priority.get(String(a.get_meta("kind","")),99))
        var pb:=int(priority.get(String(b.get_meta("kind","")),99))
        if pa==pb:
            return player.global_position.distance_squared_to(a.global_position)<player.global_position.distance_squared_to(b.global_position)
        return pa<pb
    )
    if nearby.is_empty():
        return
    # Coleta apenas um objeto por atualização para respeitar a prioridade.
    var a:Area3D=nearby[0]
    var k:String=a.get_meta("kind")
    var amount := maxi(1,int(a.get_meta("amount",1)))
    match k:
        "MUNIÇÃO":
            reserve_ammo = mini(240, reserve_ammo + amount)
        "COLETE":
            shield = minf(90, shield + amount)
        "KIT":
            medkits += amount
        "GELO":
            shield = minf(90, shield + amount)
        "ENERGIA":
            energy = minf(MAX_ENERGY, energy + amount)
        "CAIXA":
            var contents: Dictionary = a.get_meta("contents", {})
            for item in contents:
                var count := int(contents[item])
                match String(item):
                    "MUNIÇÃO":
                        reserve_ammo = mini(240, reserve_ammo + count)
                    "COLETE":
                        shield = minf(90, shield + count * 35)
                    "KIT":
                        medkits += count
                    "GELO":
                        shield = minf(90, shield + count * 20)
                    "ENERGIA":
                        energy = minf(MAX_ENERGY, energy + count * 35)
    var loot_label := "SUPRIMENTO AÉREO" if bool(a.get_meta("airdrop", false)) else ("CAIXA DE LOOT" if k == "CAIXA" else k)
    loot.erase(a)
    a.queue_free()
    _toast("PEGOU " + loot_label)
func _hud() -> void:
    hp_text.text="🐉 %s  ❤️ %d  🛡 %d  ⚡ %d  💀 %d"%[selected,int(hp),int(shield),int(energy),kills]
    ammo_text.text="%s • %s  %02d/%02d  |  RES %03d"%[active_weapon,weapon_skin_equipped[active_weapon],ammo,_mag_size(),reserve_ammo]
    reload_text.visible=reload_tick>0
    if reload_tick>0:
        var progress:=clampf(1.0-reload_tick/maxf(0.01,reload_total),0.0,1.0)
        reload_text.text="RECARREGANDO  %d%%"%int(progress*100.0)
    top_text.text=("RIVAIS %02d   |   PRORROGAÇÃO"%bots.size()) if overtime_started else "RIVAIS %02d   |   TEMPO %03d"%[bots.size(),int(maxf(0,time_left))]
    zone_text.text="ZONA %.0fm"%zone
    ability.text="DRAGÃO %s"%(["PRONTO" if ability_cd<=0 else "%ds"%int(ceil(ability_cd))][0])
    ability.disabled=ability_cd>0
func _toast(t:String)->void:
    var parent:Control = battle_ui if battle_ui and is_instance_valid(battle_ui) else ui
    if parent == null or not is_instance_valid(parent):
        return
    if toast == null or not is_instance_valid(toast):
        toast = _txt(parent, "", Vector2(get_viewport().size.x/2-250, get_viewport().size.y*0.72), Vector2(500,40), 20)
        toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast.text = t
    toast.modulate.a = 1.0
    var tw := create_tween()
    tw.tween_interval(1.0)
    tw.tween_property(toast, "modulate:a", 0.0, 0.6)
func _end(win:bool)->void:
    if match_done: return
    match_done=true
    matches_played+=1
    best_kills=maxi(best_kills,kills)
    if win:
        wins+=1
        coins+=100
    else:
        losses+=1
    _save_profile()
    var p:=Panel.new(); p.position=Vector2(get_viewport().size.x/2-190,get_viewport().size.y/2-145); p.size=Vector2(380,290); p.add_theme_stylebox_override("panel",_style(Color(0.015,0.03,0.05,0.98),Color(0.30,0.82,0.70),20)); battle_ui.add_child(p)
    var t:=_txt(p,"VITÓRIA!" if win else "ELIMINADO",Vector2(0,35),Vector2(380,50),30); t.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    var rate:=roundi(float(wins)*100.0/maxi(1,matches_played))
    var s:=_txt(p,"Kills: %d  •  Recorde: %d\\nVitórias: %d/%d (%d%%)\\nKills totais: %d\\n🪙 %d"%[kills,best_kills,wins,matches_played,rate,total_kills,coins],Vector2(0,92),Vector2(380,105),17); s.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    var b:=_btn(p,"VOLTAR AO LOBBY",Vector2(75,205),Vector2(230,55)); b.pressed.connect(_lobby)
