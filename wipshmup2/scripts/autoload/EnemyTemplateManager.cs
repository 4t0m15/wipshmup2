using Godot;
using Godot.Collections;
using System.Linq;

public partial class EnemyTemplateManager : Node
{
	// EnemyTemplateManager - Manages enemy templates and creation
	// Provides easy access to enemy templates by name

	private Dictionary<string, EnemyTemplate> _templates = new();

	public override void _Ready()
	{
		GD.Print("[EnemyTemplateManager] Initializing enemy templates");
		RegisterDefaultTemplates();
	}

	private void RegisterDefaultTemplates()
	{
		// Register default enemy templates

		// Basic enemy types
		RegisterTemplate("basic_fighter", new Dictionary
		{
			{ "type_name", "basic_fighter" },
			{ "hp", 1 },
			{ "points", 100 },
			{ "speed", 50.0f },
			{ "movement_behavior", "StraightDown" },
			{ "attack_behavior", "AimedShot" },
			{ "movement_params", new Dictionary
				{
					{ "speed", 50.0f }
				}
			},
			{ "attack_params", new Dictionary
				{
					{ "fire_rate", 1.0f },
					{ "bullet_speed", 140.0f }
				}
			}
		});

		RegisterTemplate("sine_fighter", new Dictionary
		{
			{ "type_name", "sine_fighter" },
			{ "hp", 1 },
			{ "points", 150 },
			{ "speed", 40.0f },
			{ "movement_behavior", "SineWave" },
			{ "attack_behavior", "Fan" },
			{ "movement_params", new Dictionary
				{
					{ "speed", 40.0f },
					{ "amplitude", 30.0f },
					{ "frequency", 1.0f }
				}
			},
			{ "attack_params", new Dictionary
				{
					{ "fire_rate", 0.8f },
					{ "fan_angle", 30.0f },
					{ "bullet_count", 3 }
				}
			}
		});

		RegisterTemplate("zigzag_fighter", new Dictionary
		{
			{ "type_name", "zigzag_fighter" },
			{ "hp", 1 },
			{ "points", 120 },
			{ "speed", 45.0f },
			{ "movement_behavior", "Zigzag" },
			{ "attack_behavior", "AimedShot" },
			{ "movement_params", new Dictionary
				{
					{ "speed", 45.0f },
					{ "zigzag_amplitude", 25.0f },
					{ "zigzag_frequency", 2.0f }
				}
			},
			{ "attack_params", new Dictionary
				{
					{ "fire_rate", 1.2f },
					{ "aim_lead", 0.3f }
				}
			}
		});

		RegisterTemplate("dive_bomber", new Dictionary
		{
			{ "type_name", "dive_bomber" },
			{ "hp", 2 },
			{ "points", 200 },
			{ "speed", 60.0f },
			{ "movement_behavior", "Dive" },
			{ "attack_behavior", "Ring" },
			{ "movement_params", new Dictionary
				{
					{ "speed", 60.0f },
					{ "dive_speed_multiplier", 1.5f },
					{ "level_out_distance", 80.0f }
				}
			},
			{ "attack_params", new Dictionary
				{
					{ "fire_rate", 0.6f },
					{ "bullet_count", 6 },
					{ "ring_rotation_speed", 45.0f }
				}
			}
		});

		RegisterTemplate("heavy_bomber", new Dictionary
		{
			{ "type_name", "heavy_bomber" },
			{ "hp", 3 },
			{ "points", 300 },
			{ "speed", 35.0f },
			{ "movement_behavior", "StraightDown" },
			{ "attack_behavior", "Fan" },
			{ "movement_params", new Dictionary
				{
					{ "speed", 35.0f }
				}
			},
			{ "attack_params", new Dictionary
				{
					{ "fire_rate", 0.4f },
					{ "fan_angle", 60.0f },
					{ "bullet_count", 5 },
					{ "bullet_speed", 120.0f }
				}
			}
		});

		GD.Print($"[EnemyTemplateManager] Registered {_templates.Count} enemy templates");
	}

	private void RegisterTemplate(string templateName, Dictionary templateData)
	{
		// Register a new enemy template
		var template = new EnemyTemplate();

		// Set basic properties
		template.TypeName = templateData.GetValueOrDefault("type_name", templateName).ToString();
		template.Hp = (int)templateData.GetValueOrDefault("hp", 1);
		template.Points = (int)templateData.GetValueOrDefault("points", 100);
		template.Speed = (float)templateData.GetValueOrDefault("speed", 50.0f);
		template.SpriteKey = templateData.GetValueOrDefault("sprite_key", "enemy").ToString();

		// Set behaviors
		template.MovementBehavior = templateData.GetValueOrDefault("movement_behavior", "StraightDown").ToString();
		template.AttackBehavior = templateData.GetValueOrDefault("attack_behavior", "AimedShot").ToString();

		// Set parameters
		template.MovementParams = (Dictionary)templateData.GetValueOrDefault("movement_params", new Dictionary());
		template.AttackParams = (Dictionary)templateData.GetValueOrDefault("attack_params", new Dictionary());

		// Set visual properties
		template.SpriteScale = (float)templateData.GetValueOrDefault("sprite_scale", 1.0f);
		template.GlowColor = (Color)templateData.GetValueOrDefault("glow_color", Colors.White);
		template.DangerLevel = (int)templateData.GetValueOrDefault("danger_level", 1);

		// Set collision properties
		template.CollisionRadius = (float)templateData.GetValueOrDefault("collision_radius", 8.0f);
		template.CollisionLayer = (int)templateData.GetValueOrDefault("collision_layer", 1);
		template.CollisionMask = (int)templateData.GetValueOrDefault("collision_mask", 1);

		// Set special properties
		template.IgnoreShotDamage = (bool)templateData.GetValueOrDefault("ignore_shot_damage", false);
		template.IgnoreBombDamage = (bool)templateData.GetValueOrDefault("ignore_bomb_damage", false);
		template.BombPointsOverride = (int)templateData.GetValueOrDefault("bomb_points_override", -1);
		template.BombPointsMultiplier = (float)templateData.GetValueOrDefault("bomb_points_multiplier", 10.0f);

		_templates[templateName] = template;
	}

	public EnemyTemplate GetTemplate(string templateName)
	{
		// Get an enemy template by name
		return _templates.GetValueOrDefault(templateName, null);
	}

	public Node CreateEnemy(string templateName, Vector2 position)
	{
		// Create an enemy from a template
		var template = GetTemplate(templateName);
		if (template == null)
		{
			GD.PushError($"Enemy template not found: {templateName}");
			return null;
		}

		var enemy = template.CreateEnemyInstance();
		enemy.Set("global_position", position);

		return enemy;
	}

	public string[] GetAllTemplateNames()
	{
		// Get all registered template names
		return _templates.Keys.ToArray();
	}

	public bool HasTemplate(string templateName)
	{
		// Check if a template exists
		return _templates.ContainsKey(templateName);
	}

	// Convenience methods for common enemy types
	public Node CreateBasicFighter(Vector2 position)
	{
		return CreateEnemy("basic_fighter", position);
	}

	public Node CreateSineFighter(Vector2 position)
	{
		return CreateEnemy("sine_fighter", position);
	}

	public Node CreateZigzagFighter(Vector2 position)
	{
		return CreateEnemy("zigzag_fighter", position);
	}

	public Node CreateDiveBomber(Vector2 position)
	{
		return CreateEnemy("dive_bomber", position);
	}

	public Node CreateHeavyBomber(Vector2 position)
	{
		return CreateEnemy("heavy_bomber", position);
	}
}

