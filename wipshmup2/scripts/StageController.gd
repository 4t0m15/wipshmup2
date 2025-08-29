class_name StageController
extends Node

signal enemy_killed(points: int)
signal stage_completed(stage_number: int)
signal boss_defeated()

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy/Enemy.tscn")
const PE_BASE: PackedScene = preload("res://scenes/enemy/PatternEnemyBase.tscn")

const TYPE01: PackedScene = preload("res://scenes/enemy/types/Type01_StraightAimed.tscn")
const TYPE02: PackedScene = preload("res://scenes/enemy/types/Type02_SineFan.tscn")
const TYPE03: PackedScene = preload("res://scenes/enemy/types/Type03_ZigzagShotgun.tscn")
const TYPE04: PackedScene = preload("res://scenes/enemy/types/Type04_DiagonalLeftRing.tscn")
const TYPE05: PackedScene = preload("res://scenes/enemy/types/Type05_DiagonalRightRing.tscn")
const TYPE06: PackedScene = preload("res://scenes/enemy/types/Type06_DiveAimed.tscn")

const FORMATION_FIGHTER: PackedScene = preload("res://scenes/enemy/types/FormationFighter.tscn")
const FORMATION_BOMBER: PackedScene = preload("res://scenes/enemy/types/FormationBomber.tscn")
const ESCORT_FIGHTER: PackedScene = preload("res://scenes/enemy/types/EscortFighter.tscn")

const TYPE07: PackedScene = preload("res://scenes/enemy/types/Type07_ChaserDrone.tscn")
const TYPE08: PackedScene = preload("res://scenes/enemy/types/Type08_HeavyBomber.tscn")
const TYPE09: PackedScene = preload("res://scenes/enemy/types/Type09_WeavingInterceptor.tscn")
const TYPE10: PackedScene = preload("res://scenes/enemy/types/Type10_DivingAssault.tscn")
const TYPE11: PackedScene = preload("res://scenes/enemy/types/Type11_PatrolGunship.tscn")
const TYPE12: PackedScene = preload("res://scenes/enemy/types/Type12_KamikazeStriker.tscn")
const TYPE13: PackedScene = preload("res://scenes/enemy/types/Type13_FormationLeader.tscn")

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
	stage_order.clear()
	for n in [1, 2, 3, 4, 5, 6, 7, 8]:
		stage_order.append(n)
	current_stage_index = 0
	_start_current_stage()

	if not get_node_or_null("/root/FormationManager"):
		var formation_manager = load("res://scripts/FormationManager.gd").new()
		get_tree().root.call_deferred("add_child", formation_manager)

func _process(delta: float) -> void:
	var formation_manager = get_node_or_null("/root/FormationManager")
	if formation_manager and formation_manager.has_method("update_formations"):
		formation_manager.update_formations(delta)
	_cleanup_bottom_stragglers()

func _cleanup_bottom_stragglers() -> void:
	var root := get_tree().current_scene
	if not root: return
	var rect := get_viewport().get_visible_rect()
	var enemies := root.get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if e and e is Node2D and e.global_position.y >= rect.size.y - 1:
			e.queue_free()

func _start_current_stage() -> void:
	if current_stage_index < 0 or current_stage_index >= stage_order.size():
		# Loop back to stage 1 when we reach the end
		current_stage_index = 0
	var stage_num := stage_order[current_stage_index]
	if typeof(RankManager) != TYPE_NIL:
		RankManager.reset(stage_num)

	var stage_funcs = {
		1: _run_stage_1, 2: _run_stage_2, 3: _run_stage_3, 4: _run_stage_4,
		5: _run_stage_5, 6: _run_stage_6, 7: _run_stage_7, 8: _run_stage_8
	}

	if stage_funcs.has(stage_num):
		await stage_funcs[stage_num].call()
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

func _spawn_enemy(
	scene: PackedScene, pos: Vector2, speed: float = 75.0,
	hp: int = 1, points: int = 100
) -> void:
	var e: Area2D = scene.instantiate()
	e.set("speed", speed)
	e.set("hp", hp)
	e.set("points", points)
	e.global_position = pos
	_connect_enemy_signals(e)
	var root := get_tree().current_scene
	var container := root.get_node_or_null("GameViewport/Enemies")
	var target = container if container else root
	target.add_child(e)
	# Ensure collision is properly enabled after adding to scene
	await get_tree().process_frame
	if is_instance_valid(e):
		e.monitoring = true
		e.collision_layer = 1
		e.collision_mask = 0

func _spawn_wave_line(count: int, y: float, speed: float, hp: int, margin: float = 24.0) -> void:
	var width := get_viewport().get_visible_rect().size.x
	var step := (width - margin * 2.0) / float(max(count - 1, 1))
	for i in count:
		var x := margin + step * float(i)
		_spawn_enemy(ENEMY_SCENE, Vector2(x, -y), speed, hp)

func _spawn_wave_v(shape_count: int, speed: float, hp: int) -> void:
	var width := get_viewport().get_visible_rect().size.x
	var center := width * 0.5
	var spread := 100.0
	for i in shape_count:
		var offset := float(i) / float(max(shape_count - 1, 1))
		_spawn_enemy(ENEMY_SCENE, Vector2(center - spread * offset, -32 - 16 * i), speed, hp)
		_spawn_enemy(ENEMY_SCENE, Vector2(center + spread * offset, -32 - 16 * i), speed, hp)

func _spawn_group(
	count: int, enemy_type: PackedScene, start_x: float,
	spacing: float = 60.0
) -> void:
	var base_x := start_x - (count - 1) * spacing * 0.5
	for i in count:
		_spawn_enemy(enemy_type, Vector2(base_x + i * spacing, -32.0))

func _spawn_from_side(enemy_type: PackedScene, side: String, y_offset: float = 0.0) -> void:
	var rect := get_viewport().get_visible_rect()
	var x := -32.0 if side == "left" else rect.size.x + 32.0
	_spawn_enemy(enemy_type, Vector2(x, -40.0 + y_offset))

func _spawn_formation(
	position: Vector2, leader_type: PackedScene,
	wingman_type: PackedScene, member_count: int = 3
) -> void:
	var leader = leader_type.instantiate()
	leader.global_position = position
	_connect_enemy_signals(leader)
	var root := get_tree().current_scene
	var enemies := root.get_node_or_null("GameViewport/Enemies")
	var target = enemies if enemies else root
	target.add_child(leader)
	# Ensure collision is properly enabled after adding to scene
	await get_tree().process_frame
	if is_instance_valid(leader):
		leader.monitoring = true
		leader.collision_layer = 1
		leader.collision_mask = 0

	for i in range(member_count - 1):
		await get_tree().create_timer(0.2, false).timeout
		var wingman = wingman_type.instantiate()
		wingman.global_position = position + Vector2((i + 1) * 50, -10)
		_connect_enemy_signals(wingman)
		target.add_child(wingman)
		# Ensure collision is properly enabled after adding to scene
		await get_tree().process_frame
		if is_instance_valid(wingman):
			wingman.monitoring = true
			wingman.collision_layer = 1
			wingman.collision_mask = 0
		if is_instance_valid(leader) and is_instance_valid(wingman) and leader.has_method("add_formation_member"):
			if wingman is Area2D:
				leader.add_formation_member(wingman)
			else:
				print("WARNING: Wingman is not Area2D type: ", wingman.get_class())

func _spawn_boss(boss_scene: PackedScene, y_pos: float = 48.0) -> void:
	var boss: BossBase = boss_scene.instantiate()
	var boss_defeated_signal = boss.defeated
	var rect := get_viewport().get_visible_rect()
	boss.global_position = Vector2(rect.size.x * 0.5, -32)
	var root := get_tree().current_scene
	var enemies := root.get_node_or_null("GameViewport/Enemies")
	var target = enemies if enemies else root
	target.add_child(boss)
	await get_tree().process_frame
	# Ensure collision is properly enabled after adding to scene
	if is_instance_valid(boss):
		boss.monitoring = true
		boss.collision_layer = 1
		boss.collision_mask = 0
	create_tween().tween_property(boss, "global_position:y", y_pos, 1.2)
	await get_tree().create_timer(1.3, false).timeout
	if is_instance_valid(boss):
		await boss_defeated_signal
		emit_signal("boss_defeated")

# Simplified stage implementations
func _run_stage_1() -> void:
	_spawn_wave_line(5, 50.0, 60.0, 1)
	await get_tree().create_timer(4.0, false).timeout
	_spawn_wave_v(3, 50.0, 1)
	await get_tree().create_timer(6.0, false).timeout
	_spawn_group(3, TYPE01, 200.0)
	await get_tree().create_timer(4.0, false).timeout
	_spawn_boss(GLIATH_SCENE)

func _run_stage_2() -> void:
	_spawn_group(4, TYPE02, 150.0)
	await get_tree().create_timer(3.0, false).timeout
	_spawn_from_side(TYPE03, "left")
	_spawn_from_side(TYPE03, "right")
	await get_tree().create_timer(4.0, false).timeout
	_spawn_formation(Vector2(300, -50), FORMATION_FIGHTER, TYPE01, 3)
	await get_tree().create_timer(6.0, false).timeout
	_spawn_boss(TYPE0_SCENE, 56.0)

func _run_stage_3() -> void:
	_spawn_wave_line(6, 60.0, 140.0, 2)
	await get_tree().create_timer(1.5, false).timeout
	_spawn_group(3, TYPE04, 200.0)
	_spawn_group(3, TYPE05, 400.0)
	await get_tree().create_timer(2.5, false).timeout
	_spawn_formation(Vector2(250, -60), FORMATION_BOMBER, ESCORT_FIGHTER, 4)
	await get_tree().create_timer(3.0, false).timeout
	_spawn_boss(IRONCASKET_SCENE, 52.0)

func _run_stage_4() -> void:
	_spawn_wave_v(4, 120.0, 2)
	await get_tree().create_timer(1.0, false).timeout
	_spawn_group(4, TYPE06, 150.0)
	await get_tree().create_timer(2.0, false).timeout
	_spawn_from_side(TYPE07, "left", 20.0)
	_spawn_from_side(TYPE07, "right", -20.0)
	await get_tree().create_timer(2.5, false).timeout
	_spawn_boss(GRAFZEPPELIN_SCENE, 54.0)

func _run_stage_5() -> void:
	_spawn_wave_line(7, 70.0, 160.0, 2)
	await get_tree().create_timer(1.0, false).timeout
	_spawn_group(3, TYPE08, 200.0)
	_spawn_group(3, TYPE09, 400.0)
	await get_tree().create_timer(2.0, false).timeout
	_spawn_formation(Vector2(300, -70), FORMATION_FIGHTER, TYPE10, 4)
	await get_tree().create_timer(3.0, false).timeout
	_spawn_boss(FORTRESS_SCENE, 52.0)

func _run_stage_6() -> void:
	_spawn_wave_v(5, 140.0, 3)
	await get_tree().create_timer(1.0, false).timeout
	_spawn_group(4, TYPE11, 150.0)
	_spawn_group(4, TYPE12, 450.0)
	await get_tree().create_timer(2.0, false).timeout
	_spawn_formation(Vector2(250, -80), FORMATION_BOMBER, ESCORT_FIGHTER, 5)
	await get_tree().create_timer(3.0, false).timeout
	_spawn_boss(CROSSSINKER_SCENE, 54.0)

func _run_stage_7() -> void:
	_spawn_wave_line(8, 80.0, 180.0, 3)
	await get_tree().create_timer(1.0, false).timeout
	_spawn_group(4, TYPE13, 200.0)
	await get_tree().create_timer(2.0, false).timeout
	_spawn_from_side(TYPE07, "left", 30.0)
	_spawn_from_side(TYPE07, "right", -30.0)
	await get_tree().create_timer(2.5, false).timeout
	_spawn_boss(BLOCKADE_SCENE, 52.0)

func _run_stage_8() -> void:
	_spawn_wave_v(6, 160.0, 3)
	await get_tree().create_timer(1.0, false).timeout
	_spawn_group(5, TYPE08, 150.0)
	_spawn_group(5, TYPE09, 450.0)
	await get_tree().create_timer(2.0, false).timeout
	_spawn_formation(Vector2(300, -90), FORMATION_FIGHTER, TYPE10, 5)
	await get_tree().create_timer(3.0, false).timeout
	_spawn_boss(BB_SCENE, 50.0)
	await get_tree().create_timer(2.0, false).timeout
	_spawn_boss(FGR_SCENE, 50.0)
