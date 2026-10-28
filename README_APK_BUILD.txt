REAL CHP — BATTLE 0.2 | PROTÓTIPO GODOT 4.7

Este pacote contém o projeto-fonte e um workflow do GitHub Actions para tentar exportar um APK Android.
A câmera do personagem foi ajustada para terceira pessoa (atrás/acima do personagem), como solicitado.

IMPORTANTE:
- Este ZIP NÃO é um APK instalável.
- O APK só será criado depois que os arquivos forem enviados para um repositório GitHub com Actions habilitado e o workflow terminar com sucesso.
- O workflow está em .github/workflows/build-apk.yml.
- Recursos ainda planejados (não implementados por completo): mapa battle royale grande, loot, veículos, partidas online com 50 jogadores, lobby e progressão/skins.

Arquivos principais:
- project.godot: projeto Godot
- main.tscn: cena principal
- main.gd: protótipo jogável (movimentação, câmera terceira pessoa, tiro, alvos, HUD e habilidade Kosmos)
- export_presets.cfg: configuração de exportação Android
- .github/workflows/build-apk.yml: automação de compilação
