using Godot;

// Centralized utility functions for performance optimization
public static class GameUtils
{
	// Get cached player reference
	public static Node2D GetCachedPlayer()
	{
		var mainLoop = Engine.GetMainLoop();
		if (mainLoop != null && mainLoop is SceneTree tree)
		{
			return tree.GetFirstNodeInGroup("player") as Node2D;
		}
		return null;
	}

	// Get cached viewport size
	public static Vector2 GetCachedViewportSize()
	{
		var mainLoop = Engine.GetMainLoop();
		if (mainLoop != null && mainLoop is SceneTree tree)
		{
			var root = tree.Root;
			if (root != null)
			{
				return root.GetViewport().GetVisibleRect().Size;
			}
		}
		return Vector2.Zero;
	}

	// Check if position is on screen
	public static bool IsOnScreen(Vector2 position, float margin = 32.0f)
	{
		var viewportSize = GetCachedViewportSize();
		return position.X >= -margin 
			&& position.X <= viewportSize.X + margin 
			&& position.Y >= -margin 
			&& position.Y <= viewportSize.Y + margin;
	}

	// Get distance between two positions
	public static float GetDistance(Vector2 pos1, Vector2 pos2)
	{
		return pos1.DistanceTo(pos2);
	}

	// Get direction from one position to another
	public static Vector2 GetDirection(Vector2 fromPos, Vector2 toPos)
	{
		return (toPos - fromPos).Normalized();
	}

	// Check if object should be cleaned up based on position
	public static bool ShouldCleanup(Vector2 position, bool isTurret = false)
	{
		var viewportSize = GetCachedViewportSize();

		if (!isTurret && position.Y >= viewportSize.Y - 2)
		{
			return true;
		}
		if (position.Y > viewportSize.Y + 64 
			|| position.X < -64 
			|| position.X > viewportSize.X + 64)
		{
			return true;
		}

		return false;
	}

	// Spawn bullet with optimized parameters
	public static void SpawnBullet(PackedScene bulletScene, Vector2 position, Vector2 direction, float speed, Node parent)
	{
		if (bulletScene == null || parent == null)
		{
			return;
		}

		var bullet = bulletScene.Instantiate();
		if (bullet != null && GodotObject.IsInstanceValid(bullet))
		{
			if (bullet is Node2D node2D)
			{
				node2D.GlobalPosition = position;
			}
			
			if (bullet.HasMethod("set"))
			{
				bullet.Set("direction", direction.Normalized());
				bullet.Set("speed", speed);
			}

			var container = parent.GetNodeOrNull("GameViewport/Bullets");
			var target = container ?? parent;
			if (target != null && target.HasMethod("add_child"))
			{
				target.AddChild(bullet);
				
				// Ensure collision is properly enabled after adding to scene
				if (bullet is Area2D area)
				{
					area.Monitoring = true;
					area.CollisionLayer = 0;
					area.CollisionMask = 1;
				}
			}
		}
	}
}

