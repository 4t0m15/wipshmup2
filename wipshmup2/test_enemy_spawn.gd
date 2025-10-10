extends Node

# Quick test to verify enemy spawning works

func _ready():
	print("=== ENEMY SPAWN TEST ===")
	
	# Test 1: Check if EnemyTemplateManager is loaded
	var etm = get_node_or_null("/root/EnemyTemplateManager")
	if etm:
		print("✓ EnemyTemplateManager loaded")
	else:
		print("✗ EnemyTemplateManager NOT loaded")
		return
	
	# Test 2: Check if templates are registered
	var templates = etm.get_all_template_names()
	print("✓ Found ", templates.size(), " enemy templates: ", templates)
	
	# Test 3: Try creating an enemy
	var enemy = etm.create_enemy("basic_fighter", Vector2(160, 100))
	if enemy:
		print("✓ Successfully created basic_fighter enemy")
		add_child(enemy)
		print("✓ Enemy added to scene")
	else:
		print("✗ Failed to create basic_fighter enemy")
	
	print("=== TEST COMPLETE ===")

