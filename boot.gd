extends Node

var layer: CanvasLayer
var ui: Control
var selected := "KOSMOS"
var skin := "ORIGINAL"
var coins := 250
var chars := {
    "KOSMOS": Color("#315DFF"),
    "LUCAS": Color("#19D7E8"),
    "CUÍCA": Color("#FF8A24"),
    "DANILO": Color("#28D16F"),
    "MARLI": Color("#D84FC0")
}
var skins := {
    "KOSMOS":["ORIGINAL","PRATA","DRAGÃO NEGRO"],
    "LUCAS":["ORIGINAL","NEON","GELO"],
    "CUÍCA":["ORIGINAL","FOGO","OURO"],
    "DANILO":["ORIGINAL","VERDE","TITÃ"],
    "MARLI":["ORIGINAL","ROSA","IMPERIAL"]
}

func _ready():
    layer = CanvasLayer.new()
    layer.layer = 100
    add_child(layer)
    _lobby()

func _clear():
    if ui and is_instance_valid(ui): ui.queue_free()
    ui = Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(ui)

func _bg(c):
    var r=ColorRect.new()
    r.color=c
    r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(r)

func _label(t,p,s,f=20):
    var l=Label.new()
    l.text=t; l.position=p; l.size=s
    l.add_theme_font_size_override("font_size",f)
    l.add_theme_color_override("font_color",Color.WHITE)
    l.add_theme_color_override("font_shadow_color",Color.BLACK)
    l.add_theme_constant_override("shadow_offset_x",2)
    l.add_theme_constant_override("shadow_offset_y",2)
    ui.add_child(l)
    return l

func _style(c,b,r=14):
    var s=StyleBoxFlat.new()
    s.bg_color=c; s.border_color=b
    s.set_border_width_all(2); s.set_corner_radius_all(r)
    return s

func _btn(t,p,z,c=Color("#164D40")):
    var b=Button.new()
    b.text=t; b.position=p; b.size=z
    b.add_theme_font_size_override("font_size",18)
    b.add_theme_stylebox_override("normal",_style(c,Color("#70E8C7")))
    b.add_theme_stylebox_override("hover",_style(c.lightened(.12),Color.WHITE))
    b.add_theme_stylebox_override("pressed",_style(c.darkened(.15),Color.WHITE))
    ui.add_child(b)
    return b

func _lobby():
    _clear(); _bg(Color("#050A12"))
    var logo=TextureRect.new()
    logo.texture=load("res://assets/real_chapero.png")
    logo.position=Vector2(0,18); logo.size=Vector2(1280,330)
    logo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    logo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    ui.add_child(logo)
    var a=_label("REAL CHP BATTLE",Vector2(0,325),Vector2(1280,58),42)
    a.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    a.add_theme_color_override("font_color",Color("#DCEBFF"))
    var b=_label("BATTLE ROYALE • MOBILE",Vector2(0,375),Vector2(1280,30),16)
    b.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    b.add_theme_color_override("font_color",Color("#48E5B7"))
    var x=470.0
    var play=_btn("▶  JOGAR",Vector2(x,420),Vector2(340,60),Color("#08724F"))
    play.pressed.connect(_battle)
    var ch=_btn("♙  PERSONAGENS / SKINS",Vector2(x,490),Vector2(340,54))
    ch.pressed.connect(_characters)
    var inv=_btn("▣  INVENTÁRIO",Vector2(x,554),Vector2(340,54),Color("#18324A"))
    inv.pressed.connect(_inventory)
    var st=_btn("⚙  CONFIGURAÇÕES",Vector2(x,618),Vector2(340,54),Color("#202731"))
    st.pressed.connect(_settings)
    _label("KOSMOS • %s • 🪙 %d" % [skin,coins],Vector2(0,690),Vector2(1280,25),14).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

func _characters():
    _clear(); _bg(Color("#07111C"))
    _label("PERSONAGENS",Vector2(35,25),Vector2(500,50),34)
    _label("Escolha personagem e skin",Vector2(37,72),Vector2(600,30),16)
    for i in chars.keys().size():
        var n=chars.keys()[i]
        var q=_btn(n,Vector2(25+i*130,120),Vector2(120,48),chars[n].darkened(.55))
        q.pressed.connect(_pick_char.bind(n))
    var p=Panel.new(); p.position=Vector2(30,195); p.size=Vector2(1220,230)
    p.add_theme_stylebox_override("panel",_style(Color("#0D1B2A"),chars[selected],20)); ui.add_child(p)
    var sw=ColorRect.new(); sw.color=chars[selected]; sw.position=Vector2(25,25); sw.size=Vector2(160,180); p.add_child(sw)
    var n=Label.new(); n.text=selected; n.position=Vector2(220,25); n.size=Vector2(600,45)
    n.add_theme_font_size_override("font_size",30); p.add_child(n)
    var info=Label.new(); info.text="HP: 200\nHabilidade especial: %s\nSkin: %s" % [selected,skin]
    info.position=Vector2(220,85); info.size=Vector2(700,110); info.add_theme_font_size_override("font_size",18); p.add_child(info)
    _label("SKINS",Vector2(35,455),Vector2(250,35),22)
    for i in skins[selected].size():
        var s=skins[selected][i]
        var q=_btn(s,Vector2(35+i*170,500),Vector2(155,52),Color("#182636"))
        q.pressed.connect(_pick_skin.bind(s))
    var back=_btn("← VOLTAR",Vector2(30,650),Vector2(160,50),Color("#222A34")); back.pressed.connect(_lobby)
    var go=_btn("▶ JOGAR COM "+selected,Vector2(930,650),Vector2(320,50),Color("#08724F")); go.pressed.connect(_battle)

func _pick_char(n):
    selected=n; skin=skins[n][0]; _characters()

func _pick_skin(s):
    skin=s; _characters()

func _inventory():
    _clear(); _bg(Color("#07101A")); _label("INVENTÁRIO",Vector2(35,30),Vector2(500,50),34)
    _label("🪙 Moedas: %d" % coins,Vector2(38,82),Vector2(400,35),20)
    var items=["UMP — EQUIPADA","COLETE — NÍVEL 2","MOCHILA — NÍVEL 2","KIT MÉDICO × 3","GELO × 2","MUNIÇÃO × 120"]
    for i in items.size():
        var p=Panel.new(); p.position=Vector2(35+(i%2)*390,145+(i/2)*105); p.size=Vector2(350,85)
        p.add_theme_stylebox_override("panel",_style(Color("#0D1C29"),Color("#244A59"),14)); ui.add_child(p)
        var l=Label.new(); l.text=items[i]; l.position=Vector2(18,24); l.size=Vector2(315,35); l.add_theme_font_size_override("font_size",18); p.add_child(l)
    var back=_btn("← VOLTAR",Vector2(30,650),Vector2(160,50),Color("#222A34")); back.pressed.connect(_lobby)

func _settings():
    _clear(); _bg(Color("#070C13")); _label("CONFIGURAÇÕES",Vector2(35,30),Vector2(600,50),34)
    _label("REAL CHP BATTLE\n\nCâmera: terceira pessoa\nControles: mobile\nGráficos: compatibilidade Android\nMapa: casas, estrada, árvores, cobertura e loot",Vector2(40,100),Vector2(850,300),19)
    var back=_btn("← VOLTAR",Vector2(30,650),Vector2(160,50),Color("#222A34")); back.pressed.connect(_lobby)

func _battle():
    _clear(); _bg(Color("#111922"))
    _label("BATTLE ROYALE",Vector2(30,25),Vector2(500,50),34)
    _label("O lobby está funcionando. Esta tela é o próximo módulo de combate.",Vector2(32,85),Vector2(900,40),18)
    var p=Panel.new(); p.position=Vector2(60,160); p.size=Vector2(1160,360)
    p.add_theme_stylebox_override("panel",_style(Color("#0A1620"),Color("#48E5B7"),22)); ui.add_child(p)
    var l=Label.new(); l.text="REAL CHP BATTLE\n\nKOSMOS • "+skin+"\n\nMAPA: REAL CHAPERO\nJOGADORES: 8\nMUNIÇÃO: 30 / 30"
    l.position=Vector2(55,45); l.size=Vector2(800,260); l.add_theme_font_size_override("font_size",28); p.add_child(l)
    var back=_btn("← VOLTAR AO LOBBY",Vector2(30,650),Vector2(240,50),Color("#222A34")); back.pressed.connect(_lobby)
