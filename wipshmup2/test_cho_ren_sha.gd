extends Node

# Test script for Cho Ren Sha 68K mechanics
# This script can be attached to any scene to test the implementation

func _ready() -> void:
	print("=== Cho Ren Sha 68K Test Suite ===")
	
	# Test 1: GameState initialization
	test_gamestate_initialization()
	
	# Test 2: Shield system
	test_shield_system()
	
	# Test 3: Weapon power system
	test_weapon_power_system()
	
	# Test 4: Loop system
	test_loop_system()
	
	# Test 5: Score extends
	test_score_extends()
	
	# Test 6: Triangle item spawning
	test_triangle_items()
	
	print("=== All tests completed ===")

func test_gamestate_initialization() -> void:
	print("[TEST] GameState initialization...")
	
	# Check if GameState has the new Cho Ren Sha variables
	assert(GameState.has_method("has_shield"), "GameState missing has_shield method")
	assert(GameState.has_method("set_shield"), "GameState missing set_shield method")
	assert(GameState.has_method("consume_shield"), "GameState missing consume_shield method")
	assert(GameState.has_method("add_weapon_power"), "GameState missing add_weapon_power method")
	assert(GameState.has_method("reset_weapon_power"), "GameState missing reset_weapon_power method")
	assert(GameState.has_method("increment_loop"), "GameState missing increment_loop method")
	
	print("✓ GameState initialization test passed")

func test_shield_system() -> void:
	print("[TEST] Shield system...")
	
	# Test shield state
	assert(GameState.has_shield == false, "Shield should start as false")
	
	# Test setting shield
	GameState.set_shield(true)
	assert(GameState.has_shield == true, "Shield should be true after setting")
	
	# Test consuming shield
	var consumed = GameState.consume_shield()
	assert(consumed == true, "Shield should be consumed")
	assert(GameState.has_shield == false, "Shield should be false after consumption")
	
	# Test consuming when no shield
	consumed = GameState.consume_shield()
	assert(consumed == false, "No shield should be consumed when shield is false")
	
	print("✓ Shield system test passed")

func test_weapon_power_system() -> void:
	print("[TEST] Weapon power system...")
	
	# Test initial power level
	assert(GameState.weapon_power == 1, "Weapon power should start at 1")
	
	# Test adding power
	GameState.add_weapon_power(2)
	assert(GameState.weapon_power == 3, "Weapon power should be 3 after adding 2")
	
	# Test power cap (max 8)
	GameState.add_weapon_power(10)
	assert(GameState.weapon_power == 8, "Weapon power should be capped at 8")
	
	# Test reset
	GameState.reset_weapon_power()
	assert(GameState.weapon_power == 1, "Weapon power should reset to 1")
	
	print("✓ Weapon power system test passed")

func test_loop_system() -> void:
	print("[TEST] Loop system...")
	
	# Test initial loop
	assert(GameState.current_loop == 1, "Loop should start at 1")
	
	# Test incrementing loop
	GameState.increment_loop()
	assert(GameState.current_loop == 2, "Loop should be 2 after increment")
	
	GameState.increment_loop()
	assert(GameState.current_loop == 3, "Loop should be 3 after another increment")
	
	print("✓ Loop system test passed")

func test_score_extends() -> void:
	print("[TEST] Score extends...")
	
	# Test initial extend score
	assert(GameState.last_extend_score == 0, "Last extend score should start at 0")
	
	# Test adding score that should trigger extend
	var initial_lives = GameState.lives
	GameState.add_score(1000000)  # 1 million points
	assert(GameState.lives > initial_lives, "Lives should increase after 1M points")
	assert(GameState.last_extend_score == 1000000, "Last extend score should be updated")
	
	print("✓ Score extends test passed")

func test_triangle_items() -> void:
	print("[TEST] Triangle item system...")
	
	# Test ItemDropManager has triangle spawn method
	var item_drop_manager = get_node_or_null("/root/ItemDropManager")
	assert(item_drop_manager != null, "ItemDropManager should exist")
	assert(item_drop_manager.has_method("spawn_triangle_item"), "ItemDropManager should have spawn_triangle_item method")
	assert(item_drop_manager.has_method("test_spawn_triangle"), "ItemDropManager should have test_spawn_triangle method")
	
	# Test triangle item scene exists
	var triangle_scene = preload("res://scenes/items/TriangleItem.tscn")
	assert(triangle_scene != null, "TriangleItem scene should exist")
	
	print("✓ Triangle item system test passed")

func test_eventbus_signals() -> void:
	print("[TEST] EventBus signals...")
	
	# Test that EventBus has the new Cho Ren Sha signals
	assert(EventBus.has_signal("shield_gained"), "EventBus should have shield_gained signal")
	assert(EventBus.has_signal("shield_lost"), "EventBus should have shield_lost signal")
	assert(EventBus.has_signal("shield_absorbed"), "EventBus should have shield_absorbed signal")
	assert(EventBus.has_signal("weapon_power_changed"), "EventBus should have weapon_power_changed signal")
	assert(EventBus.has_signal("loop_incremented"), "EventBus should have loop_incremented signal")
	assert(EventBus.has_signal("life_extended"), "EventBus should have life_extended signal")
	
	print("✓ EventBus signals test passed")

func test_hud_displays() -> void:
	print("[TEST] HUD displays...")
	
	# Test that HUD has the new display methods
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		assert(hud.has_method("set_shield"), "HUD should have set_shield method")
		assert(hud.has_method("set_weapon_power"), "HUD should have set_weapon_power method")
		assert(hud.has_method("set_loop"), "HUD should have set_loop method")
		print("✓ HUD displays test passed")
	else:
		print("⚠ HUD not found, skipping HUD test")

func _input(event: InputEvent) -> void:
	# Debug key bindings for testing
	if event.is_action_pressed("ui_accept"):
		print("=== Manual Test Triggers ===")
		print("Press 1: Test shield system")
		print("Press 2: Test weapon power")
		print("Press 3: Test triangle item spawn")
		print("Press 4: Test red carrier enemy")
	
	if event.is_action_pressed("ui_select"):
		# Test shield toggle
		GameState.set_shield(!GameState.has_shield)
		print("Shield toggled: ", GameState.has_shield)
	
	if event.is_action_pressed("ui_cancel"):
		# Test weapon power increase
		GameState.add_weapon_power(1)
		print("Weapon power increased to: ", GameState.weapon_power)
	
	if event.is_action_pressed("ui_up"):
		# Test triangle item spawn
		var item_drop_manager = get_node_or_null("/root/ItemDropManager")
		if item_drop_manager:
			item_drop_manager.test_spawn_triangle()
			print("Triangle item spawned")
	
	if event.is_action_pressed("ui_down"):
		# Test red carrier enemy spawn
		var item_drop_manager = get_node_or_null("/root/ItemDropManager")
		if item_drop_manager:
			item_drop_manager.test_spawn_red_carrier()
			print("Red carrier enemy spawned")
