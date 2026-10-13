# PERSISTENT DARKNESS

Soulslike 2D feito em grupo. Godot 4.7, renderer GL Compatibility.

## Estrutura de pastas

```
addons/godot_state_charts/   addon de máquina de estados (NÃO editar)
godot_state_charts_examples/ exemplos do addon (ignorar)
assets/sprites/              arte (enemies/, projectiles/, ...)
game/scenes/                 cenas .tscn (enemies/, player/, projectiles/, test/, ui/)
game/scripts/                scripts .gd espelhando scenes/ (enemies/, player/, projectiles/, test/, ui/, logic/)
game/resources/              resources (.tres)
```

## Regras de código

- Lógica fica nos scripts `.gd`; os `.tscn` guardam só a estrutura de nós e valores de inspector.
- Estilo: indentação com tabs, comentários em português.
- Exports agrupados com `@export_category('...')` e nomes em MAIÚSCULAS (ver `game/scripts/enemies/boss.gd`).
- Todo número ajustável (velocidade, dano, duração, distância...) vira `@export`.
- Máquinas de estado usam o addon `godot_state_charts` (StateChart, CompoundState, AtomicState, Transition).
  Não criar StateMachine própria.
  - Durações: transição automática com `delay_in_seconds` (é cancelada se o estado for interrompido).
  - Valores vindos de exports entram nas expressões via `state_chart.set_expression_property()`.
  - Transição num estado pai (ex.: `Root`) vale para qualquer filho ativo que não consumir o evento.
  - Guards de transições atrasadas são avaliados quando a transição é enfileirada (entrada no estado),
	não quando o delay termina.

## Camadas de física

| Camada | Nome       | Bitmask |
|--------|------------|---------|
| 1      | terrain    | 1       |
| 2      | player     | 2       |
| 3      | boss       | 4       |
| 4      | projectile | 8       |

## Contrato de dano

- O player tem um `Area2D` de hurtbox na camada 2 (player).
- O dono (`owner`) dessa hurtbox implementa `take_damage(amount: int, knockback: Vector2)`.
- Quem causa dano só chama se `owner.has_method("take_damage")`.
- O player deve estar no grupo `"player"` (o boss procura o alvo por esse grupo).

## Boss (Soul of Cinder)

- Cena: `game/scenes/enemies/boss.tscn`, script: `game/scripts/enemies/boss.gd`.
- Estados em `StateChart/Root`: Idle, Walk, Attack1 (ComboA), Attack2 (ComboB), Rest, Stunned.
- Eventos: `player_close` (Walk → Attack1), `posture_broken` (qualquer estado → Stunned).
- Ataques: `AttackN` (composto) contém um ou mais golpes (`ComboA`, futuro `Uppercut`...); cada golpe é
  composto de fases `AttackPhase` (`game/scripts/enemies/attacks/`): Telegraphy → Hit1 → Gap → Hit2 → Recovery.
  A fase liga/desliga a `MeleeHitbox` ao entrar e sempre desliga ao sair. Dano só em fase com hitbox ativa,
  nunca por contato. Durações, dano e knockback dos combos ficam nos exports do `boss.gd`.
- Cena de teste: `game/scenes/test/boss_test_scene.tscn` (usa `player_dummy.tscn`).

## Fluxo de git

- Nunca trabalhar direto na `main`. Uma branch por feature (ex.: `boss-state-chart`, `power-wave`).
- Não editar `.tscn` de outra pessoa (cenas são difíceis de mesclar). Precisa testar algo? Crie uma
  cena de teste nova em `game/scenes/test/`.
- Arquivos atuais com dono: Power Wave (`power_wave.gd`, `power_wave.tscn`, `test_scene.tscn`).
- `.godot/` não vai pro repositório.
- Abra PR para a `main` e peça revisão; não faça push forçado em branch compartilhada.
