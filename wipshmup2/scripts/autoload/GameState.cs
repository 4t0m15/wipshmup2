using Godot;

public partial class GameState : Node
{
	// Player state
	private int _lives = 3;
	private int _bombs = 3;
	private int _score = 0;
	private bool _playerInvincible = false;
	private Vector2 _playerPosition = new Vector2(160, 150);

	// Cho Ren Sha 68K
	private bool _hasShield = false;
	private int _weaponPower = 1;
	private int _currentLoop = 1;
	private int _lastExtendScore = 0;

	// Fire Rate Boost
	private bool _fireRateBoostActive = false;
	private float _fireRateBoostTimer = 0.0f;
	private float _fireRateMultiplier = 1.0f;

	// Game Flow
	private bool _gameOver = false;
	private bool _gamePaused = false;
	private int _currentStage = 1;
	private int _currentWave = 0;

	// Streak
	private int _chainCount = 0;
	private int _maxChain = 0;
	private float _lastKillTime = 0.0f;
	private float _chainTimeout = 2.0f;

	// Config
	private float _shotCooldown = 0.1f;
	private float _playerSpeed = 200.0f;
	private Rect2 _screenBounds = new Rect2(16, 16, 288, 148);  // 320x180 with margins

	// Internal
	private float _lastShotTime = 0.0f;
	private float _gameStartTime = 0.0f;

	private EventBus _eventBus;

	// Public Properties
	public int Lives
	{
		get => _lives;
		private set
		{
			int oldLives = _lives;
			_lives = Mathf.Max(0, value);
			if (_lives != oldLives)
			{
				_eventBus?.EmitSignal(EventBus.SignalName.LivesChanged, _lives);
				if (_lives <= 0)
				{
					TriggerGameOver();
				}
			}
		}
	}

	public int Bombs
	{
		get => _bombs;
		private set
		{
			int oldBombs = _bombs;
			_bombs = Mathf.Max(0, value);
			if (_bombs != oldBombs)
			{
				_eventBus?.EmitSignal(EventBus.SignalName.BombsChanged, _bombs);
			}
		}
	}

	public int Score
	{
		get => _score;
		private set
		{
			int oldScore = _score;
			_score = Mathf.Max(0, value);
			if (_score != oldScore)
			{
				_eventBus?.EmitSignal(EventBus.SignalName.ScoreChanged, _score);
			}
		}
	}

	public bool PlayerInvincible => _playerInvincible;
	public Vector2 PlayerPosition => _playerPosition;
	public bool HasShield => _hasShield;
	public int WeaponPower => _weaponPower;
	public int CurrentLoop => _currentLoop;
	public bool GameOver => _gameOver;
	public bool GamePaused => _gamePaused;
	public int CurrentStage => _currentStage;
	public int CurrentWave => _currentWave;
	public int ChainCount => _chainCount;
	public int MaxChain => _maxChain;
	public float ShotCooldown => _shotCooldown;
	public float PlayerSpeed => _playerSpeed;
	public Rect2 ScreenBounds => _screenBounds;

	public override void _Ready()
	{
		GD.Print("[GameState] Game state system initialized");
		_gameStartTime = Time.GetTicksMsec() / 1000.0f;
		_eventBus = GetNode<EventBus>("/root/EventBus");
	}

	public override void _Process(double delta)
	{
		// Update boost timer
		UpdateFireRateBoost((float)delta);
	}

	// Player Management
	public void SetLives(int newLives)
	{
		Lives = newLives;
	}

	public void AddLives(int amount)
	{
		Lives += amount;
	}

	public void TakeLives(int amount)
	{
		Lives -= amount;
	}

	public void SetBombs(int newBombs)
	{
		Bombs = newBombs;
	}

	public void AddBombs(int amount)
	{
		Bombs += amount;
	}

	public bool UseBomb()
	{
		if (_bombs > 0)
		{
			Bombs = _bombs - 1;
			_eventBus.EmitSignal(EventBus.SignalName.BombUsed, _playerPosition);
			return true;
		}
		return false;
	}

	public void SetScore(int newScore)
	{
		Score = newScore;
	}

	public void AddScore(int amount)
	{
		Score = _score + amount;
		// Check for million-point extends
		CheckScoreExtends();
	}

	// Invincibility
	public void SetInvincible(bool invincible)
	{
		_playerInvincible = invincible;
		if (invincible)
		{
			_eventBus.EmitSignal(EventBus.SignalName.PlayerInvincibilityStarted);
		}
		else
		{
			_eventBus.EmitSignal(EventBus.SignalName.PlayerInvincibilityEnded);
		}
	}

	public bool IsInvincible()
	{
		return _playerInvincible;
	}

	// Game Flow
	public void StartGame()
	{
		_gameOver = false;
		_gamePaused = false;
		_currentStage = 1;
		_currentWave = 0;
		_eventBus.EmitSignal(EventBus.SignalName.GameStarted);
	}

	public void TriggerGameOver()
	{
		if (!_gameOver)
		{
			_gameOver = true;
			_eventBus.EmitSignal(EventBus.SignalName.GameOver);
		}
	}

	public void PauseGame()
	{
		if (!_gameOver)
		{
			_gamePaused = true;
			_eventBus.EmitSignal(EventBus.SignalName.GamePaused);
		}
	}

	public void ResumeGame()
	{
		if (!_gameOver)
		{
			_gamePaused = false;
			_eventBus.EmitSignal(EventBus.SignalName.GameResumed);
		}
	}

	public void ResetGame()
	{
		_lives = 3;
		_bombs = 3;
		_score = 0;
		_playerInvincible = false;
		_gameOver = false;
		_gamePaused = false;
		_currentStage = 1;
		_currentWave = 0;
		_chainCount = 0;
		_maxChain = 0;
		_lastKillTime = 0.0f;
		_gameStartTime = Time.GetTicksMsec() / 1000.0f;

		// Reset Cho Ren Sha mechanics
		_hasShield = false;
		_weaponPower = 1;
		_currentLoop = 1;
		_lastExtendScore = 0;

		// Reset fire rate boost
		_fireRateBoostActive = false;
		_fireRateBoostTimer = 0.0f;
		_fireRateMultiplier = 1.0f;
	}

	// Streak
	public void UpdateStreak()
	{
		float currentTime = Time.GetTicksMsec() / 1000.0f;

		if (_lastKillTime > 0.0f && (currentTime - _lastKillTime) <= _chainTimeout)
		{
			_chainCount += 1;
		}
		else
		{
			_chainCount = 1;
		}

		_lastKillTime = currentTime;
		_maxChain = Mathf.Max(_maxChain, _chainCount);

		_eventBus.EmitSignal(EventBus.SignalName.StreakChanged, _chainCount, _maxChain);
	}

	public void BreakStreak()
	{
		_chainCount = 0;
		_eventBus.EmitSignal(EventBus.SignalName.ChainBroken);
		_eventBus.EmitSignal(EventBus.SignalName.StreakChanged, _chainCount, _maxChain);
	}

	// Stage
	public void SetStage(int stageNumber)
	{
		_currentStage = stageNumber;
		_eventBus.EmitSignal(EventBus.SignalName.StageStarted, stageNumber);
	}

	public void CompleteStage()
	{
		_eventBus.EmitSignal(EventBus.SignalName.StageCompleted, _currentStage);
		_currentStage += 1;
	}

	public void SetWave(int waveNumber)
	{
		_currentWave = waveNumber;
		_eventBus.EmitSignal(EventBus.SignalName.WaveStarted, waveNumber);
	}

	// Movement
	public void UpdatePlayerPosition(Vector2 newPosition)
	{
		// Clamp to screen bounds
		_playerPosition.X = Mathf.Clamp(newPosition.X, _screenBounds.Position.X, _screenBounds.Position.X + _screenBounds.Size.X);
		_playerPosition.Y = Mathf.Clamp(newPosition.Y, _screenBounds.Position.Y, _screenBounds.Position.Y + _screenBounds.Size.Y);
	}

	public bool CanShoot()
	{
		if (_gameOver || _gamePaused)
		{
			return false;
		}

		float currentTime = Time.GetTicksMsec() / 1000.0f;
		return (currentTime - _lastShotTime) >= _shotCooldown;
	}

	public void RecordShot()
	{
		_lastShotTime = Time.GetTicksMsec() / 1000.0f;
	}

	// Utils
	public float GetGameTime()
	{
		return (Time.GetTicksMsec() / 1000.0f) - _gameStartTime;
	}

	public bool IsGameActive()
	{
		return !_gameOver && !_gamePaused;
	}

	// Getters
	public Godot.Collections.Dictionary GetPlayerState()
	{
		return new Godot.Collections.Dictionary
		{
			{ "lives", _lives },
			{ "bombs", _bombs },
			{ "score", _score },
			{ "invincible", _playerInvincible },
			{ "position", _playerPosition },
			{ "chain_count", _chainCount },
			{ "max_chain", _maxChain }
		};
	}

	public Godot.Collections.Dictionary GetGameState()
	{
		return new Godot.Collections.Dictionary
		{
			{ "game_over", _gameOver },
			{ "game_paused", _gamePaused },
			{ "current_stage", _currentStage },
			{ "current_wave", _currentWave },
			{ "game_time", GetGameTime() }
		};
	}

	// Cho Ren Sha 68K

	// Shield
	public void SetShield(bool shieldActive)
	{
		bool oldShield = _hasShield;
		_hasShield = shieldActive;
		if (_hasShield != oldShield)
		{
			if (_hasShield)
			{
				_eventBus.EmitSignal(EventBus.SignalName.ShieldGained);
			}
			else
			{
				_eventBus.EmitSignal(EventBus.SignalName.ShieldLost);
			}
		}
	}

	public bool ConsumeShield()
	{
		if (_hasShield)
		{
			_hasShield = false;
			_eventBus.EmitSignal(EventBus.SignalName.ShieldAbsorbed);
			return true;
		}
		return false;
	}

	public void ActivateShield()
	{
		SetShield(true);
		GD.Print("[GameState] Shield activated");
	}

	public void IncreaseWeaponPower(int amount = 1)
	{
		AddWeaponPower(amount);
		GD.Print($"[GameState] Weapon power increased to: {_weaponPower}");
	}

	// Weapon Power
	public void AddWeaponPower(int amount = 1)
	{
		_weaponPower = Mathf.Min(_weaponPower + amount, 8);
		_eventBus.EmitSignal(EventBus.SignalName.WeaponPowerChanged, _weaponPower);
	}

	public void ResetWeaponPower()
	{
		_weaponPower = 1;
		_eventBus.EmitSignal(EventBus.SignalName.WeaponPowerChanged, _weaponPower);
	}

	// Loop
	public void IncrementLoop()
	{
		_currentLoop += 1;
		_eventBus.EmitSignal(EventBus.SignalName.LoopIncremented, _currentLoop);
	}

	// Score Extends
	private void CheckScoreExtends()
	{
		// We want integer division here to get millions (e.g., 1,500,000 -> 1)
		int currentMillions = Mathf.FloorToInt(_score / 1000000.0f);
		int lastMillions = Mathf.FloorToInt(_lastExtendScore / 1000000.0f);

		if (currentMillions > lastMillions)
		{
			AddLives(1);
			_lastExtendScore = _score;
			_eventBus.EmitSignal(EventBus.SignalName.LifeExtended, "score_threshold");
		}
	}

	// Stage Bonuses
	public int CalculateStageBonus()
	{
		int bonus = 0;

		// Max weapon power bonus
		if (_weaponPower >= 8)
		{
			bonus += 10000;
		}

		// Full bomb stock bonus (assuming max 9 bombs)
		if (_bombs >= 9)
		{
			bonus += _bombs * 5000;
		}

		// Active shield bonus
		if (_hasShield)
		{
			bonus += 20000;
		}

		return bonus;
	}

	// Fire Rate Boost
	public void ActivateFireRateBoost(float duration = 10.0f)
	{
		// Activate boost
		_fireRateBoostActive = true;
		_fireRateBoostTimer = duration;
		_fireRateMultiplier = 2.0f;  // Double fire rate
		_eventBus.EmitSignal(EventBus.SignalName.FireRateBoostActivated, duration);
		GD.Print($"[GameState] Fire rate boost activated for {duration} seconds");
	}

	private void UpdateFireRateBoost(float delta)
	{
		// Update boost timer
		if (_fireRateBoostActive)
		{
			_fireRateBoostTimer -= delta;
			if (_fireRateBoostTimer <= 0.0f)
			{
				_fireRateBoostActive = false;
				_fireRateMultiplier = 1.0f;
				_eventBus.EmitSignal(EventBus.SignalName.FireRateBoostEnded);
				GD.Print("[GameState] Fire rate boost ended");
			}
		}
	}

	public float GetFireRateMultiplier()
	{
		// Get multiplier
		return _fireRateBoostActive ? _fireRateMultiplier : 1.0f;
	}
}

