extends Node3D

# PUNK v1 — protótipo 3D em desenvolvimento.
# Original assets and gameplay. Third-person mobile camera/control style.

const MAX_HP := 200.0
const MAX_ENERGY := 200.0
const MAG := 30
const MAP := 52.0
const START_TIME := 420.0

var mode := "lobby"
var selected := "Kosmos"
var skin := "Original"
var wardrobe_category := "Conjuntos"
var wardrobe_equipped := {"Conjuntos":"Conjunto Dragão Neon","Cabeças":"Cabelo Espinhos","Máscaras":"Máscara Tática","Peitorais":"Jaqueta Eclipse","Calças":"Calça Angelical Cósmica","Sapatos":"Tênis Azul Elétrico","Emotes":"Dança da Vitória"}
var wardrobe_categories := ["Conjuntos","Cabeças","Máscaras","Peitorais","Calças","Sapatos","Emotes"]
var royale_tab := "Destaques"
var royale_items := ["Guardião Carmesim","Anjo Cósmico","Lenda Neon","Dragão Abissal","UMP Tempestade","XM8 Prisma","Emote Vitória Suprema"]

# Arsenal REAL CHP BATTLE
var active_weapon := "UMP"
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
var bot_t: Dictionary = {}
var loot: Array[Area3D] = []
var hp := MAX_HP
var shield := 0.0
var energy := MAX_ENERGY
var ammo := MAG
var kills := 0
var coins := 250
var time_left := START_TIME
var zone := MAP
var zone_tick := 0.0
var shot_tick := 0.0
var reload_tick := 0.0
var ability_tick := 0.0
var ability_cd := 0.0
var medkits := 3
var match_done := false
var yaw := 0.0
var pitch := -0.18
var joy_id := -1
var joy_start := Vector2.ZERO
var joy_pos := Vector2.ZERO
var look_id := -1

var ui: Control
var battle_ui: Control
var hp_text: Label
var ammo_text: Label
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

func _ready() -> void:
    _world_lighting()
    _lobby()

func _world_lighting() -> void:
    var e := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sm := ProceduralSkyMaterial.new()
    sm.sky_top_color = Color(0.015,0.045,0.11)
    sm.sky_horizon_color = Color(0.50,0.70,0.78)
    sm.ground_horizon_color = Color(0.35,0.45,0.30)
    sm.ground_bottom_color = Color(0.06,0.10,0.06)
    sky.sky_material = sm
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = 0.85
    env.fog_enabled = true
    env.fog_density = 0.003
    e.environment = env
    add_child(e)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50,-28,0)
    sun.light_energy = 1.4
    sun.shadow_enabled = true
    add_child(sun)

func _reset_ui() -> void:
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
    ui.mouse_filter = Control.MOUSE_FILTER_STOP
    layer.add_child(ui)

func _bg(color:Color) -> ColorRect:
    var c := ColorRect.new()
    c.color = color
    c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(c)
    return c

func _txt(parent:Control, text:String, pos:Vector2, size:Vector2, font:=20) -> Label:
    var l := Label.new()
    l.text=text; l.position=pos; l.size=size
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
    mode="lobby"; _clear_world(); _reset_ui(); _bg(Color(0.006,0.010,0.018,1))
    var logo:=TextureRect.new(); logo.texture=load("res://assets/real_chapero.png"); logo.position=Vector2(get_viewport().size.x*0.33,28); logo.size=Vector2(220,220); logo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; logo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; ui.add_child(logo)
    var title:=_txt(ui,"PUNK",Vector2(0,145),Vector2(get_viewport().size.x,90),64); title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_color_override("font_color",Color(0.78,0.90,1))
    var sub:=_txt(ui,"V1 • 3D SHOOTER EM DESENVOLVIMENTO",Vector2(0,304),Vector2(get_viewport().size.x,30),17); sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; sub.add_theme_color_override("font_color",Color(0.30,0.95,0.82))
    var play:=_btn(ui,"▶  JOGAR",Vector2(get_viewport().size.x/2-170,355),Vector2(340,64),Color(0.08,0.50,0.37)); play.pressed.connect(_start)
    var ch:=_btn(ui,"♙  PERSONAGENS / SKINS",Vector2(get_viewport().size.x/2-170,430),Vector2(340,56)); ch.pressed.connect(_characters)
    var inv:=_btn(ui,"▣  INVENTÁRIO",Vector2(get_viewport().size.x/2-170,497),Vector2(340,56),Color(0.14,0.25,0.36)); inv.pressed.connect(_inventory)
    var vault:=_btn(ui,"▣  COFRE DE ROUPAS",Vector2(get_viewport().size.x/2-170,564),Vector2(340,52),Color(0.24,0.16,0.38)); vault.pressed.connect(_wardrobe)
    var arsenal:=_btn(ui,"⚔  ARSENAL",Vector2(get_viewport().size.x/2-170,623),Vector2(160,48),Color(0.12,0.28,0.42)); arsenal.pressed.connect(_inventory)
    var royale:=_btn(ui,"✦  ROYALE",Vector2(get_viewport().size.x/2+10,623),Vector2(160,48),Color(0.48,0.22,0.08)); royale.pressed.connect(_royale)
    var st:=_btn(ui,"⚙  CONFIGURAÇÕES",Vector2(get_viewport().size.x/2-170,678),Vector2(340,48),Color(0.18,0.21,0.25)); st.pressed.connect(_settings)
    var foot:=_txt(ui,"PUNK V1     |     🪙 %d"%coins,Vector2(0,get_viewport().size.y-34),Vector2(get_viewport().size.x,25),13); foot.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

func _wardrobe() -> void:
    mode = "wardrobe"
    _reset_ui()
    _bg(Color(0.018,0.012,0.035))
    _txt(ui,"COFRE  /  MODA",Vector2(24,18),Vector2(500,42),30).add_theme_color_override("font_color",Color(1.0,0.78,0.22))
    _txt(ui,"PERSONAGEM: "+selected+"  •  VISUAIS EQUIPADOS",Vector2(26,60),Vector2(700,28),15)
    var width := get_viewport().size.x
    for i in range(wardrobe_categories.size()):
        var cat:String = wardrobe_categories[i]
        var col := i % 2
        var row := int(i / 2)
        var b := _btn(ui,cat,Vector2(20+col*(width/2),105+row*53),Vector2(width/2-28,45),Color(0.38,0.24,0.07) if wardrobe_category==cat else Color(0.10,0.16,0.23))
        b.pressed.connect(_wardrobe_category.bind(cat))
    _txt(ui,"ITENS • "+wardrobe_category.to_upper()+"  (1000 MODELOS)",Vector2(24,300),Vector2(650,30),18)
    var names:Array[String] = _wardrobe_items(wardrobe_category)
    for i in range(mini(names.size(),8)):
        var item:String = names[i]
        var b := _btn(ui,item+("  ✓" if wardrobe_equipped.get(wardrobe_category,"")==item else ""),Vector2(24,340+i*42),Vector2(width-48,36),Color(0.10,0.35,0.30) if wardrobe_equipped.get(wardrobe_category,"")==item else Color(0.12,0.16,0.23))
        b.pressed.connect(_equip_wardrobe.bind(item))
    var back := _btn(ui,"← LOBBY",Vector2(24,get_viewport().size.y-58),Vector2(140,42),Color(0.18,0.20,0.24))
    back.pressed.connect(_lobby)

func _wardrobe_items(category:String) -> Array[String]:
    var prefix := category.trim_suffix("s")
    var themes := ["Angelical Cósmico","Dragão Neon","Eclipse Sombrio","Guardião Celeste","Tempestade Rubra","Lenda Glacial","Samurai Dourado","Abismo Violeta"]
    var result:Array[String] = []
    for i in range(1000):
        result.append(prefix+" "+themes[i % themes.size()]+" • "+str(i+1))
    return result

func _wardrobe_category(category:String) -> void:
    wardrobe_category = category
    _wardrobe()

func _equip_wardrobe(item:String) -> void:
    wardrobe_equipped[wardrobe_category] = item
    _toast("EQUIPADO: "+item)
    _wardrobe()

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
        var x := 22+(i%2)*(get_viewport().size.x/2)
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
    _toast("RECOMPENSA DESBLOQUEADA: "+item)
    _royale()

func _characters() -> void:
    mode="characters"; _reset_ui(); _bg(Color(0.012,0.022,0.036))
    _txt(ui,"PERSONAGENS",Vector2(28,24),Vector2(500,50),34).add_theme_color_override("font_color",Color(0.30,0.95,0.82))
    _txt(ui,"Escolha personagem e skin para a próxima partida",Vector2(30,70),Vector2(700,30),16)
    for i in range(chars.keys().size()):
        var n:String=chars.keys()[i]; var b:=_btn(ui,n,Vector2(24+i*134,116),Vector2(124,50),chars[n]["color"]*0.72); b.pressed.connect(_pick_char.bind(n))
    var card:=Panel.new(); card.position=Vector2(25,188); card.size=Vector2(get_viewport().size.x-50,220); card.add_theme_stylebox_override("panel",_style(Color(0.03,0.055,0.08),Color(0.20,0.50,0.52),20)); ui.add_child(card)
    var sw:=ColorRect.new(); sw.color=chars[selected]["color"]; sw.position=Vector2(25,30); sw.size=Vector2(130,150); card.add_child(sw)
    var nm:=_txt(card,selected,Vector2(180,28),Vector2(400,42),30); nm.add_theme_color_override("font_color",chars[selected]["color"])
    _txt(card,"HP base: %d"%int(chars[selected]["hp"]),Vector2(180,78),Vector2(400,30),18)
    _txt(card,chars[selected]["ability"],Vector2(180,116),Vector2(650,55),16)
    _txt(ui,"SKINS",Vector2(30,435),Vector2(200,35),22)
    for i in range(skins[selected].size()):
        var s:String=skins[selected][i]; var b:=_btn(ui,s,Vector2(30+i*155,480),Vector2(142,52),Color(0.12,0.17,0.23)); b.pressed.connect(_pick_skin.bind(s))
    var back:=_btn(ui,"← VOLTAR",Vector2(30,get_viewport().size.y-72),Vector2(150,50),Color(0.18,0.20,0.24)); back.pressed.connect(_lobby)
    var go:=_btn(ui,"▶ JOGAR COM "+selected,Vector2(get_viewport().size.x-310,get_viewport().size.y-72),Vector2(280,50),Color(0.08,0.50,0.37)); go.pressed.connect(_start)

func _pick_char(n:String) -> void: selected=n; skin=skins[n][0]; _characters()
func _pick_skin(s:String) -> void: skin=s; _characters()

func _inventory() -> void:
    mode = "inventory"
    _reset_ui()
    _bg(Color(0.012, 0.02, 0.03))
    _txt(ui, "PUNK • ARSENAL E SKINS", Vector2(25, 18), Vector2(700, 45), 29)
    _txt(ui, "Moedas: %d" % coins, Vector2(28, 62), Vector2(350, 30), 19)
    _txt(ui, "ESCOLHA SUA ARMA", Vector2(28, 101), Vector2(400, 30), 18)

    var width := get_viewport().size.x
    for i in range(weapon_catalog.size()):
        var w: String = weapon_catalog[i]
        var bw := width / 5.0 - 8.0
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
    _inventory()

func _weapon_skin_action(sn: String) -> void:
    if sn in weapon_skin_owned[active_weapon]:
        weapon_skin_equipped[active_weapon] = sn
        _inventory()
    elif coins >= 100:
        coins -= 100
        weapon_skin_owned[active_weapon].append(sn)
        weapon_skin_equipped[active_weapon] = sn
        _inventory()
    else:
        _toast("MOEDAS INSUFICIENTES!")
        _inventory()


func _settings() -> void:
    mode="settings"; _reset_ui(); _bg(Color(0.012,0.018,0.028)); _txt(ui,"CONFIGURAÇÕES",Vector2(28,25),Vector2(600,50),34); _txt(ui,"PUNK v1 • PROTÓTIPO 3D",Vector2(30,82),Vector2(500,30),18)
    _txt(ui,"Câmera: terceira pessoa\nControles: joystick + arraste para mirar\nGráficos: compatibilidade mobile\nMapa: área aberta com casas, cobertura, árvores e loot",Vector2(30,140),Vector2(700,150),18)
    var back:=_btn(ui,"← VOLTAR",Vector2(30,get_viewport().size.y-72),Vector2(150,50),Color(0.18,0.20,0.24)); back.pressed.connect(_lobby)

func _start() -> void:
    mode="battle"; _reset_ui(); _clear_world(); _build_map(); _player(); _battle_ui(); _bots(); _loot(); _toast("PARTIDA INICIADA — SOBREVIVA!")

func _clear_world() -> void:
    if player and is_instance_valid(player): player.queue_free()
    for b in bots: if is_instance_valid(b): b.queue_free()
    for l in loot: if is_instance_valid(l): l.queue_free()
    bots.clear(); loot.clear(); bot_hp.clear(); bot_t.clear()
    var map=get_node_or_null("Map"); if map: map.queue_free()

func _build_map() -> void:
    var map:=Node3D.new(); map.name="Map"; add_child(map)
    var floor:=StaticBody3D.new(); map.add_child(floor)
    var pm:=PlaneMesh.new(); pm.size=Vector2(112,112); pm.material=_mat(Color(0.16,0.30,0.17)); var p:=MeshInstance3D.new(); p.mesh=pm; floor.add_child(p)
    var cc:=CollisionShape3D.new(); var cs:=BoxShape3D.new(); cs.size=Vector3(112,0.4,112); cc.shape=cs; cc.position.y=-0.2; floor.add_child(cc)
    _box(map,Vector3(13,0.04,105),Vector3(0,0.02,0),_mat(Color(0.13,0.14,0.15)))
    for z in range(-48,49,8): _box(map,Vector3(0.18,0.05,3.2),Vector3(0,0.05,z),_mat(Color(0.90,0.78,0.32)))
    var houses=[[Vector3(-19,0,-21),Vector3(11,5,9),Color(0.67,0.56,0.40),Color(0.28,0.12,0.10)],[Vector3(20,0,-28),Vector3(12,5,10),Color(0.57,0.64,0.67),Color(0.17,0.24,0.29)],[Vector3(-29,0,13),Vector3(10,4,9),Color(0.72,0.58,0.39),Color(0.40,0.18,0.10)],[Vector3(27,0,18),Vector3(12,5,10),Color(0.52,0.65,0.55),Color(0.22,0.18,0.15)],[Vector3(4,0,-42),Vector3(14,5,9),Color(0.52,0.56,0.63),Color(0.18,0.20,0.24)],[Vector3(-5,0,34),Vector3(10,4,8),Color(0.74,0.51,0.31),Color(0.36,0.13,0.10)]]
    for h in houses: _house(map,h[0],h[1],h[2],h[3])
    var walls=[[Vector3(-8,0.8,3),Vector3(8,1.6,0.7)],[Vector3(11,0.8,10),Vector3(0.7,1.6,10)],[Vector3(7,0.8,-13),Vector3(10,1.6,0.7)],[Vector3(-32,0.8,-4),Vector3(0.7,1.6,10)],[Vector3(31,0.8,-8),Vector3(8,1.6,0.7)],[Vector3(0,0.8,22),Vector3(10,1.6,0.7)]]
    for w in walls: _wall(map,w[0],w[1])
    for i in range(55):
        var pos:=Vector3(randf_range(-47,47),0,randf_range(-48,48))
        if abs(pos.x)<9 and abs(pos.z)<14: continue
        if randf()<0.72: _tree(map,pos)
        else: _crate(map,pos,randf_range(0.8,1.5))
    _wall(map,Vector3(-54,1,0),Vector3(1.2,2,110)); _wall(map,Vector3(54,1,0),Vector3(1.2,2,110)); _wall(map,Vector3(0,1,-54),Vector3(110,2,1.2)); _wall(map,Vector3(0,1,54),Vector3(110,2,1.2))

func _mat(c:Color,r:=0.8,m:=0.0)->StandardMaterial3D:
    var x:=StandardMaterial3D.new(); x.albedo_color=c; x.roughness=r; x.metallic=m; return x
func _box(parent:Node,size:Vector3,pos:Vector3,mat:Material)->MeshInstance3D:
    var m:=MeshInstance3D.new(); var b:=BoxMesh.new(); b.size=size; b.material=mat; m.mesh=b; m.position=pos; parent.add_child(m); return m
func _wall(parent:Node,pos:Vector3,size:Vector3)->void:
    var b:=StaticBody3D.new(); b.position=pos; parent.add_child(b); _box(b,size,Vector3.ZERO,_mat(Color(0.35,0.39,0.39))); var c:=CollisionShape3D.new(); var s:=BoxShape3D.new(); s.size=size; c.shape=s; b.add_child(c)
func _house(parent:Node,pos:Vector3,size:Vector3,wall:Color,roof:Color)->void:
    var b:=StaticBody3D.new(); b.position=pos+Vector3(0,size.y/2,0); parent.add_child(b); _box(b,size,Vector3.ZERO,_mat(wall)); _box(b,Vector3(size.x+0.7,0.5,size.z+0.7),Vector3(0,size.y/2+0.25,0),_mat(roof)); _box(b,Vector3(1.3,2.3,0.15),Vector3(0,-size.y/2+1.15,size.z/2+0.08),_mat(Color(0.15,0.09,0.07))); for x in [-size.x*0.28,size.x*0.28]: _box(b,Vector3(1.3,0.9,0.14),Vector3(x,0.15,size.z/2+0.09),_mat(Color(0.10,0.48,0.62),0.25,0.1)); var c:=CollisionShape3D.new(); var s:=BoxShape3D.new(); s.size=size; c.shape=s; b.add_child(c)
func _tree(parent:Node,pos:Vector3)->void:
    _box(parent,Vector3(0.55,2.2,0.55),pos+Vector3(0,1.1,0),_mat(Color(0.28,0.16,0.08))); var m:=MeshInstance3D.new(); var s:=SphereMesh.new(); s.radius=1.4; s.height=2.3; s.material=_mat(Color(0.08,0.34,0.12)); m.mesh=s; m.position=pos+Vector3(0,2.7,0); parent.add_child(m)
func _crate(parent:Node,pos:Vector3,side:float)->void:
    var b:=StaticBody3D.new(); b.position=pos+Vector3(0,side/2,0); parent.add_child(b); _box(b,Vector3(side,side,side),Vector3.ZERO,_mat(Color(0.42,0.25,0.12))); var c:=CollisionShape3D.new(); var s:=BoxShape3D.new(); s.size=Vector3(side,side,side); c.shape=s; b.add_child(c)


func _build_player_armor(parent:Node3D)->void:
    var base:Color=chars[selected]["color"]
    var dark:=base.darkened(0.48)
    var accent:=Color(0.95,0.48,0.10)
    if skin=="Dragão de Fogo":
        accent=Color(1.0,0.12,0.025)
    elif skin=="Gelo Eterno":
        accent=Color(0.25,0.86,1.0)
    elif skin=="Ouro Imperial":
        accent=Color(1.0,0.72,0.12)
    elif skin=="Neon Roxo":
        accent=Color(0.78,0.18,1.0)

    _box(parent,Vector3(0.72,0.72,0.38),Vector3(0,0.12,0),_mat(base,0.62,0.12))
    _box(parent,Vector3(0.78,0.16,0.42),Vector3(0,0.40,0),_mat(dark,0.5,0.18))
    _box(parent,Vector3(0.52,0.12,0.43),Vector3(0,0.05,-0.015),_mat(accent,0.35,0.35))
    for side in [-1.0,1.0]:
        _box(parent,Vector3(0.30,0.30,0.34),Vector3(side*0.48,0.38,0),_mat(dark,0.55,0.15))
        _box(parent,Vector3(0.22,0.48,0.24),Vector3(side*0.48,-0.03,0),_mat(base,0.7,0.05))
        _box(parent,Vector3(0.20,0.18,0.25),Vector3(side*0.48,-0.35,0),_mat(accent,0.4,0.3))
        _box(parent,Vector3(0.27,0.48,0.30),Vector3(side*0.19,-0.62,0.015),_mat(dark,0.65,0.05))
        _box(parent,Vector3(0.29,0.18,0.38),Vector3(side*0.19,-0.92,-0.035),_mat(Color(0.08,0.09,0.11),0.45,0.25))

    var head:=MeshInstance3D.new()
    var hm:=SphereMesh.new()
    hm.radius=0.23
    hm.height=0.44
    hm.material=_mat(Color(0.55,0.36,0.25))
    head.mesh=hm
    head.position=Vector3(0,0.72,0)
    parent.add_child(head)
    _box(parent,Vector3(0.44,0.14,0.40),Vector3(0,0.88,0),_mat(dark,0.4,0.25))
    _box(parent,Vector3(0.48,0.07,0.43),Vector3(0,0.81,-0.015),_mat(accent,0.3,0.4))

func _build_weapon_model(parent:Node3D)->void:
    var weapon:=Node3D.new()
    weapon.name="WeaponModel"
    weapon.position=Vector3(0.43,0.26,-0.48)
    parent.add_child(weapon)
    var metal:=Color(0.055,0.065,0.075)
    var accent:=Color(0.95,0.48,0.10)
    if skin=="Dragão de Fogo":
        accent=Color(1.0,0.12,0.025)
    elif skin=="Gelo Eterno":
        accent=Color(0.25,0.86,1.0)
    elif skin=="Ouro Imperial":
        accent=Color(1.0,0.72,0.12)
        metal=Color(0.22,0.16,0.055)
    elif skin=="Neon Roxo":
        accent=Color(0.78,0.18,1.0)
    _box(weapon,Vector3(0.13,0.13,0.78),Vector3(0,0,-0.10),_mat(metal,0.28,0.65))
    _box(weapon,Vector3(0.16,0.18,0.36),Vector3(0,0.015,0.12),_mat(accent,0.3,0.45))
    _box(weapon,Vector3(0.10,0.28,0.16),Vector3(0,-0.19,0.10),_mat(metal,0.4,0.5))
    _box(weapon,Vector3(0.07,0.07,0.48),Vector3(0,0.02,-0.62),_mat(metal,0.25,0.8))
    _box(weapon,Vector3(0.18,0.06,0.18),Vector3(0,0.11,-0.28),_mat(accent,0.25,0.35))

func _player() -> void:
    player=CharacterBody3D.new(); player.name="Player"; player.position=Vector3(0,1,16); add_child(player)
    var c:=CollisionShape3D.new(); var s:=CapsuleShape3D.new(); s.height=1.8; s.radius=0.34; c.shape=s; player.add_child(c)
    _build_player_armor(player)
    _build_weapon_model(player)
    camera=Camera3D.new(); camera.position=Vector3(0,2.35,5.8); camera.rotation.x=pitch; camera.fov=72; camera.current=true; player.add_child(camera)
    hp=chars[selected]["hp"]; shield=0; energy=MAX_ENERGY; ammo=MAG; kills=0; time_left=START_TIME; zone=MAP; zone_tick=0; ability_cd=0; ability_tick=0; medkits=3; match_done=false

func _bots() -> void:
    var points=[Vector3(-13,1,-9),Vector3(14,1,-13),Vector3(-34,1,18),Vector3(31,1,24),Vector3(7,1,-32),Vector3(-29,1,-29),Vector3(36,1,-15),Vector3(2,1,38),Vector3(22,1,3),Vector3(-20,1,31),Vector3(40,1,5),Vector3(-40,1,2)]
    for i in range(points.size()):
        var b:=CharacterBody3D.new(); b.name="Rival_%02d"%(i+1); b.position=points[i]; add_child(b)
        var c:=CollisionShape3D.new(); var s:=CapsuleShape3D.new(); s.height=1.8; s.radius=0.36; c.shape=s; b.add_child(c)
        var m:=MeshInstance3D.new(); var bm:=CapsuleMesh.new(); bm.height=1.5; bm.radius=0.37; bm.material=_mat([Color(0.78,0.14,0.10),Color(0.85,0.42,0.08),Color(0.58,0.15,0.30)][i%3]); m.mesh=bm; m.position.y=0.04; b.add_child(m)
        bot_hp[b.get_instance_id()]=100.0; bot_t[b.get_instance_id()]=randf_range(0.7,2.0); bots.append(b)

func _loot() -> void:
    var kinds=["MUNIÇÃO","COLETE","KIT","GELO","ENERGIA"]
    for i in range(18):
        var a:=Area3D.new(); a.name="Loot_%02d"%i; a.position=Vector3(randf_range(-43,43),0.55,randf_range(-43,43)); a.set_meta("kind",kinds[i%kinds.size()]); add_child(a)
        var c:=CollisionShape3D.new(); var s:=SphereShape3D.new(); s.radius=1.2; c.shape=s; a.add_child(c)
        var m:=MeshInstance3D.new(); var sm:=SphereMesh.new(); sm.radius=0.3; sm.height=0.6; sm.material=_mat([Color(0.95,0.75,0.10),Color(0.20,0.55,0.95),Color(0.15,0.80,0.35),Color(0.20,0.90,0.90),Color(0.70,0.25,0.95)][i%5],0.35,0.15); m.mesh=sm; a.add_child(m); loot.append(a)

func _battle_ui() -> void:
    battle_ui=Control.new(); battle_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); ui.add_child(battle_ui)
    hp_text=_txt(battle_ui,"",Vector2(18,18),Vector2(700,35),18); ammo_text=_txt(battle_ui,"",Vector2(18,52),Vector2(350,30),18)
    top_text=_txt(battle_ui,"",Vector2(0,18),Vector2(320,30),17); zone_text=_txt(battle_ui,"",Vector2(0,48),Vector2(320,28),15); top_text.position.x=get_viewport().size.x/2-160; zone_text.position.x=get_viewport().size.x/2-160; top_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; zone_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    var cross:=_txt(battle_ui,"+",Vector2(get_viewport().size.x/2-20,get_viewport().size.y/2-22),Vector2(40,40),30); cross.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    joy_base=Panel.new(); joy_base.size=Vector2(132,132); joy_base.add_theme_stylebox_override("panel",_style(Color(0.04,0.09,0.12,0.45),Color(0.5,0.85,0.8,0.65),70)); joy_base.mouse_filter=Control.MOUSE_FILTER_IGNORE; battle_ui.add_child(joy_base)
    joy_knob=Panel.new(); joy_knob.size=Vector2(58,58); joy_knob.add_theme_stylebox_override("panel",_style(Color(0.25,0.85,0.80,0.75),Color.WHITE,40)); joy_knob.mouse_filter=Control.MOUSE_FILTER_IGNORE; battle_ui.add_child(joy_knob)
    fire=_btn(battle_ui,"ATIRAR",Vector2.ZERO,Vector2(112,112),Color(0.72,0.10,0.10)); reload=_btn(battle_ui,"RECARREGAR",Vector2.ZERO,Vector2(145,50),Color(0.16,0.28,0.36)); ability=_btn(battle_ui,"DRAGÃO",Vector2.ZERO,Vector2(155,58),Color(0.10,0.46,0.38)); medkit=_btn(battle_ui,"KIT +50",Vector2.ZERO,Vector2(105,48),Color(0.14,0.38,0.24)); aim=_btn(battle_ui,"MIRA",Vector2.ZERO,Vector2(82,48),Color(0.20,0.28,0.40))
    fire.pressed.connect(_shoot); reload.pressed.connect(_reload); ability.pressed.connect(_ability); medkit.pressed.connect(_medkit); aim.button_down.connect(func():camera.fov=48); aim.button_up.connect(func():camera.fov=72)
    var leave:=_btn(battle_ui,"☰",Vector2(18,92),Vector2(52,48),Color(0.12,0.15,0.18)); leave.pressed.connect(_lobby)
    _layout_battle()

func _layout_battle() -> void:
    if not battle_ui: return
    var s:=get_viewport().size; top_text.position=Vector2(s.x/2-160,18); zone_text.position=Vector2(s.x/2-160,48); joy_base.position=Vector2(28,s.y-174); joy_knob.position=joy_base.position+Vector2(37,37); fire.position=Vector2(s.x-135,s.y-160); reload.position=Vector2(s.x-305,s.y-74); ability.position=Vector2(s.x-310,s.y-142); medkit.position=Vector2(s.x-425,s.y-70); aim.position=Vector2(s.x-235,s.y-210)

func _physics_process(delta:float) -> void:
    if mode!="battle" or not player: return
    shot_tick=maxf(0,shot_tick-delta); ability_cd=maxf(0,ability_cd-delta); ability_tick=maxf(0,ability_tick-delta); time_left-=delta; zone_tick+=delta; energy=minf(MAX_ENERGY,energy+delta*4)
    if reload_tick>0:
        reload_tick-=delta
        if reload_tick<=0:
            ammo=MAG
    if zone_tick>12:
        zone_tick=0
        zone=maxf(18,zone-1.6)
    _move(delta); _update_bots(delta); _pickup(); _hud()
    if player.global_position.length()>zone: _damage(5*delta)
    if time_left<=0 and not match_done: _end(true)

func _move(delta:float) -> void:
    var input:=Vector2.ZERO
    if Input.is_action_pressed("move_left"): input.x-=1
    if Input.is_action_pressed("move_right"): input.x+=1
    if Input.is_action_pressed("move_forward"): input.y-=1
    if Input.is_action_pressed("move_back"): input.y+=1
    if joy_id!=-1: input=(joy_pos-joy_start).limit_length(58)/58
    var f:Vector3=-player.global_transform.basis.z; var r:Vector3=player.global_transform.basis.x; var d:=r*input.x+f*(-input.y); if d.length()>1: d=d.normalized()
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
        var v:=player.global_position-b.global_position
        var dist:=v.length()
        if dist<32 and dist>5:
            var d:=Vector3(v.x,0,v.z).normalized()
            var sp:=2.2
            if selected=="Lucas" and ability_tick>0:
                sp=1.0
            b.velocity.x=d.x*sp
            b.velocity.z=d.z*sp
            b.rotation.y=atan2(-d.x,-d.z)
            b.move_and_slide()
        var id:=b.get_instance_id()
        bot_t[id]=float(bot_t.get(id,1.4))-delta
        if dist<14 and float(bot_t[id])<=0:
            bot_t[id]=randf_range(1.0,2.0)
            _damage(5 if selected=="Marli" and ability_tick>0 else 9)

func _unhandled_input(e:InputEvent) -> void:
    if mode!="battle": return
    if e is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT): _look(e.relative)
    elif e is InputEventMouseButton and e.button_index==MOUSE_BUTTON_LEFT and e.pressed: _shoot()
    elif e is InputEventScreenTouch:
        if e.pressed:
            var w:=get_viewport().size.x
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
    yaw-=r.x*0.004; pitch=clampf(pitch-r.y*0.003,-0.9,0.35); player.rotation.y=yaw; camera.rotation.x=pitch

func _shoot() -> void:
    if shot_tick>0 or reload_tick>0 or match_done: return
    if ammo<=0: _reload(); return
    shot_tick=0.13; ammo-=1
    var a:=camera.global_position; var z:=a+(-camera.global_transform.basis.z)*110; var q:=PhysicsRayQueryParameters3D.create(a,z); q.exclude=[player]; var hit:=get_world_3d().direct_space_state.intersect_ray(q)
    if hit:
        var obj=hit.get("collider")
        if obj and obj in bots:
            var id:=obj.get_instance_id(); var dmg:=28.0
            if selected=="Kosmos" and ability_tick>0: dmg=39
            if selected=="Cuíca" and ability_tick>0: dmg=34+kills*2
            bot_hp[id]=float(bot_hp.get(id,100))-dmg
            if bot_hp[id]<=0: kills+=1; coins+=10; bots.erase(obj); bot_hp.erase(id); bot_t.erase(id); obj.queue_free(); _toast("ELIMINAÇÃO +10 🪙")

func _reload() -> void:
    if reload_tick<=0 and ammo<MAG: reload_tick=1.5; _toast("RECARREGANDO...")
func _medkit() -> void:
    if medkits>0 and hp<MAX_HP: medkits-=1; hp=minf(MAX_HP,hp+50); _toast("KIT MÉDICO +50")
func _ability() -> void:
    if ability_cd>0 or match_done: return
    match selected:
        "Kosmos": hp=250; shield=90; ability_tick=30
        "Danilo": hp=minf(250,hp+50); ability_tick=30
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
    for a in loot.duplicate():
        if not is_instance_valid(a):
            loot.erase(a)
            continue
        if player.global_position.distance_to(a.global_position)<1.7:
            var k:String=a.get_meta("kind")
            match k:
                "MUNIÇÃO": ammo=min(MAG,ammo+15)
                "COLETE": shield=minf(70,shield+35)
                "KIT": medkits+=1
                "GELO": shield=minf(90,shield+20)
                "ENERGIA": energy=minf(MAX_ENERGY,energy+70)
            loot.erase(a); a.queue_free(); _toast("PEGOU "+k)
func _hud() -> void:
    hp_text.text="🐉 %s  ❤️ %d  🛡 %d  ⚡ %d  💀 %d"%[selected,int(hp),int(shield),int(energy),kills]
    ammo_text.text="%s • %s  %02d / %02d"%[active_weapon,weapon_skin_equipped[active_weapon],ammo,MAG]
    top_text.text="RIVAIS %02d   |   TEMPO %03d"%[bots.size(),int(maxf(0,time_left))]
    zone_text.text="ZONA %.0fm"%zone
    ability.text="DRAGÃO %s"%(["PRONTO" if ability_cd<=0 else "%ds"%int(ceil(ability_cd))][0])
    ability.disabled=ability_cd>0
func _toast(t:String)->void:
    if not toast:
        toast=_txt(battle_ui,"",Vector2(get_viewport().size.x/2-250,get_viewport().size.y*0.72),Vector2(500,40),20); toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    toast.text=t; toast.modulate.a=1
    var tw:=create_tween(); tw.tween_interval(1.0); tw.tween_property(toast,"modulate:a",0.0,0.6)
func _end(win:bool)->void:
    match_done=true; if win: coins+=100
    var p:=Panel.new(); p.position=Vector2(get_viewport().size.x/2-190,get_viewport().size.y/2-145); p.size=Vector2(380,290); p.add_theme_stylebox_override("panel",_style(Color(0.015,0.03,0.05,0.98),Color(0.30,0.82,0.70),20)); battle_ui.add_child(p)
    var t:=_txt(p,"VITÓRIA!" if win else "ELIMINADO",Vector2(0,35),Vector2(380,50),30); t.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    var s:=_txt(p,"Kills: %d\n🪙 %d"%[kills,coins],Vector2(0,100),Vector2(380,70),20); s.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    var b:=_btn(p,"VOLTAR AO LOBBY",Vector2(75,205),Vector2(230,55)); b.pressed.connect(_lobby)
