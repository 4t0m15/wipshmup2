using Godot;
using Godot.Collections;

// Item drop system
public partial class ItemDropManager : Node
{
	[Signal] public delegate void ItemCollectedEventHandler(string itemType, int value);

	public enum ItemType
	{
		POWER_UP,
		SCORE_SMALL,
		SCORE_LARGE,
		LIFE_EXTEND,
		BOMB,
		SHIELD
	}

	// Drop rates
	private Dictionary _dropRates = new Dictionary
	{
		{ ItemType.POWER_UP, 0.15f },
		{ ItemType.SCORE_SMALL, 0.3f },
		{ ItemType.SCORE_LARGE, 0.05f },
		{ ItemType.LIFE_EXTEND, 0.01f },
		{ ItemType.BOMB, 0.08f },
		{ ItemType.SHIELD, 0.02f }
	};

	private RandomNumberGenerator _rng = new RandomNumberGenerator();

	// Config
	[Export] public bool AutoEmitOnSpawn { get; set; } = true;
	[Export] public float SimulatePickupDelay { get; set; } = 0.0f;  // If > 0, emit after a delay to simulate collection timing
	
	[Export]
	public Dictionary ScoreValues { get; set; } = new Dictionary
	{
		{ ItemType.SCORE_SMALL, 100 },
		{ ItemType.SCORE_LARGE, 500 },
		{ ItemType.POWER_UP, 0 },
		{ ItemType.LIFE_EXTEND, 0 },
		{ ItemType.BOMB, 0 },
		{ ItemType.SHIELD, 0 }
	};

	public override void _Ready()
	{
		_rng.Randomize();
		AddToGroup("item_drop_manager");
	}

	// Public API

	public void TryDropItem(Vector2 position, int enemyPoints = 100, string enemyType = "")
	{
		// Cho Ren Sha 68K: triangle items
		float dropChance = CalculateDropChance(enemyPoints);
		GD.Print($"[ItemDropManager] Trying to drop item at {position} with {dropChance * 100}% chance");
		float roll = _rng.Randf();
		GD.Print($"[ItemDropManager] Roll: {roll} vs chance: {dropChance}");
		if (roll <= dropChance)
		{
			// Spawn triangle item instead of individual items
			GD.Print("[ItemDropManager] Drop successful! Spawning triangle item");
			SpawnTriangleItem(position);
			return;
		}
		else
		{
			GD.Print("[ItemDropManager] Drop failed - no item spawned");
		}

		// Legacy individual item spawning (kept for backward compatibility)
		// Only used if triangle spawning is disabled or for special cases
		if (enemyType == "legacy_individual")
		{
			ItemType itemType = SelectItemType();
			SpawnItem(itemType, position);
		}
	}

	public void ForceDropItem(ItemType itemType, Vector2 position)
	{
		// Cho Ren Sha 68K: Force drop triangle items instead of individual items
		SpawnTriangleItem(position);
	}

	public float GetDropRate(ItemType itemType)
	{
		return (float)_dropRates.Get(itemType, 0.0f);
	}

	public void SetDropRate(ItemType itemType, float rate)
	{
		_dropRates[itemType] = Mathf.Clamp(rate, 0.0f, 1.0f);
	}

	// Legacy / compatibility placeholders
	public void DropItem(Vector2 enemyPosition, string itemType = "powerup")
	{
		// Intentionally left as a no-op for legacy calls
	}

	public float GetDropChance(string enemyType)
	{
		return 0.1f;
	}

	// Internal logic ---------------------------------------------------

	private float CalculateDropChance(int enemyPoints)
	{
		float baseChance = 0.8f;  // Increased from 0.2 to 0.8 for testing
		float pointMultiplier = Mathf.Min(enemyPoints / 1000.0f, 2.0f);
		return baseChance * pointMultiplier;
	}

	private ItemType SelectItemType()
	{
		float totalWeight = 0.0f;
		foreach (Variant rate in _dropRates.Values)
		{
			totalWeight += (float)rate;
		}
		if (totalWeight <= 0.0f)
		{
			return ItemType.SCORE_SMALL;
		}
		float roll = _rng.Randf() * totalWeight;
		float currentWeight = 0.0f;
		foreach (ItemType itemType in _dropRates.Keys)
		{
			currentWeight += (float)_dropRates[itemType];
			if (roll <= currentWeight)
			{
				return itemType;
			}
		}
		return ItemType.SCORE_SMALL;  // Fallback
	}

	private void SpawnItem(ItemType itemType, Vector2 position)
	{
		// Integrate with actual scene instancing or object pooling in future
		GD.Print($"Spawn item: {itemType} at {position}");
		if (AutoEmitOnSpawn && SimulatePickupDelay <= 0.0f)
		{
			EmitCollected(itemType);
		}
		else if (AutoEmitOnSpawn && SimulatePickupDelay > 0.0f)
		{
			CallDeferred(nameof(DeferredEmitCollected), itemType); // simple delayed pickup simulation
		}
	}

	private async void DeferredEmitCollected(ItemType itemType)
	{
		await ToSignal(GetTree().CreateTimer(SimulatePickupDelay), "timeout");
		EmitCollected(itemType);
	}

	private void EmitCollected(ItemType itemType)
	{
		int value = (int)ScoreValues.Get(itemType, 0);
		EmitSignal(SignalName.ItemCollected, itemType.ToString(), value);
	}

	// Triangle Item System (Cho Ren Sha 68K)
	public void SpawnTriangleItem(Vector2 position)
	{
		// Spawn a triangle item with three pickups
		GD.Print($"[ItemDropManager] spawn_triangle_item called at position: {position}");
		var triangleScene = GD.Load<PackedScene>("res://scenes/items/TriangleItem.tscn");

		if (triangleScene == null)
		{
			GD.PushError("TriangleItem scene not found");
			return;
		}

		var triangle = triangleScene.Instantiate();
		if (triangle == null)
		{
			GD.PushError("Failed to instantiate TriangleItem");
			return;
		}

		GD.Print("[ItemDropManager] Triangle item instantiated successfully");

		// Add to scene tree using deferred call to avoid query flushing issues
		var mainScene = GetTree().CurrentScene;
		if (mainScene != null)
		{
			// Set position first, then add to scene using deferred call
			if (triangle is Node2D node2D)
			{
				node2D.GlobalPosition = position;
			}
			CallDeferred(nameof(AddTriangleToScene), triangle, mainScene);
			GD.Print($"[ItemDropManager] Spawned triangle item at {position}");
		}
		else
		{
			GD.PushError("No current scene to add triangle item");
			triangle.QueueFree();
		}
	}

	private void AddTriangleToScene(Node triangle, Node parent)
	{
		// Helper function to add triangle to scene using deferred call
		if (GodotObject.IsInstanceValid(triangle) && GodotObject.IsInstanceValid(parent))
		{
			parent.AddChild(triangle);
		}
	}

	// Test method for triangle items (can be called from debug)
	public void TestSpawnTriangle()
	{
		// Test method to spawn a triangle item at center screen
		GD.Print("[ItemDropManager] TEST: Force spawning triangle item");
		SpawnTriangleItem(new Vector2(160, 100));
	}

	public void ForceSpawnTriangleAtPlayer()
	{
		// Force spawn triangle item at player position for testing
		var gameState = GetNodeOrNull("/root/GameState");
		if (gameState != null)
		{
			var playerPos = gameState.Get("player_position").As<Vector2>();
			GD.Print($"[ItemDropManager] TEST: Force spawning triangle at player position: {playerPos}");
			SpawnTriangleItem(playerPos);
		}
	}

	// Test method for red carrier enemy (can be called from debug)
	public void TestSpawnRedCarrier()
	{
		// Test method to spawn a red carrier enemy that drops triangle items
		// Create a simple test enemy with red_carrier type
		var testEnemyScene = GD.Load<PackedScene>("res://scenes/enemy/Enemy.tscn");
		if (testEnemyScene != null)
		{
			var testEnemy = testEnemyScene.Instantiate();
			if (testEnemy != null)
			{
				testEnemy.Set("enemy_type", "red_carrier");
				if (testEnemy is Node2D node2D)
				{
					node2D.GlobalPosition = new Vector2(160, 50);
				}
				GetTree().CurrentScene.AddChild(testEnemy);
				GD.Print("[ItemDropManager] Spawned test red carrier enemy");
			}
		}
	}
}

