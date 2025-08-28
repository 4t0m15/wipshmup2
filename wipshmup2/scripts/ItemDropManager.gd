extends Node

# Manages item drop cycles (medal system removed)
const SHOT_ITEM_SCENE: Script = preload("res://scripts/items/ShotItem.gd")
const OPTION_ITEM_SCENE: Script = preload("res://scripts/items/OptionItem.gd")
const BOMB_FRAG_SCENE: Script = preload("res://scripts/items/BombFragment.gd")

@export var drop_every_n_kills: int = 5

# Cycle without medals: small shot, small shot, option, bomb
var _drop_cycle: Array = [
	{"type": "small_shot"}, {"type": "small_shot"}, {"type": "option"}, {"type": "bomb_small"}
]

var _cycle_index: int = 0
var _popcorn_kill_counter: int = 0

func _ensure_items_container() -> Node2D:
	var root := get_tree().current_scene
	if not root: return null
	var gv := root.get_node_or_null("GameViewport")
	if not gv: return root
	var items := gv.get_node_or_null("Items")
	if not items:
		items = Node2D.new()
		items.name = "Items"
		gv.call_deferred("add_child", items)
	return items

func on_enemy_killed(pos: Vector2, enemy: Node) -> void:
	# Ignore bosses for cycle purposes
	if enemy and enemy.is_in_group("boss"): return
	_popcorn_kill_counter += 1
	if _popcorn_kill_counter % max(1, drop_every_n_kills) != 0: return
	
	var drop_def: Dictionary = _drop_cycle[_cycle_index]
	_cycle_index = (_cycle_index + 1) % _drop_cycle.size()
	
	match String(drop_def.get("type", "")):
		"small_shot": _spawn_item(SHOT_ITEM_SCENE, pos, {"is_large": false})
		"option": _spawn_item(OPTION_ITEM_SCENE, pos, {})
		"bomb_small": _spawn_item(BOMB_FRAG_SCENE, pos, {"shards": 1})
		_: _spawn_item(SHOT_ITEM_SCENE, pos, {"is_large": false})

func _spawn_item(script: Script, pos: Vector2, properties: Dictionary) -> void:
	var items := _ensure_items_container()
	if not items: return
	var it := Area2D.new()
	it.set_script(script)
	it.global_position = pos
	for key in properties:
		it.set(key, properties[key])
	items.call_deferred("add_child", it)
