extends Node

signal enemy_killed(points: int)
signal stage_completed(stage_number: int)

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy/Enemy.tscn")
const GLIATH_SCENE: PackedScene = preload("res://scenes/boss/gliath/Gliath.tscn")
const TYPE0_SCENE: PackedScene = preload("res://scenes/boss/type0/Type0.tscn")
const IRONCASKET_SCENE: PackedScene = preload("res://scenes/boss/ironcasket/IronCasket.tscn")
const GRAFZEPPELIN_SCENE: PackedScene = preload("res://scenes/boss/grafzeppelin/GrafZeppelin.tscn")
const FORTRESS_SCENE: PackedScene = preload("res://scenes/boss/fortress/Fortress.tscn")
const CROSSSINKER_SCENE: PackedScene = preload("res://scenes/boss/crosssinker/CrossSinker.tscn")
const BLOCKADE_SCENE: PackedScene = preload("res://scenes/boss/blockade/BlockAde.tscn")
const FGR_SCENE: PackedScene = preload("res://scenes/boss/fgr/FGR.tscn")
const BB_SCENE: PackedScene = preload("res://scenes/boss/bb/BB.tscn")

var stage_order: Array[int] = []
var current_stage_index: int = 0

func start_run() -> void:
	# Build randomized order for 1-4, then fixed 5-8
	var early: Array[int] = [1, 2, 3, 4]
	early.shuffle()
	stage_order.clear()
	for n in early:
		stage_order.append(n)
	for n in [5, 6, 7, 8]:
		stage_order.append(n)
	current_stage_index = 0
	_start_current_stage()

func _start_current_stage() -> void:
	if current_stage_index < 0 or current_stage_index >= stage_order.size():
		return
	var stage_num := stage_order[current_stage_index]
	if typeof(RankManager) != TYPE_NIL:
		RankManager.reset(stage_num)
	match stage_num:
		1:
			await _run_stage_1()
			emit_signal("stage_completed", stage_num)
			current_stage_index += 1
			_start_current_stage()
		2:
			await _run_stage_2()
			emit_signal("stage_completed", stage_num)
			current_stage_index += 1
			_start_current_stage()
		3:
			await _run_stage_3()
			emit_signal("stage_completed", stage_num)
			current_stage_index += 1
			_start_current_stage()
		4:
			await _run_stage_4()
			emit_signal("stage_completed", stage_num)
			current_stage_index += 1
			_start_current_stage()
		5:
			await _run_stage_5()
			emit_signal("stage_completed", stage_num)
			current_stage_index += 1
			_start_current_stage()
		6:
			await _run_stage_6()
			emit_signal("stage_completed", stage_num)
			current_stage_index += 1
			_start_current_stage()
		7:
			await _run_stage_7()
			emit_signal("stage_completed", stage_num)
			current_stage_index += 1
			_start_current_stage()
		8:
			await _run_stage_8()
			emit_signal("stage_completed", stage_num)
			current_stage_index += 1
			_start_current_stage()
		_:
			# Placeholder for other stages
			emit_signal("stage_completed", stage_num)
			current_stage_index += 1
			_start_current_stage()

func _connect_enemy_signals(enemy: Area2D) -> void:
	if enemy.has_signal("killed"):
		enemy.killed.connect(func(points: int):
			emit_signal("enemy_killed", points)
			if typeof(RankManager) != TYPE_NIL and RankManager.has_method("on_enemy_killed"):
				RankManager.on_enemy_killed(points)
		)

func _spawn_enemy_at(pos: Vector2, speed: float = 150.0, hp: int = 1, points: int = 100) -> void:
	var e: Area2D = ENEMY_SCENE.instantiate()
	# Enemy exports these properties; set directly without has_variable (Godot 4)
	e.set("speed", speed)
	e.set("hp", hp)
	e.set("points", points)
	e.global_position = pos
	_connect_enemy_signals(e)
	var root := get_tree().current_scene
	var container := root.get_node_or_null("Enemies")
	if container:
		container.add_child(e)
	else:
		root.add_child(e)

func _spawn_wave_line(count: int, y: float, speed: float, hp: int, margin: float = 24.0) -> void:
	var width := get_viewport().get_visible_rect().size.x
	var step := (width - margin * 2.0) / float(max(count - 1, 1))
	for i in count:
		var x := margin + step * float(i)
		_spawn_enemy_at(Vector2(x, -y), speed, hp)

func _spawn_wave_v(shape_count: int, speed: float, hp: int) -> void:
	# Two diagonal lines forming a V
	var width := get_viewport().get_visible_rect().size.x
	var center := width * 0.5
	var spread := 100.0
	for i in shape_count:
		var offset := float(i) / float(max(shape_count - 1, 1))
		_spawn_enemy_at(Vector2(center - spread * offset, -32 - 16 * i), speed, hp)
		_spawn_enemy_at(Vector2(center + spread * offset, -32 - 16 * i), speed, hp)

func _run_stage_1() -> void:
	# Simple waves then boss
	var rect := get_viewport().get_visible_rect()
	# Wave 1: line
	_spawn_wave_line(6, 32.0, 120.0, 1)
	await get_tree().create_timer(2.0, false).timeout
	# Wave 2: V shape
	_spawn_wave_v(5, 130.0, 1)
	await get_tree().create_timer(2.0, false).timeout
	# Wave 3: heavier line
	_spawn_wave_line(8, 32.0, 140.0, 2)
	await get_tree().create_timer(2.0, false).timeout
	# Boss: Gliath
	var boss: BossBase = GLIATH_SCENE.instantiate()
	boss.global_position = Vector2(rect.size.x * 0.5, -32)
	# Slide in
	var root := get_tree().current_scene
	var enemies := root.get_node_or_null("Enemies")
	if enemies:
		enemies.add_child(boss)
	else:
		root.add_child(boss)
	boss.global_position = Vector2(rect.size.x * 0.5, -32)
	create_tween().tween_property(boss, "global_position:y", 48.0, 1.2)
	await get_tree().create_timer(1.3, false).timeout
	await boss.defeated


func _run_stage_2() -> void:
	# Stage 2: Type-0 Flying Boat themed level
	var rect := get_viewport().get_visible_rect()
	# Opening: dense waves of large planes (simulate with tougher enemies)
	_spawn_wave_line(5, 36.0, 130.0, 2)
	await get_tree().create_timer(2.0, false).timeout
	_spawn_wave_v(6, 140.0, 2)
	await get_tree().create_timer(2.0, false).timeout
	# Mid: three mid-sized planes sweeping in formation
	for sweep in 3:
		# Left to right arc
		var y := 28.0 + float(sweep) * 8.0
		_spawn_enemy_at(Vector2(24.0, -y), 180.0, 3, 300)
		_spawn_enemy_at(Vector2(rect.size.x * 0.5, -y - 12.0), 180.0, 3, 300)
		_spawn_enemy_at(Vector2(rect.size.x - 24.0, -y - 24.0), 180.0, 3, 300)
		await get_tree().create_timer(1.2, false).timeout
	await get_tree().create_timer(1.6, false).timeout
	# Boss: Type-0
	var boss: BossBase = TYPE0_SCENE.instantiate()
	boss.global_position = Vector2(rect.size.x * 0.5, -40)
	var root := get_tree().current_scene
	var enemies := root.get_node_or_null("Enemies")
	if enemies:
		enemies.add_child(boss)
	else:
		root.add_child(boss)
	create_tween().tween_property(boss, "global_position:y", 56.0, 1.2)
	await get_tree().create_timer(1.3, false).timeout
	await boss.defeated


func _run_stage_3() -> void:
	# Stage 3: Iron Casket – ruined town with ground turrets, then boss
	var rect := get_viewport().get_visible_rect()
	_spawn_wave_line(4, 30.0, 90.0, 3)
	await get_tree().create_timer(1.8, false).timeout
	_spawn_wave_v(6, 120.0, 2)
	await get_tree().create_timer(1.8, false).timeout
	var boss: BossBase = IRONCASKET_SCENE.instantiate()
	boss.global_position = Vector2(rect.size.x * 0.5, -36)
	var root := get_tree().current_scene
	var enemies := root.get_node_or_null("Enemies")
	if enemies:
		enemies.add_child(boss)
	else:
		root.add_child(boss)
	create_tween().tween_property(boss, "global_position:y", 52.0, 1.2)
	await get_tree().create_timer(1.2, false).timeout
	await boss.defeated


func _run_stage_4() -> void:
	# Stage 4: Super Carrier – ocean with subs/destroyers then Graf Zeppelin
	var rect := get_viewport().get_visible_rect()
	_spawn_wave_line(6, 34.0, 130.0, 2)
	await get_tree().create_timer(1.8, false).timeout
	_spawn_wave_v(6, 140.0, 2)
	await get_tree().create_timer(1.8, false).timeout
	var boss: BossBase = GRAFZEPPELIN_SCENE.instantiate()
	boss.global_position = Vector2(rect.size.x * 0.5, -36)
	var root := get_tree().current_scene
	var enemies := root.get_node_or_null("Enemies")
	if enemies:
		enemies.add_child(boss)
	else:
		root.add_child(boss)
	create_tween().tween_property(boss, "global_position:y", 54.0, 1.2)
	await get_tree().create_timer(1.2, false).timeout
	await boss.defeated


func _run_stage_5() -> void:
	# Stage 5: Fortress – turreted buildings around narrow bridges
	var rect := get_viewport().get_visible_rect()
	_spawn_wave_line(5, 30.0, 100.0, 3)
	await get_tree().create_timer(1.6, false).timeout
	_spawn_wave_v(7, 130.0, 2)
	await get_tree().create_timer(1.6, false).timeout
	var boss: BossBase = FORTRESS_SCENE.instantiate()
	boss.global_position = Vector2(rect.size.x * 0.5, -36)
	var root := get_tree().current_scene
	var enemies := root.get_node_or_null("Enemies")
	if enemies:
		enemies.add_child(boss)
	else:
		root.add_child(boss)
	create_tween().tween_property(boss, "global_position:y", 52.0, 1.1)
	await get_tree().create_timer(1.1, false).timeout
	await boss.defeated


func _run_stage_6() -> void:
	# Stage 6: Dam valley – towers and missiles, then crab robot
	var rect := get_viewport().get_visible_rect()
	_spawn_wave_line(4, 28.0, 90.0, 3)
	await get_tree().create_timer(1.4, false).timeout
	_spawn_wave_v(5, 120.0, 2)
	await get_tree().create_timer(1.4, false).timeout
	var boss: BossBase = CROSSSINKER_SCENE.instantiate()
	boss.global_position = Vector2(rect.size.x * 0.5, -36)
	var root := get_tree().current_scene
	var enemies := root.get_node_or_null("Enemies")
	if enemies:
		enemies.add_child(boss)
	else:
		root.add_child(boss)
	create_tween().tween_property(boss, "global_position:y", 54.0, 1.1)
	await get_tree().create_timer(1.1, false).timeout
	await boss.defeated


func _run_stage_7() -> void:
	# Stage 7: Block-Ade – industrial machines, then mech
	var rect := get_viewport().get_visible_rect()
	_spawn_wave_line(6, 30.0, 130.0, 2)
	await get_tree().create_timer(1.6, false).timeout
	_spawn_wave_v(6, 130.0, 2)
	await get_tree().create_timer(1.6, false).timeout
	var boss: BossBase = BLOCKADE_SCENE.instantiate()
	boss.global_position = Vector2(rect.size.x * 0.5, -36)
	var root := get_tree().current_scene
	var enemies := root.get_node_or_null("Enemies")
	if enemies:
		enemies.add_child(boss)
	else:
		root.add_child(boss)
	create_tween().tween_property(boss, "global_position:y", 52.0, 1.1)
	await get_tree().create_timer(1.1, false).timeout
	await boss.defeated


func _run_stage_8() -> void:
	# Stage 8: BB mid-boss then FGR
	var rect := get_viewport().get_visible_rect()
	var mid: BossBase = BB_SCENE.instantiate()
	mid.global_position = Vector2(rect.size.x * 0.5, -36)
	var root := get_tree().current_scene
	var enemies := root.get_node_or_null("Enemies")
	if enemies:
		enemies.add_child(mid)
	else:
		root.add_child(mid)
	create_tween().tween_property(mid, "global_position:y", 50.0, 1.0)
	await get_tree().create_timer(1.0, false).timeout
	await mid.defeated
	var boss: BossBase = FGR_SCENE.instantiate()
	boss.global_position = Vector2(rect.size.x * 0.5, -36)
	root = get_tree().current_scene
	enemies = root.get_node_or_null("Enemies")
	if enemies:
		enemies.add_child(boss)
	else:
		root.add_child(boss)
	create_tween().tween_property(boss, "global_position:y", 50.0, 1.0)
	await get_tree().create_timer(1.0, false).timeout
	await boss.defeated
