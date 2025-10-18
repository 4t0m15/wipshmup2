using Godot;

public partial class BulletPatterns : Node
{
	private const float BASE_DENSITY_MULT = 0.6f;  // Increased from 0.25 - MORE BULLETS
	private const float BASE_SPEED_MULT = 0.7f;  // Increased from 0.35 - FASTER BULLETS
	private const float BASE_CADENCE_MULT = 1.2f;  // Increased from 0.9 - FIRE FASTER
	private const int SOFT_ENEMY_BULLET_CAP = 300;  // Increased from 140

	// Difficulty scaling
	private static float _difficultyMultiplier = 1.0f;

	public static void SetDifficultyMultiplier(float value)
	{
		_difficultyMultiplier = Mathf.Max(0.1f, value);  // Ensure it's not too low
		GD.Print($"[BulletPatterns] Difficulty multiplier set to: {_difficultyMultiplier}");
	}

	private static float GetDensityMultiplier()
	{
		float rankMult = 1.0f;
		var rankManager = Engine.GetMainLoop().Root.GetNodeOrNull("/root/RankManager");
		if (rankManager != null && rankManager.HasMethod("get_pattern_density_multiplier"))
		{
			rankMult = (float)rankManager.Call("get_pattern_density_multiplier");
		}
		return BASE_DENSITY_MULT * rankMult * GetDynamicThrottle();
	}

	private static float GetCadenceMultiplier()
	{
		float c = 1.0f;
		var rankManager = Engine.GetMainLoop().Root.GetNodeOrNull("/root/RankManager");
		if (rankManager != null && rankManager.HasMethod("get_pattern_cadence_multiplier"))
		{
			c = Mathf.Max(0.001f, (float)rankManager.Call("get_pattern_cadence_multiplier"));
		}
		return c * BASE_CADENCE_MULT * GetDynamicThrottle();
	}

	private static float GetDynamicThrottle()
	{
		// Throttle intensity based on current enemy bullet load
		var ml = Engine.GetMainLoop();
		if (ml is SceneTree tree)
		{
			var bullets = tree.GetNodesInGroup("enemy_bullet");
			float loadRatio = bullets.Count / (float)SOFT_ENEMY_BULLET_CAP;
			// Start throttling as we approach 70% of cap; never drop below 0.25
			float throttle = 1.0f - Mathf.Max(0.0f, loadRatio - 0.7f) / 0.6f;
			return Mathf.Clamp(throttle, 0.25f, 1.0f);
		}
		return 1.0f;
	}

	private static void SpawnBullet(Node node, Vector2 position, Vector2 direction, float speed)
	{
		// Use EntityFactory for bullet spawning with difficulty scaling and dynamic throttle
		float dyn = GetDynamicThrottle();
		var entityFactory = Engine.GetMainLoop().Root.GetNodeOrNull("/root/EntityFactory") as EntityFactory;
		if (entityFactory != null)
		{
			entityFactory.SpawnEnemyBullet(position, direction.Normalized(), speed * BASE_SPEED_MULT * _difficultyMultiplier * dyn);
		}

		// Play enemy shot sound through EventBus
		var eventBus = Engine.GetMainLoop().Root.GetNodeOrNull("/root/EventBus") as EventBus;
		if (eventBus != null)
		{
			eventBus.EmitSignal(EventBus.SignalName.AudioRequested, "enemy_shot");
		}
	}

	private static async void AwaitSeconds(Node node, float seconds)
	{
		if (GodotObject.IsInstanceValid(node))
		{
			await node.ToSignal(node.GetTree().CreateTimer(seconds, false), "timeout");
		}
		else
		{
			var ml = Engine.GetMainLoop();
			if (ml is SceneTree tree)
			{
				await node.ToSignal(tree.CreateTimer(seconds, false), "timeout");
			}
		}
	}

	public static void FireRing(Node node, Vector2 origin, int bulletCount, float speed = 120.0f, float startAngleRad = 0.0f)
	{
		if (bulletCount <= 0) return;
		int count = Mathf.Max(1, (int)Mathf.Round(bulletCount * GetDensityMultiplier()));
		float step = Mathf.Tau / count;
		for (int i = 0; i < count; i++)
		{
			float angle = startAngleRad + step * i;
			SpawnBullet(node, origin, Vector2.Right.Rotated(angle), speed);
		}
	}

	public static void FireFan(Node node, Vector2 origin, int bulletCount, float spreadDegrees, float baseAngleDegrees, float speed = 130.0f)
	{
		if (bulletCount <= 0) return;
		int count = Mathf.Max(1, (int)Mathf.Round(bulletCount * GetDensityMultiplier()));
		float spreadRad = Mathf.DegToRad(spreadDegrees);
		float baseRad = Mathf.DegToRad(baseAngleDegrees);
		float start = baseRad - spreadRad * 0.5f;
		float step = count == 1 ? 0.0f : spreadRad / (count - 1);
		for (int i = 0; i < count; i++)
		{
			float angle = start + step * i;
			SpawnBullet(node, origin, Vector2.Right.Rotated(angle), speed);
		}
	}

	public static async void FireSweepingSpread(Node node, Node2D originNode, float startDegrees, float endDegrees, float durationS, int steps, int bulletsPerStep, float speed = 120.0f)
	{
		if (steps <= 0 || bulletsPerStep <= 0 || durationS <= 0.0f) return;
		float startRad = Mathf.DegToRad(startDegrees);
		float endRad = Mathf.DegToRad(endDegrees);
		float stepTime = durationS / steps / GetCadenceMultiplier();
		int bps = Mathf.Max(1, (int)Mathf.Round(bulletsPerStep * GetDensityMultiplier()));

		for (int i = 0; i < steps; i++)
		{
			if (!GodotObject.IsInstanceValid(originNode)) return;
			float t = i / (float)Mathf.Max(steps - 1, 1);
			float angle = Mathf.Lerp(startRad, endRad, t);
			FireFan(node, originNode.GlobalPosition, bps, 20.0f, Mathf.RadToDeg(angle), speed);
			AwaitSeconds(node, stepTime);
			await node.ToSignal(node.GetTree().CreateTimer(stepTime, false), "timeout");
		}
	}

	public static async void FireAimedBeam(Node node, Node2D originNode, Node2D targetNode, float durationS, float intervalS = 0.05f, float speed = 400.0f)
	{
		if (durationS <= 0.0f || intervalS <= 0.0f) return;
		float elapsed = 0.0f;
		float iv = intervalS / GetCadenceMultiplier();

		while (elapsed < durationS)
		{
			if (!GodotObject.IsInstanceValid(originNode) || !GodotObject.IsInstanceValid(targetNode)) return;
			Vector2 toTarget = (targetNode.GlobalPosition - originNode.GlobalPosition).Normalized();
			SpawnBullet(node, originNode.GlobalPosition, toTarget, speed);
			AwaitSeconds(node, iv);
			await node.ToSignal(node.GetTree().CreateTimer(iv, false), "timeout");
			elapsed += iv;
		}
	}

	public static async void FireCrossHatch(Node node, Node2D originNode, int waves, int bulletsPerFan = 7, float spreadDegrees = 60.0f, float speed = 120.0f, float intervalS = 0.25f)
	{
		if (waves <= 0) return;
		int bpf = Mathf.Max(1, (int)Mathf.Round(bulletsPerFan * GetDensityMultiplier()));
		float iv = intervalS / GetCadenceMultiplier();

		for (int i = 0; i < waves; i++)
		{
			if (!GodotObject.IsInstanceValid(originNode)) return;
			Vector2 origin = originNode.GlobalPosition;
			FireFan(node, origin, bpf, spreadDegrees, -45.0f, speed);
			FireFan(node, origin, bpf, spreadDegrees, 135.0f, speed);
			AwaitSeconds(node, iv);
			await node.ToSignal(node.GetTree().CreateTimer(iv, false), "timeout");
			if (!GodotObject.IsInstanceValid(originNode)) return;
			origin = originNode.GlobalPosition;
			FireFan(node, origin, bpf, spreadDegrees, 45.0f, speed);
			FireFan(node, origin, bpf, spreadDegrees, -135.0f, speed);
			AwaitSeconds(node, iv);
			await node.ToSignal(node.GetTree().CreateTimer(iv, false), "timeout");
		}
	}

	public static async void FireRotatingRings(Node node, Node2D originNode, int bursts, int bulletsPerRing = 16, float speed = 100.0f, float rotationStepDegrees = 12.0f, float intervalS = 0.35f)
	{
		if (bursts <= 0) return;
		float angle = 0.0f;
		float iv = intervalS / GetCadenceMultiplier();

		for (int i = 0; i < bursts; i++)
		{
			if (!GodotObject.IsInstanceValid(originNode)) return;
			int count = Mathf.Max(1, (int)Mathf.Round(bulletsPerRing * GetDensityMultiplier()));
			FireRing(node, originNode.GlobalPosition, count, speed, Mathf.DegToRad(angle));
			angle += rotationStepDegrees;
			AwaitSeconds(node, iv);
			await node.ToSignal(node.GetTree().CreateTimer(iv, false), "timeout");
		}
	}

	// New patterns
	public static async void FireSpiral(Node node, Node2D originNode, int turns = 2, int bulletsPerTurn = 24, float speed = 120.0f, float angularStepDeg = 10.0f, float accel = 0.0f)
	{
		if (turns <= 0 || bulletsPerTurn <= 0) return;
		int total = Mathf.Max(1, (int)Mathf.Round(turns * bulletsPerTurn * GetDensityMultiplier()));
		float angleDeg = 0.0f;
		for (int i = 0; i < total; i++)
		{
			if (!GodotObject.IsInstanceValid(originNode)) return;
			Vector2 dir = Vector2.Right.Rotated(Mathf.DegToRad(angleDeg));
			SpawnBullet(node, originNode.GlobalPosition, dir, speed);
			angleDeg += angularStepDeg;
			float delay = 0.02f / GetCadenceMultiplier();
			AwaitSeconds(node, delay);
			await node.ToSignal(node.GetTree().CreateTimer(delay, false), "timeout");
		}
	}

	public static void FireAccelBloom(Node node, Vector2 origin, int petals = 12, float speed = 90.0f, float accel = 40.0f)
	{
		int count = Mathf.Max(1, (int)Mathf.Round(petals * GetDensityMultiplier()));
		float step = Mathf.Tau / count;
		for (int i = 0; i < count; i++)
		{
			float angle = step * i;
			Vector2 dir = Vector2.Right.Rotated(angle);
			SpawnBullet(node, origin, dir, speed);
		}
	}

	public static async void FireWaveStream(Node node, Node2D originNode, float durationS = 1.2f, float intervalS = 0.06f, float baseAngleDeg = 90.0f, float wiggleAmp = 18.0f, float wiggleFreq = 2.0f, float speed = 120.0f)
	{
		if (durationS <= 0.0f) return;
		float elapsed = 0.0f;
		float iv = intervalS / GetCadenceMultiplier();
		while (elapsed < durationS)
		{
			if (!GodotObject.IsInstanceValid(originNode)) return;
			Vector2 dir = Vector2.Right.Rotated(Mathf.DegToRad(baseAngleDeg));
			SpawnBullet(node, originNode.GlobalPosition, dir, speed);
			AwaitSeconds(node, iv);
			await node.ToSignal(node.GetTree().CreateTimer(iv, false), "timeout");
			elapsed += iv;
		}
	}

	public static async void FireFixedBeam(Node node, Node2D originNode, float angleDegrees, float durationS, float intervalS = 0.02f, float speed = 450.0f)
	{
		if (durationS <= 0.0f || intervalS <= 0.0f) return;
		float elapsed = 0.0f;
		Vector2 dir = Vector2.Right.Rotated(Mathf.DegToRad(angleDegrees)).Normalized();
		float iv = intervalS / GetCadenceMultiplier();

		while (elapsed < durationS)
		{
			if (!GodotObject.IsInstanceValid(originNode)) return;
			SpawnBullet(node, originNode.GlobalPosition, dir, speed);
			AwaitSeconds(node, iv);
			await node.ToSignal(node.GetTree().CreateTimer(iv, false), "timeout");
			elapsed += iv;
		}
	}

	public static async void FireDualLasers(Node node, Node2D originNode, float baseAngleDegrees, float separationDegrees, float durationS, float intervalS = 0.025f, float speed = 450.0f)
	{
		if (durationS <= 0.0f || intervalS <= 0.0f) return;
		float elapsed = 0.0f;
		float angA = baseAngleDegrees - separationDegrees * 0.5f;
		float angB = baseAngleDegrees + separationDegrees * 0.5f;
		Vector2 dirA = Vector2.Right.Rotated(Mathf.DegToRad(angA)).Normalized();
		Vector2 dirB = Vector2.Right.Rotated(Mathf.DegToRad(angB)).Normalized();
		float iv = intervalS / GetCadenceMultiplier();

		while (elapsed < durationS)
		{
			if (!GodotObject.IsInstanceValid(originNode)) return;
			Vector2 origin = originNode.GlobalPosition;
			SpawnBullet(node, origin, dirA, speed);
			SpawnBullet(node, origin, dirB, speed);
			AwaitSeconds(node, iv);
			await node.ToSignal(node.GetTree().CreateTimer(iv, false), "timeout");
			elapsed += iv;
		}
	}
}

