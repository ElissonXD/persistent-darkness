class_name CardData
extends Resource


# Uma carta é só DADO: um nome, uma raridade e uma lista de StatModifier. Não existe código
# especial por raridade: o efeito inteiro está em MODIFIERS e quem aplica é o PlayerStats.
#
# COMO CRIAR UMA CARTA NOVA (sem código):
#   1. No FileSystem da Godot, na pasta game/resources/cards/, clique com o botão direito >
#      Novo > Resource... > CardData e salve (ex.: carta_pe_leve.tres).
#   2. No Inspetor, preencha nome, descrição e raridade.
#   3. Em MODIFIERS, adicione itens "StatModifier" e preencha STAT, FLAT e MULT.
#      STAT precisa ser EXATAMENTE o nome de um @export do player_stats.gd.

# COMO USAR (quem controla o fluxo da run): player.STATS.apply_card(carta). Para tirar:
# player.STATS.remove_card(carta). A RARITY serve para a tela de escolha e o sorteio.

enum Rarity { COMMON, NORMAL, LEGENDARY }

@export_category('Carta')
@export var CARD_NAME : String = ''
@export_multiline var DESCRIPTION : String = ''
@export var RARITY : Rarity = Rarity.COMMON
@export var MODIFIERS : Array[StatModifier] = []
