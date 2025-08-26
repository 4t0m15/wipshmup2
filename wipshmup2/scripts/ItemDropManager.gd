extends Node

# Manages item drop cycles and medal chaining akin to Battle Garegga

signal medal_value_changed(new_value: int)
signal medal_chain_broken()

const MEDAL_SCENE: Script = preload("res://scripts/items/Medal.gd")
const SHOT_ITEM_SCENE: Script = preload("res://scripts/items/ShotItem.gd")
const OPTION_ITEM_SCENE: Script = preload("res://scripts/items/OptionItem.gd")
const BOMB_FRAG_SCENE: Script = preload("res://scripts/items/BombFragment.gd")

@export var drop_every_n_kills: int = 5

# Cycle: small shot, large medal, small shot, large medal, option
var _drop_cycle: Array = [
	{"type": "small_shot"},
	{"type": "large_medal"},
	{"type": "small_shot"},
	{"type": "large_medal"},
	{"type": "option"},
	{"type": "bomb_small"},
]

var _cycle_index: int = 0
var _popcorn_kill_counter: int = 0

# Medal chain state: 100..900 by 100, then 1000..10000 by 1000
var _medal_value: int = 100

func _ensure_items_container() -> Node2D:
	var root := get_tree().current_scene
	if not root:
		return null
	var gv := root.get_node_or_null("GameViewport")
	if not gv:
		return root
	var items := gv.get_node_or_null("Items")
	if not items:
		items = Node2D.new()
		items.name = "Items"
		gv.add_child(items)
	return items

func reset_chain() -> void:
	_medal_value = 100
	emit_signal("medal_value_changed", _medal_value)

func on_medal_collected() -> void:
	# Step up medal value
	if _medal_value < 900:
		_medal_value += 100
	elif _medal_value < 10000:
		_medal_value += 1000
	else:
		_medal_value = 10000
	emit_signal("medal_value_changed", _medal_value)

func get_medal_value() -> int:
	return _medal_value

func on_medal_missed() -> void:
	reset_chain()
	emit_signal("medal_chain_broken")

func on_enemy_killed(pos: Vector2, enemy: Node) -> void:
	# Ignore bosses for cycle purposes
	if enemy and enemy.is_in_group("boss"):
		return
	_popcorn_kill_counter += 1
	if _popcorn_kill_counter % max(1, drop_every_n_kills) != 0:
		return
	var drop_def: Dictionary = _drop_cycle[_cycle_index]
	_cycle_index = (_cycle_index + 1) % _drop_cycle.size()
	match String(drop_def.get("type", "")):
		"small_shot":
			_spawn_shot_item(pos, false)
		"large_medal":
			_spawn_medal(pos, _medal_value)
		"option":
			_spawn_option_item(pos)
		"bomb_small":
			_spawn_bomb_frag(pos, 1)
		_:
			_spawn_medal(pos, _medal_value)

func _spawn_medal(pos: Vector2, value: int) -> void:
	var items := _ensure_items_container()
	if not items:
		return
	var medal := Area2D.new()
	medal.set_script(MEDAL_SCENE)
	medal.set("value", value)
	medal.global_position = pos
	items.add_child(medal)

func _spawn_shot_item(pos: Vector2, is_large: bool) -> void:
	var items := _ensure_items_container()
	if not items:
		return
	var it := Area2D.new()
	it.set_script(SHOT_ITEM_SCENE)
	it.set("is_large", is_large)
	it.global_position = pos
	items.add_child(it)

func _spawn_option_item(pos: Vector2) -> void:
	var items := _ensure_items_container()
	if not items:
		return
	var it := Area2D.new()
	it.set_script(OPTION_ITEM_SCENE)
	it.global_position = pos
	items.add_child(it)

func _spawn_bomb_frag(pos: Vector2, shards: int) -> void:
	var items := _ensure_items_container()
	if not items:
		return
	var it := Area2D.new()
	it.set_script(BOMB_FRAG_SCENE)
	it.set("shards", shards)
	it.global_position = pos
	items.add_child(it)
