class_name ItemDropManager
extends Node

# Item drop system for power-ups, score items, and special pickups

signal item_collected(item_type: String, value: int)

enum ItemType {
	POWER_UP,
	SCORE_SMALL,
	SCORE_LARGE,
	LIFE_EXTEND,
	BOMB,
	SHIELD
}

const POWER_UP_SCENE: PackedScene = preload("res://scenes/items/PowerUp.tscn")
const SCORE_ITEM_SCENE: PackedScene = preload("res://scenes/items/ScoreItem.tscn")

var drop_rates := {
	ItemType.POWER_UP: 0.15,
	ItemType.SCORE_SMALL: 0.3,
	ItemType.SCORE_LARGE: 0.05,
	ItemType.LIFE_EXTEND: 0.01,
	ItemType.BOMB: 0.08,
	ItemType.SHIELD: 0.02
}

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func try_drop_item(position: Vector2, enemy_points: int = 100) -> void:
	var drop_chance := _calculate_drop_chance(enemy_points)

	if _rng.randf() <= drop_chance:
		var item_type := _select_item_type()
		_spawn_item(item_type, position)

func _calculate_drop_chance(enemy_points: int) -> float:
	# Higher value enemies have better drop rates
	var base_chance := 0.2
	var point_multiplier := min(enemy_points / 1000.0, 2.0)
	return base_chance * point_multiplier

func _select_item_type() -> ItemType:
	var total_weight := 0.0
	for rate in drop_rates.values():
		total_weight += rate

	var roll := _rng.randf() * total_weight
	var current_weight := 0.0

	for item_type in drop_rates:
		current_weight += drop_rates[item_type]
		if roll <= current_weight:
			return item_type

	return ItemType.SCORE_SMALL  # Fallback

func _spawn_item(item_type: ItemType, position: Vector2) -> void:
	var item_scene: PackedScene

	match item_type:
		ItemType.POWER_UP, ItemType.LIFE_EXTEND, ItemType.BOMB, ItemType.SHIELD:
			if ResourceLoader.exists("res://scenes/items/PowerUp.tscn"):
				item_scene = load("res://scenes/items/PowerUp.tscn")
			else:
				return  # Skip if scene doesn't exist
		_:
			if ResourceLoader.exists("res://scenes/items/ScoreItem.tscn"):
				item_scene = load("res://scenes/items/ScoreItem.tscn")
			else:
				return  # Skip if scene doesn't exist

	var item = item_scene.instantiate()
	item.global_position = position
	item.set("item_type", item_type)

	var root := get_tree().current_scene
	var container := root.get_node_or_null("GameViewport/Items")
	var target = container if container else root
	target.add_child(item)

func force_drop_item(item_type: ItemType, position: Vector2) -> void:
	_spawn_item(item_type, position)

func set_drop_rate(item_type: ItemType, rate: float) -> void:
	drop_rates[item_type] = clamp(rate, 0.0, 1.0)

func get_drop_rate(item_type: ItemType) -> float:
	return drop_rates.get(item_type, 0.0)
