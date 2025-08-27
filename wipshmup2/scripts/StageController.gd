class_name StageController
extends Node

signal enemy_killed(points: int)
signal stage_completed(stage_number: int)
signal boss_defeated()

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy/Enemy.tscn")
const PE_BASE: PackedScene = preload("res://scenes/enemy/PatternEnemyBase.tscn")
# Classic 1942-style enemy types
const TYPE01: PackedScene = preload("res://scenes/enemy/types/Type01_StraightAimed.tscn")
const TYPE02: PackedScene = preload("res://scenes/enemy/types/Type02_SineFan.tscn")
const TYPE03: PackedScene = preload("res://scenes/enemy/types/Type03_ZigzagShotgun.tscn")
const TYPE04: PackedScene = preload("res://scenes/enemy/types/Type04_DiagonalLeftRing.tscn")
const TYPE05: PackedScene = preload("res://scenes/enemy/types/Type05_DiagonalRightRing.tscn")
const TYPE06: PackedScene = preload("res://scenes/enemy/types/Type06_DiveAimed.tscn")

# Formation-based enemy types
const FORMATION_FIGHTER: PackedScene = preload("res://scenes/enemy/types/FormationFighter.tscn")
const FORMATION_BOMBER: PackedScene = preload("res://scenes/enemy/types/FormationBomber.tscn")
const ESCORT_FIGHTER: PackedScene = preload("res://scenes/enemy/types/EscortFighter.tscn")

# New 1942-style tactical enemies
const TYPE07: PackedScene = preload("res://scenes/enemy/types/Type07_ChaserDrone.tscn")
const TYPE08: PackedScene = preload("res://scenes/enemy/types/Type08_HeavyBomber.tscn")
const TYPE09: PackedScene = preload("res://scenes/enemy/types/Type09_WeavingInterceptor.tscn")
const TYPE10: PackedScene = preload("res://scenes/enemy/types/Type10_DivingAssault.tscn")
const TYPE11: PackedScene = preload("res://scenes/enemy/types/Type11_PatrolGunship.tscn")
const TYPE12: PackedScene = preload("res://scenes/enemy/types/Type12_KamikazeStriker.tscn")
const TYPE13: PackedScene = preload("res://scenes/enemy/types/Type13_FormationLeader.tscn")
# Legacy types (commented out - files may not exist)
# const TYPE12: PackedScene = preload("res://scenes/enemy/types/Type14_DiveShotgun.tscn")
# const TYPE15: PackedScene = preload("res://scenes/enemy/types/Type15_PauseSweepFan.tscn")
# const TYPE08: PackedScene = preload("res://scenes/enemy/types/Type16_SweeperRotatingRings.tscn")
# const TYPE17: PackedScene = preload("res://scenes/enemy/types/Type17_BackForthCrossHatch.tscn")
# const TYPE09: PackedScene = preload("res://scenes/enemy/types/Type18_CircleFixedBeams.tscn")
# const TYPE10: PackedScene = preload("res://scenes/enemy/types/Type19_StraightRotatingRings.tscn")
# const TYPE11: PackedScene = preload("res://scenes/enemy/types/Type20_SineDualLaser.tscn")
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

	# Initialize formation manager if not present
	if not get_node_or_null("/root/FormationManager"):
		var formation_manager = load("res://scripts/FormationManager.gd").new()
		get_tree().root.call_deferred("add_child", formation_manager)

func _process(delta: float) -> void:
	# Update formation manager each frame
	var formation_manager = get_node_or_null("/root/FormationManager")
	if formation_manager and formation_manager.has_method("update_formations"):
		formation_manager.update_formations(delta)
	# Despawn any stragglers that reach the bottom edge (safety net)
	_cleanup_bottom_stragglers()

func _cleanup_bottom_stragglers() -> void:
	var root := get_tree().current_scene
	if not root:
		return
	var rect := get_viewport().get_visible_rect()
	var enemies := root.get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if e and e is Node2D:
			var n := e as Node2D
			if n.global_position.y >= rect.size.y - 1:
				n.queue_free()

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
	var y := -40.0 + y_offset  # Start above screen, fly down
	_spawn_pattern_enemy(enemy_type, Vector2(x, y))

func _spawn_dual_from_sides(enemy_type1: PackedScene, enemy_type2: PackedScene,
		y_offset: float = 0.0) -> void:
	"""Spawn two enemies, one from each side"""
	_spawn_single_from_side(enemy_type1, "left", y_offset)
	_spawn_single_from_side(enemy_type2, "right", y_offset)

func _spawn_triple_staggered(enemy_types: Array, center_y: float = -40.0) -> void:
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

# Formation spawning functions
func _spawn_fighter_formation(position: Vector2, member_count: int = 3) -> void:
	"""Spawn a fighter formation with leader and wingmen"""
	var leader = FORMATION_FIGHTER.instantiate()
	leader.global_position = position
	_connect_enemy_signals(leader)

	var root := get_tree().current_scene
	var enemies := root.get_node_or_null("GameViewport/Enemies")
	if enemies:
		enemies.call_deferred("add_child", leader)
	else:
		root.call_deferred("add_child", leader)

	# Add wingmen to formation
	for i in range(member_count - 1):
		await get_tree().create_timer(0.1, false).timeout
		var wingman = TYPE01.instantiate()
		var offset = Vector2((i + 1) * 50, -10)  # Spawn slightly behind/above leader
		wingman.global_position = position + offset
		_connect_enemy_signals(wingman)

		if enemies:
			enemies.call_deferred("add_child", wingman)
		else:
			root.call_deferred("add_child", wingman)

		# Add wingman to formation if leader has formation manager
		if is_instance_valid(leader) and leader.has_method("add_formation_member"):
			leader.call_deferred("add_formation_member", wingman)

func _spawn_bomber_escort_formation(position: Vector2, escort_count: int = 2) -> void:
	"""Spawn a bomber with escort fighters"""
	var bomber = FORMATION_BOMBER.instantiate()
	bomber.global_position = position
	_connect_enemy_signals(bomber)

	var root := get_tree().current_scene
	var enemies := root.get_node_or_null("GameViewport/Enemies")
	if enemies:
		enemies.call_deferred("add_child", bomber)
	else:
		root.call_deferred("add_child", bomber)

	# Add escort fighters
	for i in range(escort_count):
		await get_tree().create_timer(0.2, false).timeout
		var escort = ESCORT_FIGHTER.instantiate()
		var escort_offset = Vector2((i - escort_count/2.0) * 60, -25)
		escort.global_position = position + escort_offset
		_connect_enemy_signals(escort)

		if enemies:
			enemies.call_deferred("add_child", escort)
		else:
			root.call_deferred("add_child", escort)

		# Set escort to follow the bomber
		if is_instance_valid(escort) and escort.has_method("set_leader"):
			escort.call_deferred("set_leader", bomber)

		# Add escort to bomber's formation
		if is_instance_valid(bomber) and bomber.has_method("add_escort_member"):
			bomber.call_deferred("add_escort_member", escort)

func _spawn_defensive_line(position: Vector2, turret_count: int = 3) -> void:
	"""Spawn a defensive line of turrets"""
	var rect := get_viewport().get_visible_rect()
	var spacing = rect.size.x / (turret_count + 1)

	for i in range(turret_count):
		var turret_x = spacing * (i + 1)
		var turret = TYPE02.instantiate()
		turret.global_position = Vector2(turret_x, position.y)
		_connect_enemy_signals(turret)

		var root := get_tree().current_scene
		var enemies := root.get_node_or_null("GameViewport/Enemies")
		if enemies:
			enemies.call_deferred("add_child", turret)
		else:
			root.call_deferred("add_child", turret)

func _spawn_formation_wave(formation_type: String, count: int, base_position: Vector2) -> void:
	"""Spawn a wave of formations"""
	match formation_type:
		"fighter_squad":
			for i in range(count):
				var formation_pos = base_position + Vector2(i * 120, 0)
				_spawn_fighter_formation(formation_pos, 3)
				await get_tree().create_timer(1.5, false).timeout

		"bomber_escort":
			for i in range(count):
				var formation_pos = base_position + Vector2(i * 150, 0)
				_spawn_bomber_escort_formation(formation_pos, 2)
				await get_tree().create_timer(2.0, false).timeout

		"mixed_fleet":
			# Mix of different formation types
			for i in range(count):
				if i % 2 == 0:
					_spawn_fighter_formation(base_position + Vector2(i * 100, 0), 2)
				else:
					_spawn_bomber_escort_formation(base_position + Vector2(i * 100, 0), 1)
				await get_tree().create_timer(1.8, false).timeout


func _run_stage_1() -> void:
	# Stage 1: Introduction to formation flying
	var rect := get_viewport().get_visible_rect()

	# Wave 1: Basic fighter formations
	print("Stage 1: Deploying fighter formations...")
	_spawn_formation_wave("fighter_squad", 2, Vector2(rect.size.x * 0.3, -20))
	await get_tree().create_timer(4.0, false).timeout

	# Wave 2: Ground defense line
	print("Stage 1: Establishing defensive positions...")
	_spawn_defensive_line(Vector2(0, -40), 3)
	await get_tree().create_timer(3.5, false).timeout

	# Wave 3: Bomber escort formations
	print("Stage 1: Deploying bomber escort formations...")
	_spawn_formation_wave("bomber_escort", 1, Vector2(rect.size.x * 0.2, -30))
	await get_tree().create_timer(1.0, false).timeout
	_spawn_formation_wave("bomber_escort", 1, Vector2(rect.size.x * 0.8, -30))
	await get_tree().create_timer(4.0, false).timeout

	# Wave 4: Light Chaser Drone Formation (00:45 timing)
	print("Stage 1: Deploying chaser drones...")
	for i in range(5):
		var x_pos = rect.size.x * (0.1 + i * 0.2)  # Evenly spaced across width
		_spawn_pattern_enemy(TYPE07, Vector2(x_pos, -50))
		await get_tree().create_timer(0.3, false).timeout
	await get_tree().create_timer(3.0, false).timeout
	# Wave 5: Mixed fleet approach
	print("Stage 1: Mixed fleet engagement...")
	_spawn_formation_wave("mixed_fleet", 3, Vector2(rect.size.x * 0.15, -25))
	await get_tree().create_timer(5.0, false).timeout

	# Wave 6: Heavy Bomber Line (01:15 timing)
	print("Stage 1: Heavy bombers incoming...")
	for i in range(3):
		var x_pos = rect.size.x * (0.2 + i * 0.3)  # Spaced 120px apart
		_spawn_pattern_enemy(TYPE08, Vector2(x_pos, -50))
		await get_tree().create_timer(0.5, false).timeout
	await get_tree().create_timer(4.0, false).timeout

	# Wave 7: Submarine surfacing behind defenses
	print("Stage 1: Underwater threat detected...")
	_spawn_pattern_enemy(TYPE06, Vector2(rect.size.x * 0.5, -40))  # Submarine from top
	await get_tree().create_timer(3.0, false).timeout

	# Final wave: Intense formation assault
	print("Stage 1: Final formation assault...")
	_spawn_formation_wave("fighter_squad", 2, Vector2(rect.size.x * 0.25, -20))
	await get_tree().create_timer(1.0, false).timeout
	_spawn_formation_wave("bomber_escort", 1, Vector2(rect.size.x * 0.7, -30))
	await get_tree().create_timer(4.0, false).timeout

	# Boss: Gliath
	print("Stage 1: Boss encounter - Gliath")
	var boss: BossBase = GLIATH_SCENE.instantiate()
	var boss_defeated_signal = boss.defeated
	boss.global_position = Vector2(rect.size.x * 0.5, -32)
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
		emit_signal("boss_defeated")


func _run_stage_2() -> void:
	# Stage 2: Advanced formation tactics demonstration
	var rect := get_viewport().get_visible_rect()

	# Opening: V-formation fighter squad
	print("Stage 2: V-Formation fighter squad approaching...")
	_spawn_formation_wave("fighter_squad", 1, Vector2(rect.size.x * 0.4, -20))
	await get_tree().create_timer(4.0, false).timeout

	# Wave 1: Defensive line with flanking maneuvers
	print("Stage 2: Establishing defensive perimeter...")
	_spawn_defensive_line(Vector2(0, -40), 4)  # 4 turrets from top
	await get_tree().create_timer(2.0, false).timeout

	# Wave 1.5: Weaving Interceptors (00:30 timing)
	print("Stage 2: Weaving interceptors detected...")
	for i in range(4):
		var side = 1 if i % 2 == 0 else -1
		var x_pos = rect.size.x * 0.5 + side * 100
		_spawn_pattern_enemy(TYPE09, Vector2(x_pos, -50))
		await get_tree().create_timer(0.5, false).timeout
	await get_tree().create_timer(3.0, false).timeout

	# Flanking maneuver with formations
	_spawn_formation_wave("fighter_squad", 1, Vector2(-30, -30))   # Left flank
	await get_tree().create_timer(0.5, false).timeout
	_spawn_formation_wave("fighter_squad", 1, Vector2(rect.size.x + 30, -30))  # Right flank
	await get_tree().create_timer(4.0, false).timeout

	# Wave 2: Naval patrol with destroyer formations
	print("Stage 2: Naval patrol patterns...")
	_spawn_pattern_enemy(TYPE04, Vector2(-60, -50))   # Left destroyer
	await get_tree().create_timer(1.0, false).timeout
	_spawn_pattern_enemy(TYPE04, Vector2(rect.size.x + 60, -50))  # Right destroyer
	await get_tree().create_timer(2.0, false).timeout

	# Wave 2.5: Diving Assault Fighters (01:00 timing)
	print("Stage 2: Diving assault incoming...")
	for i in range(6):
		var side = 1 if i % 2 == 0 else -1
		var x_pos = side * 50 + rect.size.x * 0.5
		_spawn_pattern_enemy(TYPE10, Vector2(x_pos, -50))
		if i % 2 == 1:  # Every pair
			await get_tree().create_timer(2.0, false).timeout
		else:
			await get_tree().create_timer(0.3, false).timeout
	await get_tree().create_timer(3.0, false).timeout

	# Wave 3: Patrol Gunships (01:30 timing)
	print("Stage 2: Patrol gunships deploying...")
	_spawn_pattern_enemy(TYPE11, Vector2(-50, -40))     # From left
	await get_tree().create_timer(0.1, false).timeout
	_spawn_pattern_enemy(TYPE11, Vector2(rect.size.x + 50, -40))  # From right
	await get_tree().create_timer(4.0, false).timeout

	# Wave 4: Combined arms - bomber escorted by fighters
	print("Stage 2: Combined arms assault...")
	_spawn_formation_wave("bomber_escort", 1, Vector2(rect.size.x * 0.3, -25))
	await get_tree().create_timer(1.0, false).timeout
	_spawn_formation_wave("bomber_escort", 1, Vector2(rect.size.x * 0.7, -25))
	await get_tree().create_timer(4.0, false).timeout

	# Wave 4: Echelon formation attack
	print("Stage 2: Echelon formation attack...")
	# Create staggered formations from both sides
	for i in range(3):
		_spawn_formation_wave("fighter_squad", 1, Vector2(-20 + i * 40, -15 - i * 20))
		_spawn_formation_wave("fighter_squad", 1, Vector2(rect.size.x + 20 - i * 40, -15 - i * 20))
		await get_tree().create_timer(1.5, false).timeout

	# Wave 5: Mixed fleet with submarines
	print("Stage 2: Mixed fleet with underwater elements...")
	_spawn_formation_wave("mixed_fleet", 2, Vector2(rect.size.x * 0.2, -20))
	await get_tree().create_timer(1.0, false).timeout
	_spawn_pattern_enemy(TYPE06, Vector2(rect.size.x * 0.5, -40))  # Submarine from top
	await get_tree().create_timer(1.0, false).timeout
	_spawn_pattern_enemy(TYPE06, Vector2(rect.size.x * 0.3, -40))  # Another submarine
	await get_tree().create_timer(4.0, false).timeout

	# Pre-boss: Maximum formation assault
	print("Stage 2: Maximum formation assault...")
	_spawn_formation_wave("fighter_squad", 2, Vector2(rect.size.x * 0.25, -18))
	await get_tree().create_timer(0.8, false).timeout
	_spawn_formation_wave("bomber_escort", 1, Vector2(rect.size.x * 0.6, -25))
	await get_tree().create_timer(0.8, false).timeout
	_spawn_defensive_line(Vector2(0, -40), 2)  # Additional turrets
	await get_tree().create_timer(4.0, false).timeout

	# Boss: Type-0
	print("Stage 2: Boss encounter - Type-0")
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
		emit_signal("boss_defeated")


func _run_stage_3() -> void:
	# Stage 3: Iron Casket – ruined town with ground turrets, then boss
	var rect := get_viewport().get_visible_rect()

	# Wave 1: Kamikaze Striker Rush (00:20 timing)
	print("Stage 3: Kamikaze strike wave incoming...")
	for i in range(8):
		var x_pos = randf() * rect.size.x  # Random across top edge
		_spawn_pattern_enemy(TYPE12, Vector2(x_pos, -50))
		await get_tree().create_timer(0.3, false).timeout
	await get_tree().create_timer(3.0, false).timeout

	# Wave 2: Mixed assault with remaining chasers and bombers
	print("Stage 3: Combined assault wave...")
	_spawn_single_from_side(TYPE07, "left")   # Chaser Drone
	await get_tree().create_timer(1.5, false).timeout
	_spawn_single_from_side(TYPE08, "right")  # Heavy Bomber
	await get_tree().create_timer(2.0, false).timeout

	# Wave 3: Dual interceptor sweep
	_spawn_dual_from_sides(TYPE09, TYPE07)  # Weaving Interceptor + Chaser
	await get_tree().create_timer(2.5, false).timeout

	# Wave 4: Quick mixed barrage
	_spawn_single_from_side(TYPE09, "left", -30)  # Weaving Interceptor
	await get_tree().create_timer(0.7, false).timeout
	_spawn_single_from_side(TYPE10, "right", 30)  # Diving Assault
	await get_tree().create_timer(0.7, false).timeout
	_spawn_single_from_side(TYPE08, "left", 0)    # Heavy Bomber
	await get_tree().create_timer(2.0, false).timeout

	# Wave 5: Formation Leader with Escorts (01:45 timing)
	print("Stage 3: Enemy formation leader detected...")
	# Spawn the formation leader with escort fighters
	_spawn_pattern_enemy(TYPE13, Vector2(rect.size.x * 0.5, -50))  # Formation Leader
	await get_tree().create_timer(0.5, false).timeout
	# Spawn escorts in V-formation
	for i in range(4):
		var angle = (i - 1.5) * 0.5  # Spread the escorts
		var x_offset = sin(angle) * 80
		var y_offset = abs(cos(angle)) * 30
		_spawn_pattern_enemy(TYPE07, Vector2(rect.size.x * 0.5 + x_offset, -50 + y_offset))
		await get_tree().create_timer(0.2, false).timeout
	await get_tree().create_timer(4.0, false).timeout

	# Wave 6: Final mixed assault
	_spawn_dual_from_sides(TYPE09, TYPE08)  # Interceptor + Bomber
	await get_tree().create_timer(1.5, false).timeout
	_spawn_small_group(2, TYPE10, rect.size.x * 0.5)  # Diving Assault pair
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
		emit_signal("boss_defeated")


func _run_stage_4() -> void:
	# Stage 4: Super Carrier – ocean with subs/destroyers then Graf Zeppelin
	var rect := get_viewport().get_visible_rect()

	# Opening: Single sweeper from each side
	_spawn_single_from_side(TYPE08, "left")
	await get_tree().create_timer(1.8, false).timeout
	_spawn_single_from_side(TYPE08, "right")
	await get_tree().create_timer(2.0, false).timeout

	# Wave 1: Dual rotating ring types
	_spawn_dual_from_sides(TYPE08, TYPE10)
	await get_tree().create_timer(2.5, false).timeout

	# Wave 2: Quick succession patterns
	_spawn_single_from_side(TYPE08, "left", 25)
	await get_tree().create_timer(1.0, false).timeout
	_spawn_single_from_side(TYPE08, "right", -25)
	await get_tree().create_timer(1.0, false).timeout
	_spawn_single_from_side(TYPE10, "left", 0)
	await get_tree().create_timer(2.0, false).timeout

	# Wave 3: Triple formation
	_spawn_triple_staggered([TYPE08, TYPE08, TYPE10])
	await get_tree().create_timer(2.5, false).timeout

	# Wave 4: Mixed patterns
	_spawn_dual_from_sides(TYPE10, TYPE08)
	await get_tree().create_timer(1.8, false).timeout
	_spawn_small_group(2, TYPE08, rect.size.x * 0.5)
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
		emit_signal("boss_defeated")


func _run_stage_5() -> void:
	# Stage 5: Fortress – turreted buildings around narrow bridges
	var rect := get_viewport().get_visible_rect()

	# Opening: Single fortress turret from each side
	_spawn_single_from_side(TYPE09, "left")
	await get_tree().create_timer(1.6, false).timeout
	_spawn_single_from_side(TYPE09, "right")
	await get_tree().create_timer(2.0, false).timeout

	# Wave 1: Dual beam turrets
	_spawn_dual_from_sides(TYPE09, TYPE09)
	await get_tree().create_timer(2.2, false).timeout

	# Wave 2: Quick beam barrage
	_spawn_single_from_side(TYPE09, "left", -25)
	await get_tree().create_timer(0.9, false).timeout
	_spawn_single_from_side(TYPE09, "right", 25)
	await get_tree().create_timer(0.9, false).timeout
	_spawn_single_from_side(TYPE09, "left", 0)
	await get_tree().create_timer(2.0, false).timeout

	# Wave 3: Triple fortress pattern
	_spawn_triple_staggered([TYPE09, TYPE09, TYPE09])
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
		emit_signal("boss_defeated")


func _run_stage_6() -> void:
	# Stage 6: Dam valley – towers and missiles, then crab robot
	var rect := get_viewport().get_visible_rect()

	# Opening: Single laser tower from each side
	_spawn_single_from_side(TYPE13, "left")
	await get_tree().create_timer(1.4, false).timeout
	_spawn_single_from_side(TYPE13, "right")
	await get_tree().create_timer(1.8, false).timeout

	# Wave 1: Dual rotating sweepers
	_spawn_dual_from_sides(TYPE08, TYPE13)
	await get_tree().create_timer(2.2, false).timeout

	# Wave 2: Quick succession
	_spawn_single_from_side(TYPE08, "left", 20)
	await get_tree().create_timer(0.8, false).timeout
	_spawn_single_from_side(TYPE13, "right", -20)
	await get_tree().create_timer(0.8, false).timeout
	_spawn_single_from_side(TYPE08, "left", 0)
	await get_tree().create_timer(2.0, false).timeout

	# Wave 3: Triple pattern
	_spawn_triple_staggered([TYPE13, TYPE08, TYPE13])
	await get_tree().create_timer(2.5, false).timeout

	# Wave 4: Mixed waves
	_spawn_dual_from_sides(TYPE08, TYPE13)
	await get_tree().create_timer(1.8, false).timeout
	_spawn_small_group(2, TYPE08, rect.size.x * 0.5)
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
		emit_signal("boss_defeated")


func _run_stage_7() -> void:
	# Stage 7: Block-Ade – industrial machines, then mech
	var rect := get_viewport().get_visible_rect()

	# Opening: Alternating single spawns
	_spawn_single_from_side(TYPE03, "left")
	await get_tree().create_timer(1.2, false).timeout
	_spawn_single_from_side(TYPE11, "right")
	await get_tree().create_timer(1.8, false).timeout

	# Wave 1: Dual diagonal types
	_spawn_dual_from_sides(TYPE04, TYPE05)
	await get_tree().create_timer(2.0, false).timeout

	# Wave 2: Quick industrial barrage
	_spawn_single_from_side(TYPE03, "left", -25)
	await get_tree().create_timer(0.7, false).timeout
	_spawn_single_from_side(TYPE11, "right", 25)
	await get_tree().create_timer(0.7, false).timeout
	_spawn_single_from_side(TYPE04, "left", 0)
	await get_tree().create_timer(1.5, false).timeout

	# Wave 3: Triple industrial pattern
	_spawn_triple_staggered([TYPE05, TYPE03, TYPE11])
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
	_spawn_single_from_side(TYPE08, "right")
	await get_tree().create_timer(1.8, false).timeout

	# Wave 1: Mixed dual spawns
	_spawn_dual_from_sides(TYPE09, TYPE13)
	await get_tree().create_timer(2.0, false).timeout

	# Wave 2: Quick final barrage
	_spawn_single_from_side(TYPE09, "left", -30)
	await get_tree().create_timer(0.8, false).timeout
	_spawn_single_from_side(TYPE11, "right", 30)
	await get_tree().create_timer(0.8, false).timeout
	_spawn_single_from_side(TYPE04, "left", 0)
	await get_tree().create_timer(1.5, false).timeout

	# Wave 3: Triple final pattern
	_spawn_triple_staggered([TYPE08, TYPE08, TYPE09])
	await get_tree().create_timer(2.5, false).timeout

	# Wave 4: Intense mixed waves
	_spawn_dual_from_sides(TYPE13, TYPE09)
	await get_tree().create_timer(1.5, false).timeout
	_spawn_small_group(3, TYPE11, rect.size.x * 0.5, 50)
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
		emit_signal("boss_defeated")

	# Post-mid-boss waves
	_spawn_dual_from_sides(TYPE10, TYPE10)
	await get_tree().create_timer(2.0, false).timeout
	_spawn_triple_staggered([TYPE11, TYPE12, TYPE12])
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
		emit_signal("boss_defeated")
