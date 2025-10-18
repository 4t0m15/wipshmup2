using Godot;
using Godot.Collections;

public partial class RankManager : Node
{
	[Export] public float MinRank { get; set; } = 1.0f;
	[Export] public float MaxRank { get; set; } = 5.0f;  // Increased from 3.0 for wider difficulty range
	[Export] public float TimeRankRate { get; set; } = 0.03f;  // 3x faster - was 0.01
	[Export] public float KillRankRate { get; set; } = 0.002f;  // 4x faster - was 0.0005
	[Export] public float ShotRankRate { get; set; } = 0.00006f;  // 4x faster - was 0.000015

	[Export] public float BombUseRankAdd { get; set; } = 0.15f;  // 2.5x more - was 0.06 (punish bombing)
	[Export] public float DeathRankDrop { get; set; } = 0.12f;  // Half reduction - was 0.22 (less forgiving)
	[Export] public float BulletSealRankRate { get; set; } = 0.0008f;  // 4x faster - was 0.0002

	public float Rank { get; private set; } = 1.0f;
	public int StageNumber { get; private set; } = 1;
	private int _previousLives = -1;

	// Max multiplier caps - AGGRESSIVE SCALING
	private Dictionary _multipliers = new Dictionary
	{
		{ "enemy_speed", 2.5f },      // Increased from 1.4 - enemies get MUCH faster
		{ "enemy_hp", 3.5f },         // Increased from 2.0 - enemies become tanks
		{ "bullet_speed", 2.2f },     // Increased from 1.3 - bullets get very fast
		{ "pattern_density", 2.8f },  // Increased from 1.6 - many more bullets
		{ "pattern_cadence", 1.5f }   // Increased from 0.8 - fire much faster
	};

	public override void _Ready()
	{
		var dc = GetNodeOrNull("/root/DifficultyConfig");
		if (dc != null && dc.HasMethod("get_rank_params"))
		{
			var rp = dc.Call("get_rank_params").As<Dictionary>();
			MinRank = (float)rp.Get("min_rank", MinRank);
			MaxRank = (float)rp.Get("max_rank", MaxRank);
			TimeRankRate = (float)rp.Get("time_rank_rate", TimeRankRate);
			KillRankRate = (float)rp.Get("kill_rank_rate", KillRankRate);
		}

		if (dc != null && dc.HasMethod("get_multiplier_caps"))
		{
			var caps = dc.Call("get_multiplier_caps").As<Dictionary>();
			_multipliers["enemy_speed"] = (float)caps.Get("enemy_speed_max_mult", _multipliers["enemy_speed"]);
			_multipliers["enemy_hp"] = (float)caps.Get("enemy_hp_max_mult", _multipliers["enemy_hp"]);
			_multipliers["bullet_speed"] = (float)caps.Get("bullet_speed_max_mult", _multipliers["bullet_speed"]);
			_multipliers["pattern_density"] = (float)caps.Get("pattern_density_max_mult", _multipliers["pattern_density"]);
			_multipliers["pattern_cadence"] = (float)caps.Get("pattern_cadence_max_mult", _multipliers["pattern_cadence"]);
		}

		// Initialize rank and hook stage resets
		SetRank(MinRank);
		
		var eb = GetNodeOrNull("/root/EventBus") as EventBus;
		if (eb != null)
		{
			eb.StageStarted += OnStageStarted;
			eb.InputShoot += OnInputShoot;
			eb.LivesChanged += OnLivesChanged;
		}
		
		// Initialize previous lives from GameState if available
		var gs = GetNodeOrNull("/root/GameState");
		if (gs != null)
		{
			var livesValue = gs.Get("lives");
			if (livesValue.VariantType != Variant.Type.Nil)
			{
				_previousLives = (int)livesValue;
			}
		}
	}

	public override void _Process(double delta)
	{
		SetRank(Rank + TimeRankRate * (float)delta);
	}

	public void Reset(int newStage)
	{
		StageNumber = newStage;
		// Start each stage at higher rank - was 0.05, now 0.25
		SetRank(1.0f + (StageNumber - 1) * 0.25f);
	}

	public void OnEnemyKilled(int points)
	{
		SetRank(Rank + KillRankRate * points);
	}

	public void OnShotFired(float multiplier = 1.0f)
	{
		SetRank(Rank + ShotRankRate * Mathf.Max(0.0f, multiplier));
	}

	public void OnBombUsed()
	{
		SetRank(Rank + BombUseRankAdd);
	}

	public void OnPlayerDied(int currentLives = 0)
	{
		// Less forgiving - reduced life_factor scaling
		float lifeFactor = Mathf.Clamp(1.0f - 0.02f * Mathf.Max(currentLives - 1, 0), 0.9f, 1.0f);
		SetRank(Rank - DeathRankDrop * lifeFactor);
	}

	public void OnBulletSealed()
	{
		SetRank(Rank + BulletSealRankRate);
	}

	public void OnBossDefeated()
	{
		// Provide slight relief after boss defeat
		SetRank(Rank - 0.3f);
	}

	public float GetRankPercent()
	{
		return Mathf.Clamp((Rank - MinRank) / (MaxRank - MinRank), 0.0f, 1.0f) * 100.0f;
	}

	public float GetMultiplier(string type)
	{
		float maxMult = (float)_multipliers.Get(type, 1.0f);
		float normalized = Mathf.Clamp((Rank - MinRank) / (MaxRank - MinRank), 0.0f, 1.0f);
		return Mathf.Lerp(1.0f, maxMult, normalized);
	}

	public float GetEnemySpeedMultiplier()
	{
		return GetMultiplier("enemy_speed");
	}

	public float GetEnemyHpMultiplier()
	{
		return GetMultiplier("enemy_hp");
	}

	public float GetBulletSpeedMultiplier()
	{
		return GetMultiplier("bullet_speed");
	}

	public float GetPatternDensityMultiplier()
	{
		return GetMultiplier("pattern_density");
	}

	public float GetPatternCadenceMultiplier()
	{
		return GetMultiplier("pattern_cadence");
	}

	// Internal helpers and signal relays
	private void SetRank(float newRank)
	{
		float clamped = Mathf.Clamp(newRank, MinRank, MaxRank);
		if (Mathf.Abs(clamped - Rank) > 0.0001f)
		{
			Rank = clamped;
			var eb = GetNodeOrNull("/root/EventBus") as EventBus;
			if (eb != null)
			{
				eb.EmitSignal(EventBus.SignalName.RankChanged, Rank);
			}
		}
	}

	private void OnStageStarted(int stageNum)
	{
		Reset(stageNum);
	}

	private void OnInputShoot(bool pressed)
	{
		if (!pressed)
		{
			return;
		}
		
		var gs = GetNodeOrNull("/root/GameState");
		float mult = 1.0f;
		if (gs != null && gs.HasMethod("get_fire_rate_multiplier"))
		{
			mult = (float)gs.Call("get_fire_rate_multiplier");
		}
		OnShotFired(mult);
	}

	private void OnLivesChanged(int newLives)
	{
		if (_previousLives >= 0 && newLives < _previousLives)
		{
			OnPlayerDied(newLives);
		}
		_previousLives = newLives;
	}
}


