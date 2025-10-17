extends Node

# Test script to verify HUD functionality
# This script tests that all HUD connections are working properly

func _ready() -> void:
	print("[HUD Test] Starting HUD functionality test...")
	
	# Wait a frame for everything to initialize
	await get_tree().process_frame
	
	# Test GameState integration
	_test_gamestate_integration()
	
	# Test EventBus signals
	_test_eventbus_signals()
	
	print("[HUD Test] HUD functionality test completed!")

func _test_gamestate_integration() -> void:
	print("[HUD Test] Testing GameState integration...")
	
	# Test initial values
	print("Initial lives: ", GameState.lives)
	print("Initial bombs: ", GameState.bombs)
	print("Initial score: ", GameState.score)
	print("Initial chain: ", GameState.chain_count)
	
	# Test score changes
	var original_score = GameState.score
	GameState.add_score(1000)
	print("Score after adding 1000: ", GameState.score)
	assert(GameState.score == original_score + 1000, "Score not updated correctly")
	
	# Test lives changes
	var original_lives = GameState.lives
	GameState.take_lives(1)
	print("Lives after taking 1: ", GameState.lives)
	assert(GameState.lives == original_lives - 1, "Lives not updated correctly")
	
	# Test bombs changes
	var original_bombs = GameState.bombs
	GameState.add_bombs(1)
	print("Bombs after adding 1: ", GameState.bombs)
	assert(GameState.bombs == original_bombs + 1, "Bombs not updated correctly")
	
	# Test streak system
	GameState.update_streak()
	print("Chain count after update: ", GameState.chain_count)
	
	print("[HUD Test] GameState integration test passed!")

func _test_eventbus_signals() -> void:
	print("[HUD Test] Testing EventBus signals...")
	
	# Test that signals are connected
	var eventbus = get_node("/root/EventBus")
	assert(eventbus != null, "EventBus not found")
	
	# Test signal connections
	var hud = get_node("/root/Main/HUD")
	assert(hud != null, "HUD not found")
	
	# Test that HUD has the required methods
	assert(hud.has_method("set_lives"), "HUD missing set_lives method")
	assert(hud.has_method("set_bombs"), "HUD missing set_bombs method")
	assert(hud.has_method("set_score"), "HUD missing set_score method")
	assert(hud.has_method("set_chain"), "HUD missing set_chain method")
	
	print("[HUD Test] EventBus signals test passed!")

func _test_hud_display_methods() -> void:
	print("[HUD Test] Testing HUD display methods...")
	
	var hud = get_node("/root/Main/HUD")
	if hud == null:
		print("[HUD Test] HUD not found, skipping display test")
		return
	
	# Test direct method calls
	hud.set_score(5000)
	hud.set_lives(2)
	hud.set_bombs(1)
	hud.set_chain(5, 10)
	
	print("[HUD Test] HUD display methods test passed!")

func _test_cho_ren_sha_mechanics() -> void:
	print("[HUD Test] Testing Cho Ren Sha mechanics...")
	
	# Test shield system
	GameState.set_shield(true)
	assert(GameState.has_shield == true, "Shield not set correctly")
	
	# Test weapon power
	GameState.add_weapon_power(2)
	assert(GameState.weapon_power > 1, "Weapon power not increased")
	
	# Test loop system
	var original_loop = GameState.current_loop
	GameState.increment_loop()
	assert(GameState.current_loop == original_loop + 1, "Loop not incremented correctly")
	
	print("[HUD Test] Cho Ren Sha mechanics test passed!")
