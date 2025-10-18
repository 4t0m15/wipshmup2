using Godot;
using Godot.Collections;

[GlobalClass]
public partial class EnemyTemplate : Resource
{
	// EnemyTemplate - Data-driven enemy definitions
	// Replaces hardcoded enemy types with configurable templates

	[Export] public string TypeName { get; set; } = "enemy";
	[Export] public int Hp { get; set; } = 1;
	[Export] public int Points { get; set; } = 100;
	[Export] public float Speed { get; set; } = 50.0f;
	[Export] public string SpriteKey { get; set; } = "enemy";

	// Behavior configuration
	[Export] public string MovementBehavior { get; set; } = "StraightDown";
	[Export] public string AttackBehavior { get; set; } = "AimedShot";

	// Movement parameters
	[Export] public Dictionary MovementParams { get; set; } = new();

	// Attack parameters
	[Export] public Dictionary AttackParams { get; set; } = new();

	// Visual parameters
	[Export] public float SpriteScale { get; set; } = 1.0f;
	[Export] public Color GlowColor { get; set; } = Colors.White;
	[Export] public int DangerLevel { get; set; } = 1;

	// Collision parameters
	[Export] public float CollisionRadius { get; set; } = 8.0f;
	[Export] public int CollisionLayer { get; set; } = 1;
	[Export] public int CollisionMask { get; set; } = 1;

	// Special properties
	[Export] public bool IgnoreShotDamage { get; set; } = false;
	[Export] public bool IgnoreBombDamage { get; set; } = false;
	[Export] public int BombPointsOverride { get; set; } = -1;
	[Export] public float BombPointsMultiplier { get; set; } = 10.0f;

	public EnemyTemplate()
	{
		// Set default movement parameters
		if (MovementParams.Count == 0)
		{
			MovementParams = new Dictionary
			{
				{ "speed", Speed },
				{ "direction", Vector2.Down }
			};
		}

		// Set default attack parameters
		if (AttackParams.Count == 0)
		{
			AttackParams = new Dictionary
			{
				{ "fire_rate", 1.0f },
				{ "bullet_speed", 140.0f },
				{ "bullet_damage", 1 }
			};
		}
	}

	public GDScript GetMovementBehaviorScene()
	{
		// Get the movement behavior scene for this template
		return MovementBehavior switch
		{
			"StraightDown" => GD.Load<GDScript>("res://scripts/components/behaviors/StraightDownBehavior.cs"),
			"SineWave" => GD.Load<GDScript>("res://scripts/components/behaviors/SineWaveBehavior.cs"),
			"Zigzag" => GD.Load<GDScript>("res://scripts/components/behaviors/ZigzagBehavior.cs"),
			"Dive" => GD.Load<GDScript>("res://scripts/components/behaviors/DiveBehavior.cs"),
			_ => GD.Load<GDScript>("res://scripts/components/behaviors/StraightDownBehavior.cs")
		};
	}

	public GDScript GetAttackBehaviorScene()
	{
		// Get the attack behavior scene for this template
		return AttackBehavior switch
		{
			"AimedShot" => GD.Load<GDScript>("res://scripts/components/behaviors/AimedShotBehavior.cs"),
			"Fan" => GD.Load<GDScript>("res://scripts/components/behaviors/FanBehavior.cs"),
			"Ring" => GD.Load<GDScript>("res://scripts/components/behaviors/RingBehavior.cs"),
			_ => GD.Load<GDScript>("res://scripts/components/behaviors/AimedShotBehavior.cs")
		};
	}

	public Node CreateEnemyInstance()
	{
		// Create an enemy instance from this template
		// Load the base enemy scene
		var enemyScene = GD.Load<PackedScene>("res://scenes/enemy/Enemy.tscn");
		var enemy = enemyScene.Instantiate();

		// Apply template properties
		enemy.Set("hp", Hp);
		enemy.Set("points", Points);
		enemy.Set("speed", Speed);
		enemy.Set("enemy_type", TypeName);
		enemy.Set("ignore_shot_damage", IgnoreShotDamage);
		enemy.Set("ignore_bomb_damage", IgnoreBombDamage);
		enemy.Set("bomb_points_override", BombPointsOverride);
		enemy.Set("bomb_points_multiplier", BombPointsMultiplier);

		// Add movement behavior
		var movementScript = GetMovementBehaviorScene();
		var movementBehaviorNode = (Node)movementScript.New();
		movementBehaviorNode.Name = "MovementBehavior";
		enemy.AddChild(movementBehaviorNode);

		// Apply movement parameters
		foreach (var key in MovementParams.Keys)
		{
			string keyStr = key.ToString();
			if (movementBehaviorNode.HasMethod($"set_{keyStr}"))
			{
				movementBehaviorNode.Call($"set_{keyStr}", MovementParams[key]);
			}
			else if (movementBehaviorNode.Get(keyStr).VariantType != Variant.Type.Nil)
			{
				movementBehaviorNode.Set(keyStr, MovementParams[key]);
			}
		}

		// Add attack behavior
		var attackScript = GetAttackBehaviorScene();
		var attackBehaviorNode = (Node)attackScript.New();
		attackBehaviorNode.Name = "AttackBehavior";
		enemy.AddChild(attackBehaviorNode);

		// Apply attack parameters
		foreach (var key in AttackParams.Keys)
		{
			string keyStr = key.ToString();
			if (attackBehaviorNode.HasMethod($"set_{keyStr}"))
			{
				attackBehaviorNode.Call($"set_{keyStr}", AttackParams[key]);
			}
			else if (attackBehaviorNode.Get(keyStr).VariantType != Variant.Type.Nil)
			{
				attackBehaviorNode.Set(keyStr, AttackParams[key]);
			}
		}

		// Setup sprite
		SetupEnemySprite(enemy);

		// Setup collision
		SetupEnemyCollision(enemy);

		return enemy;
	}

	private void SetupEnemySprite(Node enemy)
	{
		// Setup the enemy sprite from template
		if (enemy.HasNode("Sprite2D"))
		{
			var sprite = enemy.GetNode<Sprite2D>("Sprite2D");

			// Apply sprite scale
			sprite.Scale = new Vector2(SpriteScale, SpriteScale);

			// Apply glow color if needed
			if (GlowColor != Colors.White)
			{
				sprite.Modulate = GlowColor;
			}
		}
	}

	private void SetupEnemyCollision(Node enemy)
	{
		// Setup the enemy collision from template
		if (enemy.HasNode("CollisionShape2D"))
		{
			var collision = enemy.GetNode<CollisionShape2D>("CollisionShape2D");
			if (collision.Shape is CircleShape2D circleShape)
			{
				circleShape.Radius = CollisionRadius;
			}
			else if (collision.Shape is RectangleShape2D rectangleShape)
			{
				var size = new Vector2(CollisionRadius * 2, CollisionRadius * 2);
				rectangleShape.Size = size;
			}
		}

		// Set collision layers
		if (enemy is CollisionObject2D collisionObject)
		{
			collisionObject.CollisionLayer = (uint)CollisionLayer;
			collisionObject.CollisionMask = (uint)CollisionMask;
		}
	}
}

