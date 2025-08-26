class_name StageController
extends Node

signal enemy_killed(points: int)
signal stage_completed(stage_number: int)

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy/Enemy.tscn")
const PE_BASE: PackedScene = preload("res://scenes/enemy/PatternEnemyBase.tscn")
const TYPE01: PackedScene = preload("res://scenes/enemy/types/Type01_StraightAimed.tscn")
const TYPE02: PackedScene = preload("res://scenes/enemy/types/Type02_SineFan.tscn")
const TYPE03: PackedScene = preload("res://scenes/enemy/types/Type03_ZigzagShotgun.tscn")
const TYPE04: PackedScene = preload("res://scenes/enemy/types/Type04_DiagonalLeftRing.tscn")
const TYPE05: PackedScene = preload("res://scenes/enemy/types/Type05_DiagonalRightRing.tscn")
const TYPE06: PackedScene = preload("res://scenes/enemy/types/Type06_DiveAimed.tscn")
const TYPE07: PackedScene = preload("res://scenes/enemy/types/Type07_PauseDualLasers.tscn")
const TYPE08: PackedScene = preload("res://scenes/enemy/types/Type08_SweeperCross.tscn")
const TYPE09: PackedScene = preload("res://scenes/enemy/types/Type09_BackForthRing.tscn")
const TYPE10: PackedScene = preload("res://scenes/enemy/types/Type10_CircleRotate.tscn")
const TYPE11: PackedScene = preload("res://scenes/enemy/types/Type11_StraightFan.tscn")
const TYPE12: PackedScene = preload("res://scenes/enemy/types/Type12_SineRing.tscn")
const TYPE13: PackedScene = preload("res://scenes/enemy/types/Type13_ZigzagDualLaser.tscn")
const TYPE14: PackedScene = preload("res://scenes/enemy/types/Type14_DiveShotgun.tscn")
const TYPE15: PackedScene = preload("res://scenes/enemy/types/Type15_PauseSweepFan.tscn")
const TYPE16: PackedScene = preload("res://scenes/enemy/types/Type16_SweeperRotatingRings.tscn")
const TYPE17: PackedScene = preload("res://scenes/enemy/types/Type17_BackForthCrossHatch.tscn")
const TYPE18: PackedScene = preload("res://scenes/enemy/types/Type18_CircleFixedBeams.tscn")
const TYPE19: PackedScene = preload("res://scenes/enemy/types/Type19_StraightRotatingRings.tscn")
const TYPE20: PackedScene = preload("res://scenes/enemy/types/Type20_SineDualLaser.tscn")
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
	# Fixed stage order for a more predictable, "normal" progression
	stage_order.clear()
	for n in [1, 2, 3, 4, 5, 6, 7, 8]:
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
	var container := root.get_node_or_null("GameViewport/Enemies")
	if container:
		container.call_deferred("add_child", e)
	else:
		root.call_deferred("add_child", e)

func _spawn_pattern_enemy(scene: PackedScene, pos: Vector2) -> void:
	var e: Area2D = scene.instantiate()
	e.global_position = pos
	_connect_enemy_signals(e)
	var root := get_tree().current_scene
	var container := root.get_node_or_null("GameViewport/Enemies")
	if container:
		container.call_deferred("add_child", e)
	else:
		root.call_deferred("add_child", e)

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

# New shmup-style spawn functions
func _spawn_small_group(count: int, enemy_type: PackedScene,
		start_x: float, spacing: float = 60.0) -> void:
	"""Spawn a small group of enemies in a horizontal line"""
	var base_x := start_x - (count - 1) * spacing * 0.5
	for i in count:
		_spawn_pattern_enemy(enemy_type, Vector2(base_x + i * spacing, -32.0))

func _spawn_single_from_side(enemy_type: PackedScene, side: String, y_offset: float = 0.0) -> void:
	"""Spawn a single enemy from left or right side"""
	var rect := get_viewport().get_visible_rect()
	var x := -32.0 if side == "left" else rect.size.x + 32.0
	var y := 60.0 + y_offset
	_spawn_pattern_enemy(enemy_type, Vector2(x, y))

func _spawn_dual_from_sides(enemy_type1: PackedScene, enemy_type2: PackedScene,
		y_offset: float = 0.0) -> void:
	"""Spawn two enemies, one from each side"""
	_spawn_single_from_side(enemy_type1, "left", y_offset)
	_spawn_single_from_side(enemy_type2, "right", y_offset)

func _spawn_triple_staggered(enemy_types: Array, center_y: float = 60.0) -> void:
	"""Spawn three enemies in a staggered pattern"""
	var rect := get_viewport().get_visible_rect()
	var positions := [
		Vector2(rect.size.x * 0.3, center_y - 20),
		Vector2(rect.size.x * 0.5, center_y),
		Vector2(rect.size.x * 0.7, center_y + 20)
	]

	for i in min(enemy_types.size(), positions.size()):
		if enemy_types[i]:
			_spawn_pattern_enemy(enemy_types[i], positions[i])


func _run_stage_1() -> void:
	# Simpler, more traditional top-entry waves (no side spawns)
	var rect := get_viewport().get_visible_rect()

	# Wave 1: Straight line of 5 basic enemies
	_spawn_wave_line(5, 24.0, 90.0, 1)
	await get_tree().create_timer(2.0, false).timeout

	# Wave 2: Wider line of 7, slightly slower
	_spawn_wave_line(7, 28.0, 85.0, 1, 18.0)
	await get_tree().create_timer(2.2, false).timeout

	# Wave 3: Two quick staggered lines
	_spawn_wave_line(6, 24.0, 95.0, 1)
	await get_tree().create_timer(0.6, false).timeout
	_spawn_wave_line(6, 24.0, 95.0, 1)
	await get_tree().create_timer(2.0, false).timeout

	# Wave 4: Centered singles from top
	var xs := [rect.size.x * 0.2, rect.size.x * 0.4, rect.size.x * 0.6, rect.size.x * 0.8]
	for x in xs:
		_spawn_enemy_at(Vector2(x, -24.0), 100.0, 1, 150)
		await get_tree().create_timer(0.5, false).timeout
	await get_tree().create_timer(2.0, false).timeout

	# Boss: Gliath
	var boss: BossBase = GLIATH_SCENE.instantiate()
	var boss_defeated_signal = boss.defeated
	boss.global_position = Vector2(rect.size.x * 0.5, -32)
	# Slide in
	var root := get_tree().current_scene
	var enemies := root.get_node_or_null("GameViewport/Enemies")
	if enemies:
		enemies.call_deferred("add_child", boss)
	else:
		root.call_deferred("add_child", boss)
	boss.global_position = Vector2(rect.size.x * 0.5, -32)
	await get_tree().process_frame
	create_tween().tween_property(boss, "global_position:y", 48.0, 1.2)
	await get_tree().create_timer(1.3, false).timeout
	if is_instance_valid(boss):
		await boss_defeated_signal


func _run_stage_2() -> void:
	# Traditional shmup-style waves: small groups with varied timing
	var rect := get_viewport().get_visible_rect()

	# Opening: Alternating single spawns
	_spawn_single_from_side(TYPE11, "right")
	await get_tree().create_timer(1.8, false).timeout
	_spawn_single_from_side(TYPE12, "left")
	await get_tree().create_timer(1.8, false).timeout

	# Wave 1: Dual pair from sides
	_spawn_dual_from_sides(TYPE06, TYPE14)
	await get_tree().create_timer(2.5, false).timeout

	# Wave 2: Quick succession singles
	_spawn_single_from_side(TYPE11, "left", 30)
	await get_tree().create_timer(0.8, false).timeout
	_spawn_single_from_side(TYPE12, "right", -30)
	await get_tree().create_timer(0.8, false).timeout
	_spawn_single_from_side(TYPE06, "left", 0)
	await get_tree().create_timer(2.0, false).timeout

	# Wave 3: Triple diagonal pattern
	_spawn_triple_staggered([TYPE14, TYPE11, TYPE12], 70)
	await get_tree().create_timer(2.5, false).timeout

	# Wave 4: Small center group followed by sides
	_spawn_small_group(2, TYPE06, rect.size.x * 0.5, 70)
	await get_tree().create_timer(1.5, false).timeout
	_spawn_dual_from_sides(TYPE14, TYPE11)
	await get_tree().create_timer(2.0, false).timeout

	# Pre-boss: Mixed patterns
	_spawn_single_from_side(TYPE10, "right", 20)
	await get_tree().create_timer(1.2, false).timeout
	_spawn_single_from_side(TYPE19, "left", -20)
	await get_tree().create_timer(1.2, false).timeout
	_spawn_triple_staggered([TYPE11, TYPE12, TYPE06])
	await get_tree().create_timer(3.0, false).timeout

	# Boss: Type-0
	var boss: BossBase = TYPE0_SCENE.instantiate()
	var boss_defeated_signal = boss.defeated
	boss.global_position = Vector2(rect.size.x * 0.5, -40)
	var root := get_tree().current_scene
	var enemies := root.get_node_or_null("GameViewport/Enemies")
	if enemies:
		enemies.call_deferred("add_child", boss)
	else:
		root.call_deferred("add_child", boss)
	await get_tree().process_frame
	create_tween().tween_property(boss, "global_position:y", 56.0, 1.2)
	await get_tree().create_timer(1.3, false).timeout
	if is_instance_valid(boss):
		await boss_defeated_signal


func _run_stage_3() -> void:
	# Stage 3: Iron Casket – ruined town with ground turrets, then boss
	var rect := get_viewport().get_visible_rect()

	# Opening: Single turret from each side
	_spawn_single_from_side(TYPE07, "left")
	await get_tree().create_timer(1.5, false).timeout
	_spawn_single_from_side(TYPE07, "right")
	await get_tree().create_timer(2.0, false).timeout

	# Wave 1: Dual turrets
	_spawn_dual_from_sides(TYPE09, TYPE07)
	await get_tree().create_timer(2.5, false).timeout

	# Wave 2: Quick turret barrage
	_spawn_single_from_side(TYPE07, "left", -30)
	await get_tree().create_timer(0.7, false).timeout
	_spawn_single_from_side(TYPE09, "right", 30)
	await get_tree().create_timer(0.7, false).timeout
	_spawn_single_from_side(TYPE07, "left", 0)
	await get_tree().create_timer(2.0, false).timeout

	# Wave 3: Triple staggered turrets
	_spawn_triple_staggered([TYPE07, TYPE09, TYPE07])
	await get_tree().create_timer(3.0, false).timeout

	# Wave 4: Mixed patterns
	_spawn_dual_from_sides(TYPE09, TYPE07)
	await get_tree().create_timer(1.5, false).timeout
	_spawn_small_group(2, TYPE07, rect.size.x * 0.5)
	await get_tree().create_timer(2.5, false).timeout

	var boss: BossBase = IRONCASKET_SCENE.instantiate()
	var boss_defeated_signal = boss.defeated
	boss.global_position = Vector2(rect.size.x * 0.5, -36)
	var root := get_tree().current_scene
	var enemies := root.get_node_or_null("GameViewport/Enemies")
	if enemies:
		enemies.call_deferred("add_child", boss)
	else:
		root.call_deferred("add_child", boss)
	await get_tree().process_frame
	create_tween().tween_property(boss, "global_position:y", 52.0, 1.2)
	await get_tree().create_timer(1.2, false).timeout
	if is_instance_valid(boss):
		await boss_defeated_signal


func _run_stage_4() -> void:
	# Stage 4: Super Carrier – ocean with subs/destroyers then Graf Zeppelin
	var rect := get_viewport().get_visible_rect()

	# Opening: Single sweeper from each side
	_spawn_single_from_side(TYPE08, "left")
	await get_tree().create_timer(1.8, false).timeout
	_spawn_single_from_side(TYPE08, "right")
	await get_tree().create_timer(2.0, false).timeout

	# Wave 1: Dual rotating ring types
	_spawn_dual_from_sides(TYPE16, TYPE19)
	await get_tree().create_timer(2.5, false).timeout

	# Wave 2: Quick succession patterns
	_spawn_single_from_side(TYPE08, "left", 25)
	await get_tree().create_timer(1.0, false).timeout
	_spawn_single_from_side(TYPE16, "right", -25)
	await get_tree().create_timer(1.0, false).timeout
	_spawn_single_from_side(TYPE19, "left", 0)
	await get_tree().create_timer(2.0, false).timeout

	# Wave 3: Triple formation
	_spawn_triple_staggered([TYPE08, TYPE16, TYPE19])
	await get_tree().create_timer(2.5, false).timeout

	# Wave 4: Mixed patterns
	_spawn_dual_from_sides(TYPE19, TYPE08)
	await get_tree().create_timer(1.8, false).timeout
	_spawn_small_group(2, TYPE16, rect.size.x * 0.5)
	await get_tree().create_timer(2.5, false).timeout

	var boss: BossBase = GRAFZEPPELIN_SCENE.instantiate()
	var boss_defeated_signal = boss.defeated
	boss.global_position = Vector2(rect.size.x * 0.5, -36)
	var root := get_tree().current_scene
	var enemies := root.get_node_or_null("GameViewport/Enemies")
	if enemies:
		enemies.call_deferred("add_child", boss)
	else:
		root.call_deferred("add_child", boss)
	await get_tree().process_frame
	create_tween().tween_property(boss, "global_position:y", 54.0, 1.2)
	await get_tree().create_timer(1.2, false).timeout
	if is_instance_valid(boss):
		await boss_defeated_signal


func _run_stage_5() -> void:
	# Stage 5: Fortress – turreted buildings around narrow bridges
	var rect := get_viewport().get_visible_rect()

	# Opening: Single fortress turret from each side
	_spawn_single_from_side(TYPE09, "left")
	await get_tree().create_timer(1.6, false).timeout
	_spawn_single_from_side(TYPE09, "right")
	await get_tree().create_timer(2.0, false).timeout

	# Wave 1: Dual beam turrets
	_spawn_dual_from_sides(TYPE18, TYPE09)
	await get_tree().create_timer(2.2, false).timeout

	# Wave 2: Quick beam barrage
	_spawn_single_from_side(TYPE18, "left", -25)
	await get_tree().create_timer(0.9, false).timeout
	_spawn_single_from_side(TYPE09, "right", 25)
	await get_tree().create_timer(0.9, false).timeout
	_spawn_single_from_side(TYPE18, "left", 0)
	await get_tree().create_timer(2.0, false).timeout

	# Wave 3: Triple fortress pattern
	_spawn_triple_staggered([TYPE09, TYPE18, TYPE09])
	await get_tree().create_timer(2.5, false).timeout

	var boss: BossBase = FORTRESS_SCENE.instantiate()
	var boss_defeated_signal = boss.defeated
	boss.global_position = Vector2(rect.size.x * 0.5, -36)
	var root := get_tree().current_scene
	var enemies := root.get_node_or_null("GameViewport/Enemies")
	if enemies:
		enemies.call_deferred("add_child", boss)
	else:
		root.call_deferred("add_child", boss)
	await get_tree().process_frame
	create_tween().tween_property(boss, "global_position:y", 52.0, 1.1)
	await get_tree().create_timer(1.1, false).timeout
	if is_instance_valid(boss):
		await boss_defeated_signal


func _run_stage_6() -> void:
	# Stage 6: Dam valley – towers and missiles, then crab robot
	var rect := get_viewport().get_visible_rect()

	# Opening: Single laser tower from each side
	_spawn_single_from_side(TYPE13, "left")
	await get_tree().create_timer(1.4, false).timeout
	_spawn_single_from_side(TYPE13, "right")
	await get_tree().create_timer(1.8, false).timeout

	# Wave 1: Dual rotating sweepers
	_spawn_dual_from_sides(TYPE16, TYPE13)
	await get_tree().create_timer(2.2, false).timeout

	# Wave 2: Quick succession
	_spawn_single_from_side(TYPE16, "left", 20)
	await get_tree().create_timer(0.8, false).timeout
	_spawn_single_from_side(TYPE13, "right", -20)
	await get_tree().create_timer(0.8, false).timeout
	_spawn_single_from_side(TYPE16, "left", 0)
	await get_tree().create_timer(2.0, false).timeout

	# Wave 3: Triple pattern
	_spawn_triple_staggered([TYPE13, TYPE16, TYPE13])
	await get_tree().create_timer(2.5, false).timeout

	# Wave 4: Mixed waves
	_spawn_dual_from_sides(TYPE16, TYPE13)
	await get_tree().create_timer(1.8, false).timeout
	_spawn_small_group(2, TYPE16, rect.size.x * 0.5)
	await get_tree().create_timer(2.5, false).timeout

	var boss: BossBase = CROSSSINKER_SCENE.instantiate()
	var boss_defeated_signal = boss.defeated
	boss.global_position = Vector2(rect.size.x * 0.5, -36)
	var root := get_tree().current_scene
	var enemies := root.get_node_or_null("GameViewport/Enemies")
	if enemies:
		enemies.call_deferred("add_child", boss)
	else:
		root.call_deferred("add_child", boss)
	await get_tree().process_frame
	create_tween().tween_property(boss, "global_position:y", 54.0, 1.1)
	await get_tree().create_timer(1.1, false).timeout
	if is_instance_valid(boss):
		await boss_defeated_signal


func _run_stage_7() -> void:
	# Stage 7: Block-Ade – industrial machines, then mech
	var rect := get_viewport().get_visible_rect()

	# Opening: Alternating single spawns
	_spawn_single_from_side(TYPE03, "left")
	await get_tree().create_timer(1.2, false).timeout
	_spawn_single_from_side(TYPE20, "right")
	await get_tree().create_timer(1.8, false).timeout

	# Wave 1: Dual diagonal types
	_spawn_dual_from_sides(TYPE04, TYPE05)
	await get_tree().create_timer(2.0, false).timeout

	# Wave 2: Quick industrial barrage
	_spawn_single_from_side(TYPE03, "left", -25)
	await get_tree().create_timer(0.7, false).timeout
	_spawn_single_from_side(TYPE20, "right", 25)
	await get_tree().create_timer(0.7, false).timeout
	_spawn_single_from_side(TYPE04, "left", 0)
	await get_tree().create_timer(1.5, false).timeout

	# Wave 3: Triple industrial pattern
	_spawn_triple_staggered([TYPE05, TYPE03, TYPE20])
	await get_tree().create_timer(2.5, false).timeout

	# Wave 4: Mixed waves
	_spawn_dual_from_sides(TYPE04, TYPE05)
	await get_tree().create_timer(1.5, false).timeout
	_spawn_small_group(2, TYPE03, rect.size.x * 0.5)
	await get_tree().create_timer(2.0, false).timeout

	var boss: BossBase = BLOCKADE_SCENE.instantiate()
	var boss_defeated_signal = boss.defeated
	boss.global_position = Vector2(rect.size.x * 0.5, -36)
	var root := get_tree().current_scene
	var enemies := root.get_node_or_null("GameViewport/Enemies")
	if enemies:
		enemies.call_deferred("add_child", boss)
	else:
		root.call_deferred("add_child", boss)
	await get_tree().process_frame
	create_tween().tween_property(boss, "global_position:y", 52.0, 1.1)
	await get_tree().create_timer(1.1, false).timeout
	if is_instance_valid(boss):
		await boss_defeated_signal


func _run_stage_8() -> void:
	# Stage 8: Final challenge - mixed waves then BB mid-boss then FGR
	var rect := get_viewport().get_visible_rect()

	# Opening: Final challenge begins
	_spawn_single_from_side(TYPE08, "left")
	await get_tree().create_timer(1.5, false).timeout
	_spawn_single_from_side(TYPE16, "right")
	await get_tree().create_timer(1.8, false).timeout

	# Wave 1: Mixed dual spawns
	_spawn_dual_from_sides(TYPE09, TYPE13)
	await get_tree().create_timer(2.0, false).timeout

	# Wave 2: Quick final barrage
	_spawn_single_from_side(TYPE18, "left", -30)
	await get_tree().create_timer(0.8, false).timeout
	_spawn_single_from_side(TYPE20, "right", 30)
	await get_tree().create_timer(0.8, false).timeout
	_spawn_single_from_side(TYPE04, "left", 0)
	await get_tree().create_timer(1.5, false).timeout

	# Wave 3: Triple final pattern
	_spawn_triple_staggered([TYPE08, TYPE16, TYPE09])
	await get_tree().create_timer(2.5, false).timeout

	# Wave 4: Intense mixed waves
	_spawn_dual_from_sides(TYPE13, TYPE18)
	await get_tree().create_timer(1.5, false).timeout
	_spawn_small_group(3, TYPE20, rect.size.x * 0.5, 50)
	await get_tree().create_timer(3.0, false).timeout

	# Mid-boss: BB
	var mid: BossBase = BB_SCENE.instantiate()
	var mid_defeated_signal = mid.defeated
	mid.global_position = Vector2(rect.size.x * 0.5, -36)
	var root := get_tree().current_scene
	var enemies := root.get_node_or_null("GameViewport/Enemies")
	if enemies:
		enemies.call_deferred("add_child", mid)
	else:
		root.call_deferred("add_child", mid)
	await get_tree().process_frame
	create_tween().tween_property(mid, "global_position:y", 50.0, 1.0)
	await get_tree().create_timer(1.0, false).timeout
	if is_instance_valid(mid):
		await mid_defeated_signal

	# Post-mid-boss waves
	_spawn_dual_from_sides(TYPE19, TYPE10)
	await get_tree().create_timer(2.0, false).timeout
	_spawn_triple_staggered([TYPE11, TYPE12, TYPE14])
	await get_tree().create_timer(2.5, false).timeout

	# Final boss: FGR
	var boss: BossBase = FGR_SCENE.instantiate()
	var boss_defeated_signal = boss.defeated
	boss.global_position = Vector2(rect.size.x * 0.5, -36)
	root = get_tree().current_scene
	enemies = root.get_node_or_null("GameViewport/Enemies")
	if enemies:
		enemies.call_deferred("add_child", boss)
	else:
		root.call_deferred("add_child", boss)
	await get_tree().process_frame
	create_tween().tween_property(boss, "global_position:y", 50.0, 1.0)
	await get_tree().create_timer(1.0, false).timeout
	if is_instance_valid(boss):
		await boss_defeated_signal
