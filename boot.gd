extends Node

var layer: CanvasLayer
var ui: Control
var selected := "KOSMOS"
var skin := "DRAGÃO NEGRO"
var coins := 5609
var diamonds := 0
var current_page := "lobby"

var chars := {
    "KOSMOS": Color("#172B55"),
    "LUCAS": Color("#19D7E8"),
    "CUÍCA": Color("#FF8A24"),
    "DANILO": Color("#28D16F"),
    "MARLI": Color("#D84FC0")
}

var skins := {
    "KOSMOS": ["ORIGINAL", "PRATA", "DRAGÃO NEGRO"],
    "LUCAS": ["ORIGINAL", "NEON", "GELO"],
    "CUÍCA": ["ORIGINAL", "FOGO", "OURO"],
    "DANILO": ["ORIGINAL", "VERDE", "TITÃ"],
    "MARLI": ["ORIGINAL", "ROSA", "IMPERIAL"]
}

func _ready():
    layer = CanvasLayer.new()
    layer.layer = 100
    add_child(layer)
    _lobby()

func _clear():
    if ui and is_instance_valid(ui):
        ui.queue_free()
    ui = Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(ui)

func _rect(parent, pos, size, color, radius = 0):
    var p = Panel.new()
    p.position = pos
    p.size = size
    var st = StyleBoxFlat.new()
    st.bg_color = color
    st.set_corner_radius_all(radius)
    p.add_theme_stylebox_override("panel", st)
    parent.add_child(p)
    return p

func _label(parent, txt, pos, size, font_size = 20, color = Color.WHITE):
    var l = Label.new()
    l.text = txt
    l.position = pos
    l.size = size
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", color)
    l.add_theme_color_override("font_shadow_color", Color.BLACK)
    l.add_theme_constant_override("shadow_offset_x", 2)
    l.add_theme_constant_override("shadow_offset_y", 2)
    parent.add_child(l)
    return l

func _button(parent, txt, pos, size, color, callback, font_size = 18):
    var b = Button.new()
    b.text = txt
    b.position = pos
    b.size = size
    b.add_theme_font_size_override("font_size", font_size)
    var normal = StyleBoxFlat.new()
    normal.bg_color = color
    normal.border_color = Color("#70E8C7")
    normal.set_border_width_all(2)
    normal.set_corner_radius_all(9)
    var hover = normal.duplicate()
    hover.bg_color = color.lightened(0.18)
    b.add_theme_stylebox_override("normal", normal)
    b.add_theme_stylebox_override("hover", hover)
    b.add_theme_stylebox_override("pressed", hover)
    parent.add_child(b)
    b.pressed.connect(callback)
    return b

func _background():
    var bg = ColorRect.new()
    bg.color = Color("#101E31")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(bg)

    # Céu e montanhas estilizadas
    _rect(ui, Vector2(0, 310), Vector2(1280, 410), Color("#263F50"))
    var mountain = Polygon2D.new()
    mountain.polygon = PackedVector2Array([
        Vector2(0, 390), Vector2(170, 220), Vector2(320, 360),
        Vector2(500, 185), Vector2(690, 365), Vector2(890, 230),
        Vector2(1090, 360), Vector2(1280, 190),
        Vector2(1280, 720), Vector2(0, 720)
    ])
    mountain.color = Color("#315B61")
    ui.add_child(mountain)

    _rect(ui, Vector2(0, 475), Vector2(1280, 245), Color("#24343A"))
    # Plataformas e prédios decorativos
    for i in range(7):
        var x = i * 195 - 25
        var h = 60 + (i % 3) * 24
        _rect(ui, Vector2(x, 480 - h), Vector2(125, h), Color("#3B5155"))
        for w in range(3):
            _rect(ui, Vector2(x + 15 + w * 32, 495 - h), Vector2(16, 18), Color("#E0B86D"))

    # Plataforma central
    _rect(ui, Vector2(475, 585), Vector2(330, 14), Color("#56DDB8"), 7)
    _rect(ui, Vector2(510, 600), Vector2(260, 9), Color("#0A131D"), 4)

func _avatar(parent, center: Vector2, scale_factor: float, color: Color):
    # Boneco estilizado em 2D; não é um modelo 3D.
    var shadow = _rect(parent, center + Vector2(-60, 115) * scale_factor,
        Vector2(120, 15) * scale_factor, Color("#101820"), 8)

    var leg1 = _rect(parent, center + Vector2(-29, 48) * scale_factor,
        Vector2(24, 75) * scale_factor, Color("#353D49"), 7)
    var leg2 = _rect(parent, center + Vector2(8, 48) * scale_factor,
        Vector2(24, 75) * scale_factor, Color("#353D49"), 7)
    _rect(parent, center + Vector2(-35, 111) * scale_factor,
        Vector2(37, 15) * scale_factor, Color("#D9DCE2"), 5)
    _rect(parent, center + Vector2(4, 111) * scale_factor,
        Vector2(37, 15) * scale_factor, Color("#D9DCE2"), 5)

    _rect(parent, center + Vector2(-40, -25) * scale_factor,
        Vector2(80, 85) * scale_factor, color, 12)
    _rect(parent, center + Vector2(-54, -15) * scale_factor,
        Vector2(18, 65) * scale_factor, color.darkened(0.18), 7)
    _rect(parent, center + Vector2(36, -15) * scale_factor,
        Vector2(18, 65) * scale_factor, color.darkened(0.18), 7)

    _rect(parent, center + Vector2(-20, -67) * scale_factor,
        Vector2(40, 42) * scale_factor, Color("#C78E70"), 12)
    _rect(parent, center + Vector2(-22, -72) * scale_factor,
        Vector2(44, 16) * scale_factor, Color("#171D29"), 8)
    _rect(parent, center + Vector2(-8, -42) * scale_factor,
        Vector2(16, 5) * scale_factor, Color("#202B3A"), 2)

func _topbar():
    _rect(ui, Vector2(0, 0), Vector2(1280, 62), Color("#0A1422"), 0)
    _label(ui, "REAL CHP", Vector2(18, 8), Vector2(210, 42), 28, Color("#70E8C7"))
    _label(ui, "BATTLE", Vector2(195, 13), Vector2(120, 35), 21)
    _rect(ui, Vector2(865, 12), Vector2(145, 38), Color("#263647"), 8)
    _label(ui, "🪙 %d" % coins, Vector2(878, 17), Vector2(125, 28), 18)
    _rect(ui, Vector2(1020, 12), Vector2(115, 38), Color("#263647"), 8)
    _label(ui, "💎 %d" % diamonds, Vector2(1030, 17), Vector2(100, 28), 18)
    _button(ui, "⚙", Vector2(1150, 10), Vector2(48, 42),
        Color("#263647"), _settings, 22)

func _lobby():
    current_page = "lobby"
    _clear()
    _background()
    _topbar()

    _label(ui, "TEMPORADA REAL CHP", Vector2(30, 85),
        Vector2(360, 36), 23, Color("#E9D18B"))
    _label(ui, "A ARENA É SUA.", Vector2(30, 122),
        Vector2(370, 45), 30)
    _label(ui, "Prepare seu personagem e entre na batalha.",
        Vector2(30, 168), Vector2(390, 30), 15)

    _avatar(ui, Vector2(625, 450), 1.35, chars[selected])
    _label(ui, selected, Vector2(530, 250), Vector2(300, 38),
        25, Color("#FFFFFF"))
    _label(ui, "SKIN: " + skin, Vector2(535, 285),
        Vector2(280, 30), 15, Color("#70E8C7"))

    _button(ui, "PERSONAGENS", Vector2(25, 235), Vector2(205, 48),
        Color("#172A3C"), _characters)
    _button(ui, "LOJA", Vector2(25, 292), Vector2(205, 48),
        Color("#172A3C"), _shop)
    _button(ui, "COFRE / INVENTÁRIO", Vector2(25, 349),
        Vector2(205, 48), Color("#172A3C"), _inventory)
    _button(ui, "EVENTOS", Vector2(25, 406), Vector2(205, 48),
        Color("#172A3C"), _events)

    _rect(ui, Vector2(935, 390), Vector2(310, 115), Color("#102335"), 12)
    _label(ui, "MODO DE JOGO", Vector2(955, 402),
        Vector2(260, 26), 16, Color("#70E8C7"))
    _label(ui, "BATTLE ROYALE", Vector2(955, 432),
        Vector2(260, 32), 22)
    _label(ui, "Mapa: REAL CHAPERO", Vector2(955, 465),
        Vector2(260, 25), 15)

    _button(ui, "▶  DECOLAR", Vector2(935, 520), Vector2(310, 74),
        Color("#D9A92B"), _battle, 26)
    _label(ui, "REAL CHP BATTLE • V0.4",
        Vector2(18, 680), Vector2(330, 25), 13, Color("#B9C9D6"))

func _characters():
    current_page = "characters"
    _clear()
    _background()
    _topbar()
    _label(ui, "PERSONAGENS E SKINS", Vector2(28, 82),
        Vector2(600, 45), 30)
    _label(ui, "Escolha seu lutador e personalize o visual.",
        Vector2(30, 125), Vector2(600, 28), 16, Color("#70E8C7"))

    var names = chars.keys()
    for i in range(names.size()):
        var n = names[i]
        _button(ui, n, Vector2(25 + i * 155, 170),
            Vector2(145, 46), chars[n].darkened(0.45),
            _pick_char.bind(n), 15)

    _rect(ui, Vector2(350, 240), Vector2(540, 270),
        Color("#0D1A28"), 16)
    _avatar(ui, Vector2(590, 390), 0.85, chars[selected])
    _label(ui, selected, Vector2(680, 265), Vector2(190, 35), 24)
    _label(ui, "HP: 200\nPERSONAGEM SELECIONADO\nSKIN: " + skin,
        Vector2(680, 310), Vector2(200, 120), 17, Color("#C9D9E7"))

    _label(ui, "SKINS DISPONÍVEIS", Vector2(30, 535),
        Vector2(330, 32), 20)
    for i in range(skins[selected].size()):
        var s = skins[selected][i]
        _button(ui, s, Vector2(30 + i * 195, 575),
            Vector2(180, 48), Color("#1B3548"),
            _pick_skin.bind(s), 15)

    _button(ui, "← VOLTAR", Vector2(30, 645),
        Vector2(160, 45), Color("#25313D"), _lobby)

func _pick_char(n):
    selected = n
    skin = skins[n][0]
    _characters()

func _pick_skin(s):
    skin = s
    _characters()

func _shop():
    current_page = "shop"
    _clear()
    _background()
    _topbar()
    _label(ui, "LOJA REAL CHP", Vector2(30, 85),
        Vector2(500, 45), 30)
    _label(ui, "Itens demonstrativos • moedas locais do protótipo",
        Vector2(32, 130), Vector2(600, 28), 15, Color("#70E8C7"))

    var names = ["SKIN PRATA", "SKIN NEON", "SKIN OURO", "SKIN GELO"]
    var prices = [500, 800, 1200, 1000]
    for i in range(names.size()):
        var x = 35 + (i % 2) * 370
        var y = 190 + int(i / 2) * 180
        _rect(ui, Vector2(x, y), Vector2(335, 145),
            Color("#112336"), 12)
        _label(ui, names[i], Vector2(x + 18, y + 16),
            Vector2(290, 32), 21)
        _label(ui, "🪙 %d" % prices[i], Vector2(x + 18, y + 54),
            Vector2(150, 28), 18, Color("#E9D18B"))
        _button(ui, "COMPRAR", Vector2(x + 170, y + 85),
            Vector2(145, 42), Color("#17634E"),
            _buy_skin.bind(names[i], prices[i]), 15)

    _button(ui, "← VOLTAR", Vector2(30, 645),
        Vector2(160, 45), Color("#25313D"), _lobby)

func _buy_skin(name, price):
    if coins < price:
        _notice("Moedas insuficientes!")
        return
    coins -= price
    skin = name
    _notice(name + " equipada!")
    _shop()

func _notice(message):
    var popup = _rect(ui, Vector2(400, 80), Vector2(480, 58),
        Color("#17634E"), 12)
    _label(popup, message, Vector2(12, 10),
        Vector2(450, 38), 19)

func _inventory():
    current_page = "inventory"
    _clear()
    _background()
    _topbar()
    _label(ui, "COFRE / INVENTÁRIO", Vector2(30, 85),
        Vector2(600, 45), 30)
    _label(ui, "PERSONAGEM: " + selected + "\nSKIN EQUIPADA: " + skin,
        Vector2(40, 155), Vector2(600, 100), 22, Color("#70E8C7"))

    var items = ["UMP EQUIPADA", "COLETE NÍVEL 2",
        "MOCHILA NÍVEL 2", "KIT MÉDICO × 3",
        "GELO × 2", "MUNIÇÃO × 120"]
    for i in range(items.size()):
        var x = 40 + (i % 3) * 390
        var y = 300 + int(i / 3) * 100
        _rect(ui, Vector2(x, y), Vector2(350, 75),
            Color("#12273A"), 10)
        _label(ui, items[i], Vector2(x + 15, y + 20),
            Vector2(320, 35), 17)

    _button(ui, "← VOLTAR", Vector2(30, 645),
        Vector2(160, 45), Color("#25313D"), _lobby)

func _events():
    current_page = "events"
    _clear()
    _background()
    _topbar()
    _label(ui, "EVENTOS", Vector2(30, 85),
        Vector2(400, 45), 30)
    _rect(ui, Vector2(40, 160), Vector2(560, 180),
        Color("#123247"), 15)
    _label(ui, "DESAFIO REAL CHP", Vector2(65, 180),
        Vector2(500, 40), 25, Color("#E9D18B"))
    _label(ui, "Entre na arena e teste suas habilidades.",
        Vector2(65, 230), Vector2(500, 35), 17)
    _label(ui, "Recompensas e eventos online ainda não estão conectados.",
        Vector2(65, 275), Vector2(500, 40), 14)
    _button(ui, "← VOLTAR", Vector2(30, 645),
        Vector2(160, 45), Color("#25313D"), _lobby)

func _settings():
    current_page = "settings"
    _clear()
    _background()
    _topbar()
    _label(ui, "CONFIGURAÇÕES", Vector2(30, 85),
        Vector2(500, 45), 30)
    _label(ui, "REAL CHP BATTLE\n\nOrientação: paisagem\nInterface: mobile\nRenderização: compatibilidade Android\nPersonagem: " + selected,
        Vector2(40, 155), Vector2(650, 240), 20)
    _button(ui, "← VOLTAR", Vector2(30, 645),
        Vector2(160, 45), Color("#25313D"), _lobby)

func _battle():
    current_page = "battle"
    _clear()
    _background()
    _topbar()
    _label(ui, "BATTLE ROYALE", Vector2(30, 85),
        Vector2(500, 45), 32)
    _rect(ui, Vector2(250, 180), Vector2(780, 300),
        Color("#0A1723"), 18)
    _avatar(ui, Vector2(390, 335), 0.65, chars[selected])
    _label(ui, "REAL CHP BATTLE", Vector2(540, 210),
        Vector2(430, 40), 27)
    _label(ui, selected + " • " + skin +
        "\n\nMAPA: REAL CHAPERO\nJOGADORES: 8\nMUNIÇÃO: 30 / 30",
        Vector2(540, 265), Vector2(430, 175), 21)
    _label(ui, "Tela de demonstração. Combate online e partidas reais não estão implementados.",
        Vector2(250, 510), Vector2(780, 45), 15, Color("#F2D18C"))
    _button(ui, "← VOLTAR AO LOBBY", Vector2(30, 645),
        Vector2(240, 45), Color("#25313D"), _lobby)
