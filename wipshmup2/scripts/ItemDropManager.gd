

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




var drop_rates: Dictionary = {


	ItemType.POWER_UP: 0.15,

	ItemType.SCORE_SMALL: 0.3,

	ItemType.SCORE_LARGE: 0.05,

	ItemType.LIFE_EXTEND: 0.01,

	ItemType.BOMB: 0.08,

	ItemType.SHIELD: 0.02

}




var _rng: RandomNumberGenerator = RandomNumberGenerator.new()




# Configuration for auto emit behavior
@export var auto_emit_on_spawn: bool = true
@export var simulate_pickup_delay: float = 0.0  # If > 0, schedules an emit to simulate collection after spawn
@export var score_values := {
	ItemType.SCORE_SMALL: 100,
	ItemType.SCORE_LARGE: 500,
	ItemType.POWER_UP: 0,
	ItemType.LIFE_EXTEND: 0,
	ItemType.BOMB: 0,
	ItemType.SHIELD: 0
}


func _ready() -> void:


	_rng.randomize()

	add_to_group("item_drop_manager")




func try_drop_item(position: Vector2, enemy_points: int = 100) -> void:



	var drop_chance: float = _calculate_drop_chance(enemy_points)


	if _rng.randf() <= drop_chance:


		var item_type: ItemType = _select_item_type()


		_spawn_item(item_type, position)




func _calculate_drop_chance(enemy_points: int) -> float:


	var base_chance := 0.2
	var point_multiplier: float = min(enemy_points / 1000.0, 2.0)

	return base_chance * point_multiplier




func _select_item_type() -> ItemType:



	var total_weight: float = 0.0


	for rate in drop_rates.values():

		total_weight += rate
	var roll := _rng.randf() * total_weight


	var current_weight: float = 0.0


	for item_type: ItemType in drop_rates:

		current_weight += drop_rates[item_type]

		if roll <= current_weight:

			return item_type

	return ItemType.SCORE_SMALL  # Fallback




func _spawn_item(item_type: ItemType, position: Vector2) -> void:


	print("Spawn item: ", item_type, " at ", position)
	if auto_emit_on_spawn and simulate_pickup_delay <= 0.0:
		_emit_collected(item_type)
	elif auto_emit_on_spawn and simulate_pickup_delay > 0.0:
		call_deferred("_deferred_emit_collected", item_type) # simple delayed pickup simulation


func _deferred_emit_collected(item_type: ItemType) -> void:

	await get_tree().create_timer(simulate_pickup_delay).timeout
	_emit_collected(item_type)


func _emit_collected(item_type: ItemType) -> void:


	var value: int = int(score_values.get(item_type, 0))

	emit_signal("item_collected", str(item_type), value)


func get_drop_rate(item_type: ItemType) -> float:


	return drop_rates.get(item_type, 0.0)




func drop_item(_enemy_position: Vector2, _item_type: String = "powerup") -> void:


	# Legacy function for compatibility (kept intentionally)

	pass



func get_drop_chance(_enemy_type: String) -> float:

	return 0.1


func force_drop_item(item_type: ItemType, position: Vector2) -> void:


	_spawn_item(item_type, position)




func set_drop_rate(item_type: ItemType, rate: float) -> void:


	drop_rates[item_type] = clamp(rate, 0.0, 1.0)
