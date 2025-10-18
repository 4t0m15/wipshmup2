using Godot;
using Godot.Collections;

// Loads and serves difficulty tuning from a properties file.
// File format: Godot ConfigFile (ini-like), sections per difficulty.
// Example path: res://config/difficulty.cfg
public partial class DifficultyConfigService : Node
{
	[Export] public string ConfigPath { get; set; } = "res://config/difficulty.cfg";

	private ConfigFile _cfg = new ConfigFile();
	private bool _loaded = false;
	private string _current = "normal";

	public override void _Ready()
	{
		Load();
	}

	private void Load()
	{
		var err = _cfg.Load(ConfigPath);
		if (err != Error.Ok)
		{
			_loaded = false;
			return;
		}
		_loaded = true;
		_current = _cfg.GetValue("general", "current_difficulty", "normal").ToString();
	}

	public void Reload()
	{
		Load();
	}

	public string GetCurrentDifficulty()
	{
		return _current;
	}

	public void SetCurrentDifficulty(string difficultyName, bool persist = true)
	{
		_current = difficultyName;
		if (persist && _loaded)
		{
			_cfg.SetValue("general", "current_difficulty", difficultyName);
			_cfg.Save(ConfigPath);
		}
	}

	private Variant GetValueForCurrent(string key, Variant defaultValue)
	{
		var value = _cfg.GetValue(_current, key, default(Variant));
		if (value.VariantType == Variant.Type.Nil)
		{
			value = _cfg.GetValue("normal", key, default(Variant));
		}
		return value.VariantType != Variant.Type.Nil ? value : defaultValue;
	}

	public Dictionary GetRankParams()
	{
		return new Dictionary
		{
			{ "min_rank", (float)GetValueForCurrent("min_rank", 1.0f) },
			{ "max_rank", (float)GetValueForCurrent("max_rank", 5.0f) },  // Increased from 3.0
			{ "time_rank_rate", (float)GetValueForCurrent("time_rank_rate", 0.03f) },  // 3x faster
			{ "kill_rank_rate", (float)GetValueForCurrent("kill_rank_rate", 0.002f) }  // 4x faster
		};
	}

	public Dictionary GetMultiplierCaps()
	{
		return new Dictionary
		{
			{ "enemy_speed_max_mult", (float)GetValueForCurrent("enemy_speed_max_mult", 2.5f) },  // More aggressive
			{ "enemy_hp_max_mult", (float)GetValueForCurrent("enemy_hp_max_mult", 3.5f) },  // More aggressive
			{ "bullet_speed_max_mult", (float)GetValueForCurrent("bullet_speed_max_mult", 2.2f) },  // More aggressive
			{ "pattern_density_max_mult", (float)GetValueForCurrent("pattern_density_max_mult", 2.8f) },  // More aggressive
			{ "pattern_cadence_max_mult", (float)GetValueForCurrent("pattern_cadence_max_mult", 1.5f) }  // More aggressive
		};
	}
}


