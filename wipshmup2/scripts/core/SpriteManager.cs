using Godot;
using Godot.Collections;
using System;

// Centralized sprite scaling
public partial class SpriteManager : Node
{
	// Target sizes
	private static readonly System.Collections.Generic.Dictionary<string, float> TARGET_SIZES = new System.Collections.Generic.Dictionary<string, float>
	{
		{ "player", 18.0f },
		{ "enemy_fighter", 20.0f },
		{ "enemy_bomber", 24.0f },
		{ "enemy_turret", 22.0f },
		{ "boss", 40.0f },
		{ "bullet", 12.0f },
		{ "explosion", 32.0f },
		{ "powerup", 16.0f }
	};

	// Scale presets
	private static readonly System.Collections.Generic.Dictionary<string, Vector2> SCALE_PRESETS = new System.Collections.Generic.Dictionary<string, Vector2>
	{
		{ "player", new Vector2(1.0f, 1.0f) },  // Full size for better visibility
		{ "enemy_fighter", new Vector2(1.2f, 1.2f) },
		{ "enemy_bomber", new Vector2(1.0f, 1.0f) },
		{ "enemy_turret", new Vector2(1.0f, 1.0f) },
		{ "boss", new Vector2(0.8f, 0.8f) },
		{ "bullet", new Vector2(3.0f, 3.0f) },
		{ "explosion", new Vector2(1.0f, 1.0f) },
		{ "powerup", new Vector2(1.0f, 1.0f) }
	};

	// Color presets
	private static readonly System.Collections.Generic.Dictionary<string, Color> COLOR_PRESETS = new System.Collections.Generic.Dictionary<string, Color>
	{
		// Player: bright cyan
		{ "player", new Color(0.2f, 1.0f, 0.8f, 1.0f) },
		// Enemies by threat
		{ "enemy_fighter", new Color(1.0f, 0.3f, 0.3f, 1.0f) },  // Red - aggressive
		{ "enemy_bomber", new Color(1.0f, 0.6f, 0.2f, 1.0f) },   // Orange - medium threat
		{ "enemy_turret", new Color(1.0f, 0.8f, 0.2f, 1.0f) },   // Yellow - shooter
		{ "enemy_escort", new Color(1.0f, 0.5f, 0.8f, 1.0f) },   // Pink - support
		{ "enemy_kamikaze", new Color(1.0f, 0.2f, 0.2f, 1.0f) }, // Dark red - high threat
		{ "enemy_boss", new Color(0.8f, 0.4f, 1.0f, 1.0f) },     // Purple - boss
		// Fallbacks
		{ "default", Colors.White },
		{ "fighter", new Color(1.0f, 0.3f, 0.3f, 1.0f) },
		{ "bomber", new Color(1.0f, 0.6f, 0.2f, 1.0f) },
		{ "turret", new Color(1.0f, 0.8f, 0.2f, 1.0f) },
		{ "escort", new Color(1.0f, 0.5f, 0.8f, 1.0f) },
		{ "kamikaze", new Color(1.0f, 0.2f, 0.2f, 1.0f) },
		{ "boss", new Color(0.8f, 0.4f, 1.0f, 1.0f) }
	};

	// Health-based color tinting for damaged enemies
	private static readonly System.Collections.Generic.Dictionary<string, Color> HEALTH_COLORS = new System.Collections.Generic.Dictionary<string, Color>
	{
		{ "healthy", new Color(1.0f, 1.0f, 1.0f, 1.0f) },      // White
		{ "damaged", new Color(1.0f, 0.8f, 0.6f, 1.0f) },      // Light orange
		{ "critical", new Color(1.0f, 0.4f, 0.4f, 1.0f) },     // Red
		{ "dying", new Color(0.8f, 0.2f, 0.2f, 1.0f) }         // Dark red
	};

	public static void SetupSprite(Sprite2D sprite, string entityType, float targetHeight = -1.0f)
	{
		// Setup sprite with enhanced visual clarity
		if (sprite == null)
		{
			return;
		}

		// Apply size scaling
		if (targetHeight > 0.0f)
		{
			var scalePreset = SCALE_PRESETS.ContainsKey(entityType) ? SCALE_PRESETS[entityType] : new Vector2(1.0f, 1.0f);
			var baseScale = scalePreset;
			if (sprite.Texture != null)
			{
				var texSize = sprite.Texture.GetSize();
				if (texSize.Y > 0)
				{
					float scaleFactor = targetHeight / texSize.Y;
					sprite.Scale = baseScale * scaleFactor;
				}
			}
		}

		// Apply color modulation
		var color = COLOR_PRESETS.ContainsKey(entityType) ? COLOR_PRESETS[entityType] : COLOR_PRESETS["default"];
		sprite.Modulate = color;

		// Add subtle glow effect for better visibility
		AddGlowEffect(sprite, entityType);
	}

	public static void ApplyScaleAndColor(Sprite2D sprite, float scaleValue, Color tint)
	{
		// Apply uniform scale and optional tint to a sprite with safety guards
		if (sprite == null)
		{
			return;
		}
		// Apply scale (uniform)
		if (scaleValue > 0.0f)
		{
			sprite.Scale = new Vector2(scaleValue, scaleValue);
		}
		// Apply tint only if not default white to avoid redundant modulates
		if (tint != Colors.White)
		{
			sprite.Modulate = tint;
		}
	}

	private static void AddGlowEffect(Sprite2D sprite, string entityType)
	{
		// Add subtle glow effect for better visibility
		// This would be implemented with a glow shader or duplicate sprite
		// For now, we'll enhance the base color
		var baseColor = sprite.Modulate;
		float glowIntensity = 0.1f;

		// Increase brightness slightly for better visibility
		sprite.Modulate = new Color(
			Math.Min(1.0f, baseColor.R + glowIntensity),
			Math.Min(1.0f, baseColor.G + glowIntensity),
			Math.Min(1.0f, baseColor.B + glowIntensity),
			baseColor.A
		);
	}

	public static void ApplyHealthTint(Sprite2D sprite, float healthRatio)
	{
		// Apply health-based color tinting to enemy sprites
		if (sprite == null)
		{
			return;
		}

		Color healthColor;
		if (healthRatio > 0.7f)
		{
			healthColor = HEALTH_COLORS["healthy"];
		}
		else if (healthRatio > 0.3f)
		{
			healthColor = HEALTH_COLORS["damaged"];
		}
		else if (healthRatio > 0.1f)
		{
			healthColor = HEALTH_COLORS["critical"];
		}
		else
		{
			healthColor = HEALTH_COLORS["dying"];
		}

		// Blend with original color
		var originalColor = sprite.Modulate;
		sprite.Modulate = new Color(
			(originalColor.R + healthColor.R) * 0.5f,
			(originalColor.G + healthColor.G) * 0.5f,
			(originalColor.B + healthColor.B) * 0.5f,
			originalColor.A
		);
	}

	public static void SetupSpriteLegacy(Sprite2D sprite, string entityType, float targetHeight = -1.0f)
	{
		// Setup a sprite with proper scaling and color based on entity type
		if (sprite == null || sprite.Texture == null)
		{
			GD.PushWarning("SpriteManager: Invalid sprite or missing texture");
			return;
		}

		// Check if sprite already has a reasonable scale set (from scene file)
		var currentScale = sprite.Scale;
		bool isAlreadyScaled = currentScale.X > 0.5f && currentScale.Y > 0.5f;

		// Only apply scaling if the sprite is at default scale (1,1) or very small
		if (!isAlreadyScaled)
		{
			// SPECIAL CASE: Don't aggressively auto-scale player; keep readable size.
			// The player texture can be large which made auto height-scaling shrink it to ~sub‑pixel size
			// after post-processing. Use the explicit preset scale for the player.
			if (entityType == "player")
			{
				sprite.Scale = SCALE_PRESETS.ContainsKey("player") ? SCALE_PRESETS["player"] : new Vector2(1.0f, 1.0f);
			}
			else
			{
				// Use provided target height or get from presets
				float height = targetHeight > 0 ? targetHeight : (TARGET_SIZES.ContainsKey(entityType) ? TARGET_SIZES[entityType] : 20.0f);
				// Calculate scale based on texture size
				var texSize = sprite.Texture.GetSize();
				if (texSize.Y > 0)
				{
					float scaleFactor = height / texSize.Y;
					// If computed scale would be too tiny, fall back to preset to keep visibility
					if (scaleFactor < 0.25f)
					{
						GD.PushWarning($"SpriteManager: Computed scale ({scaleFactor}) too small for {entityType}, using preset");
						sprite.Scale = SCALE_PRESETS.ContainsKey(entityType) ? SCALE_PRESETS[entityType] : new Vector2(1.0f, 1.0f);
					}
					else
					{
						sprite.Scale = new Vector2(scaleFactor, scaleFactor);
					}
				}
				else
				{
					// Fallback to preset scale
					sprite.Scale = SCALE_PRESETS.ContainsKey(entityType) ? SCALE_PRESETS[entityType] : new Vector2(1.0f, 1.0f);
				}
			}
		}
		else
		{
			// Sprite already has a good scale, just ensure it's not too small
			if (currentScale.X < 0.1f || currentScale.Y < 0.1f)
			{
				sprite.Scale = SCALE_PRESETS.ContainsKey(entityType) ? SCALE_PRESETS[entityType] : new Vector2(1.0f, 1.0f);
			}
		}

		// Apply color modulation (normalize keys like enemy_*)
		string key = entityType;
		if (!COLOR_PRESETS.ContainsKey(key))
		{
			if (key.StartsWith("enemy_"))
			{
				// try both specific enemy_* and generic role
				string role = key.Replace("enemy_", "");
				key = COLOR_PRESETS.ContainsKey("enemy_" + role) ? ("enemy_" + role) : role;
			}
		}
		sprite.Modulate = COLOR_PRESETS.ContainsKey(key) ? COLOR_PRESETS[key] : Colors.White;
		sprite.Visible = true;
	}

	public static Vector2 GetOptimalScale(string entityType)
	{
		// Get the optimal scale for an entity type
		return SCALE_PRESETS.ContainsKey(entityType) ? SCALE_PRESETS[entityType] : new Vector2(1.0f, 1.0f);
	}

	public static Color GetOptimalColor(string entityType)
	{
		// Get the optimal color for an entity type
		return COLOR_PRESETS.ContainsKey(entityType) ? COLOR_PRESETS[entityType] : Colors.White;
	}

	public static bool ValidateSpriteVisibility(Sprite2D sprite)
	{
		// Check if a sprite is properly visible and sized
		if (sprite == null)
		{
			return false;
		}

		if (sprite.Texture == null)
		{
			return false;
		}

		if (sprite.Scale.X < 0.1f || sprite.Scale.Y < 0.1f)
		{
			GD.PushWarning($"SpriteManager: Sprite scale too small: {sprite.Scale}");
			return false;
		}

		if (!sprite.Visible)
		{
			GD.PushWarning("SpriteManager: Sprite not visible");
			return false;
		}

		return true;
	}

	// Auto-setup function for common entity types
	public void AutoSetupPlayerSprite(Sprite2D sprite)
	{
		SetupSprite(sprite, "player");
	}

	public void AutoSetupEnemySprite(Sprite2D sprite, string enemyType = "fighter")
	{
		SetupSprite(sprite, "enemy_" + enemyType);
	}

	public void AutoSetupBossSprite(Sprite2D sprite)
	{
		SetupSprite(sprite, "boss");
	}

	public void AutoSetupBulletSprite(Sprite2D sprite)
	{
		SetupSprite(sprite, "bullet");
	}

	public void AutoSetupExplosionSprite(Sprite2D sprite)
	{
		SetupSprite(sprite, "explosion");
	}
}


