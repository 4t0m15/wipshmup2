using Godot;
using System.Collections.Generic;

public partial class EventBus : Node
{
	private bool _debugLogging;

	// Game signals
	[Signal] public delegate void PlayerHitEventHandler();
	[Signal] public delegate void PlayerDamagedEventHandler(int amount);
	[Signal] public delegate void GameOverEventHandler();
	[Signal] public delegate void GameStartedEventHandler();
	[Signal] public delegate void GamePausedEventHandler();
	[Signal] public delegate void GameResumedEventHandler();

	// Player signals
	[Signal] public delegate void ScoreChangedEventHandler(int newScore);
	[Signal] public delegate void LivesChangedEventHandler(int newLives);
	[Signal] public delegate void BombsChangedEventHandler(int newBombs);
	[Signal] public delegate void PlayerInvincibilityStartedEventHandler();
	[Signal] public delegate void PlayerInvincibilityEndedEventHandler();

	// Combat signals
	[Signal] public delegate void EnemyKilledEventHandler(int points, Vector2 position, string enemyType);
	[Signal] public delegate void BossDefeatedEventHandler(string bossName, int points);
	[Signal] public delegate void BulletHitPlayerEventHandler(Vector2 bulletPosition);
	[Signal] public delegate void BulletHitEnemyEventHandler(Vector2 enemyPosition, int damage);
	[Signal] public delegate void BombUsedEventHandler(Vector2 position);

	// Stage signals
	[Signal] public delegate void StageStartedEventHandler(int stageNumber);
	[Signal] public delegate void StageCompletedEventHandler(int stageNumber);
	[Signal] public delegate void EnemySpawnedEventHandler(Node enemy, string enemyType);
	[Signal] public delegate void BossSpawnedEventHandler(Node boss, string bossName);
	[Signal] public delegate void WaveStartedEventHandler(int waveNumber);
	[Signal] public delegate void WaveCompletedEventHandler(int waveNumber);

	// Item signals
	[Signal] public delegate void ItemDroppedEventHandler(string itemType, Vector2 position);
	[Signal] public delegate void ItemCollectedEventHandler(string itemType, int value);

	// Cho Ren Sha 68K signals
	[Signal] public delegate void ShieldGainedEventHandler();
	[Signal] public delegate void ShieldLostEventHandler();
	[Signal] public delegate void ShieldAbsorbedEventHandler();
	[Signal] public delegate void WeaponPowerChangedEventHandler(int newPower);
	[Signal] public delegate void LoopIncrementedEventHandler(int newLoop);
	[Signal] public delegate void LifeExtendedEventHandler(string reason);
	[Signal] public delegate void FireRateBoostActivatedEventHandler(float duration);
	[Signal] public delegate void FireRateBoostEndedEventHandler();

	// Visual Effects signals
	[Signal] public delegate void ScreenShakeRequestedEventHandler(float intensity, float duration);
	[Signal] public delegate void HitStopRequestedEventHandler(float duration, float scale);
	[Signal] public delegate void FlashRequestedEventHandler(Color color, float duration);
	[Signal] public delegate void ExplosionRequestedEventHandler(Vector2 position, float size);
	[Signal] public delegate void StageTransitionRequestedEventHandler(int stageNumber, float duration);
	[Signal] public delegate void BackgroundChangeRequestedEventHandler(string backgroundType, Color tint, float ambientLighting);
	[Signal] public delegate void ParticleEffectRequestedEventHandler(string effectName, float duration);

	// Audio signals
	[Signal] public delegate void PlaySoundEventHandler(string soundName, float volume);
	[Signal] public delegate void PlayMusicEventHandler(string musicName, bool fadeIn);
	[Signal] public delegate void StopMusicEventHandler(bool fadeOut);

	// Input signals
	[Signal] public delegate void InputMovementEventHandler(Vector2 direction);
	[Signal] public delegate void InputShootEventHandler(bool pressed);
	[Signal] public delegate void InputBombEventHandler(bool pressed);
	[Signal] public delegate void InputPauseEventHandler(bool pressed);

	// Rank/Progress signals
	[Signal] public delegate void RankChangedEventHandler(float newRank);
	[Signal] public delegate void StreakChangedEventHandler(int current, int maxStreak);
	[Signal] public delegate void ChainBrokenEventHandler();

	// Utility signals
	[Signal] public delegate void EntitySpawnedEventHandler(Node entity, string entityType);
	[Signal] public delegate void EntityDestroyedEventHandler(Node entity, string entityType);

	public override void _Ready()
	{
		_debugLogging = OS.IsDebugBuild();
		
		if (_debugLogging)
		{
			GD.Print("[EventBus] Event system initialized");
			ConnectDebugHandlers();
		}
	}

	private void ConnectDebugHandlers()
	{
		// Connect to basic events for logging
		PlayerHit += OnPlayerHit;
		GameOver += OnGameOver;
		GameStarted += OnGameStarted;
		GamePaused += OnGamePaused;
		GameResumed += OnGameResumed;
		LivesChanged += OnLivesChanged;
		BombsChanged += OnBombsChanged;
		PlayerInvincibilityStarted += OnPlayerInvincibilityStarted;
		PlayerInvincibilityEnded += OnPlayerInvincibilityEnded;
		BulletHitPlayer += OnBulletHitPlayer;
		BulletHitEnemy += OnBulletHitEnemy;
		BombUsed += OnBombUsed;
		StageStarted += OnStageStarted;
		StageCompleted += OnStageCompleted;
		EnemySpawned += OnEnemySpawned;
		BossSpawned += OnBossSpawned;
		WaveStarted += OnWaveStarted;
		WaveCompleted += OnWaveCompleted;
		ItemDropped += OnItemDropped;
		ItemCollected += OnItemCollected;
		InputMovement += OnInputMovement;
		InputShoot += OnInputShoot;
		InputBomb += OnInputBomb;
		InputPause += OnInputPause;
		RankChanged += OnRankChanged;
		StreakChanged += OnStreakChanged;
		EntitySpawned += OnEntitySpawned;
		EntityDestroyed += OnEntityDestroyed;

		// Cho Ren Sha 68K signals
		ShieldGained += OnShieldGained;
		ShieldLost += OnShieldLost;
		ShieldAbsorbed += OnShieldAbsorbed;
		WeaponPowerChanged += OnWeaponPowerChanged;
		LoopIncremented += OnLoopIncremented;
		LifeExtended += OnLifeExtended;
		FireRateBoostActivated += OnFireRateBoostActivated;
		FireRateBoostEnded += OnFireRateBoostEnded;

		// Visual effects signals
		ScreenShakeRequested += OnScreenShakeRequested;
		HitStopRequested += OnHitStopRequested;
		FlashRequested += OnFlashRequested;
		ExplosionRequested += OnExplosionRequested;
		StageTransitionRequested += OnStageTransitionRequested;
		BackgroundChangeRequested += OnBackgroundChangeRequested;
		ParticleEffectRequested += OnParticleEffectRequested;

		// Audio signals
		PlaySound += OnPlaySound;
		PlayMusic += OnPlayMusic;
		StopMusic += OnStopMusic;
	}

	// Convenience methods for common event patterns
	public void EmitPlayerDamage(int amount)
	{
		EmitSignal(SignalName.PlayerDamaged, amount);
		if (amount > 0)
		{
			EmitSignal(SignalName.ChainBroken);
		}
	}

	public void EmitEnemyKill(int points, Vector2 position, string enemyType = "enemy")
	{
		EmitSignal(SignalName.EnemyKilled, points, position, enemyType);
		var gameState = GetNodeOrNull<GameState>("/root/GameState");
		if (gameState != null)
		{
			EmitSignal(SignalName.ScoreChanged, gameState.Score + points);
		}
	}

	public void EmitBossDefeat(string bossName, int points)
	{
		EmitSignal(SignalName.BossDefeated, bossName, points);
		var gameState = GetNodeOrNull<GameState>("/root/GameState");
		if (gameState != null)
		{
			EmitSignal(SignalName.ScoreChanged, gameState.Score + points);
		}
	}

	public void EmitVisualEffect(string effectType, Godot.Collections.Dictionary parameters)
	{
		switch (effectType)
		{
			case "screen_shake":
				EmitSignal(SignalName.ScreenShakeRequested, 
					parameters.GetValueOrDefault("intensity", 1.0f), 
					parameters.GetValueOrDefault("duration", 0.1f));
				break;
			case "hit_stop":
				EmitSignal(SignalName.HitStopRequested, 
					parameters.GetValueOrDefault("duration", 0.05f), 
					parameters.GetValueOrDefault("scale", 1.0f));
				break;
			case "flash":
			case "screen_flash":
				EmitSignal(SignalName.FlashRequested, 
					parameters.GetValueOrDefault("color", Colors.White), 
					parameters.GetValueOrDefault("duration", 0.1f));
				break;
			case "explosion":
				EmitSignal(SignalName.ExplosionRequested, 
					parameters.GetValueOrDefault("position", Vector2.Zero), 
					parameters.GetValueOrDefault("size", 1.0f));
				break;
			case "stage_transition":
				EmitSignal(SignalName.StageTransitionRequested, 
					parameters.GetValueOrDefault("stage_number", 1), 
					parameters.GetValueOrDefault("duration", 1.0f));
				break;
			case "background_change":
				EmitSignal(SignalName.BackgroundChangeRequested,
					parameters.GetValueOrDefault("background_type", "space"),
					parameters.GetValueOrDefault("tint", Colors.White),
					parameters.GetValueOrDefault("ambient_lighting", 1.0f));
				break;
			case "particle_effect":
				EmitSignal(SignalName.ParticleEffectRequested, 
					parameters.GetValueOrDefault("effect_name", ""), 
					parameters.GetValueOrDefault("duration", -1.0f));
				break;
		}
	}

	public void EmitAudio(string soundType, Godot.Collections.Dictionary parameters = null)
	{
		parameters ??= new Godot.Collections.Dictionary();
		
		switch (soundType)
		{
			case "player_shot":
				EmitSignal(SignalName.PlaySound, "player_shot", parameters.GetValueOrDefault("volume", 0.3f));
				break;
			case "enemy_shot":
				EmitSignal(SignalName.PlaySound, "enemy_shot", parameters.GetValueOrDefault("volume", 0.25f));
				break;
			case "enemy_death":
				EmitSignal(SignalName.PlaySound, "enemy_death", parameters.GetValueOrDefault("volume", 0.4f));
				break;
			case "player_hit":
				EmitSignal(SignalName.PlaySound, "player_hit", parameters.GetValueOrDefault("volume", 0.6f));
				break;
			case "bomb_use":
				EmitSignal(SignalName.PlaySound, "bomb_use", parameters.GetValueOrDefault("volume", 0.5f));
				break;
			case "boss_hit":
				EmitSignal(SignalName.PlaySound, "boss_hit", parameters.GetValueOrDefault("volume", 0.5f));
				break;
		}
	}

	// Convenience methods for audio signals with defaults
	public void PlaySoundWithDefaults(string soundName, float volume = 1.0f)
	{
		EmitSignal(SignalName.PlaySound, soundName, volume);
	}

	public void PlayMusicWithDefaults(string musicName, bool fadeIn = true)
	{
		EmitSignal(SignalName.PlayMusic, musicName, fadeIn);
	}

	public void StopMusicWithDefaults(bool fadeOut = true)
	{
		EmitSignal(SignalName.StopMusic, fadeOut);
	}

	// Event handlers for debug logging
	private void OnPlayerHit()
	{
		if (_debugLogging) GD.Print("[EventBus] Player hit event received");
	}

	private void OnGameOver()
	{
		if (_debugLogging) GD.Print("[EventBus] Game over event received");
	}

	private void OnGameStarted()
	{
		if (_debugLogging) GD.Print("[EventBus] Game started event received");
	}

	private void OnGamePaused()
	{
		if (_debugLogging) GD.Print("[EventBus] Game paused event received");
	}

	private void OnGameResumed()
	{
		if (_debugLogging) GD.Print("[EventBus] Game resumed event received");
	}

	private void OnLivesChanged(int newLives)
	{
		if (_debugLogging) GD.Print($"[EventBus] Lives changed to: {newLives}");
	}

	private void OnBombsChanged(int newBombs)
	{
		if (_debugLogging) GD.Print($"[EventBus] Bombs changed to: {newBombs}");
	}

	private void OnPlayerInvincibilityStarted()
	{
		if (_debugLogging) GD.Print("[EventBus] Player invincibility started");
	}

	private void OnPlayerInvincibilityEnded()
	{
		if (_debugLogging) GD.Print("[EventBus] Player invincibility ended");
	}

	private void OnBulletHitPlayer(Vector2 bulletPosition)
	{
		if (_debugLogging) GD.Print($"[EventBus] Bullet hit player at: {bulletPosition}");
	}

	private void OnBulletHitEnemy(Vector2 enemyPosition, int damage)
	{
		if (_debugLogging) GD.Print($"[EventBus] Bullet hit enemy at: {enemyPosition} for {damage} damage");
	}

	private void OnBombUsed(Vector2 position)
	{
		if (_debugLogging) GD.Print($"[EventBus] Bomb used at: {position}");
	}

	private void OnStageStarted(int stageNumber)
	{
		if (_debugLogging) GD.Print($"[EventBus] Stage started: {stageNumber}");
	}

	private void OnStageCompleted(int stageNumber)
	{
		if (_debugLogging) GD.Print($"[EventBus] Stage completed: {stageNumber}");
	}

	private void OnEnemySpawned(Node enemy, string enemyType)
	{
		if (_debugLogging) GD.Print($"[EventBus] Enemy spawned: {enemyType}");
	}

	private void OnBossSpawned(Node boss, string bossName)
	{
		if (_debugLogging) GD.Print($"[EventBus] Boss spawned: {bossName}");
	}

	private void OnWaveStarted(int waveNumber)
	{
		if (_debugLogging) GD.Print($"[EventBus] Wave started: {waveNumber}");
	}

	private void OnWaveCompleted(int waveNumber)
	{
		if (_debugLogging) GD.Print($"[EventBus] Wave completed: {waveNumber}");
	}

	private void OnItemDropped(string itemType, Vector2 position)
	{
		if (_debugLogging) GD.Print($"[EventBus] Item dropped: {itemType} at {position}");
	}

	private void OnItemCollected(string itemType, int value)
	{
		if (_debugLogging) GD.Print($"[EventBus] Item collected: {itemType} value: {value}");
	}

	private void OnInputMovement(Vector2 direction)
	{
		// Input events are typically handled by input systems
	}

	private void OnInputShoot(bool pressed)
	{
		// Input events are typically handled by input systems
	}

	private void OnInputBomb(bool pressed)
	{
		// Input events are typically handled by input systems
	}

	private void OnInputPause(bool pressed)
	{
		// Input events are typically handled by input systems
	}

	private void OnRankChanged(float newRank)
	{
		if (_debugLogging) GD.Print($"[EventBus] Rank changed to: {newRank}");
	}

	private void OnStreakChanged(int current, int maxStreak)
	{
		if (_debugLogging) GD.Print($"[EventBus] Streak changed: {current}/{maxStreak}");
	}

	private void OnEntitySpawned(Node entity, string entityType)
	{
		if (_debugLogging) GD.Print($"[EventBus] Entity spawned: {entityType}");
	}

	private void OnEntityDestroyed(Node entity, string entityType)
	{
		if (_debugLogging) GD.Print($"[EventBus] Entity destroyed: {entityType}");
	}

	// Cho Ren Sha 68K Event Handlers
	private void OnShieldGained()
	{
		if (_debugLogging) GD.Print("[EventBus] Shield gained");
	}

	private void OnShieldLost()
	{
		if (_debugLogging) GD.Print("[EventBus] Shield lost");
	}

	private void OnShieldAbsorbed()
	{
		if (_debugLogging) GD.Print("[EventBus] Shield absorbed");
	}

	private void OnWeaponPowerChanged(int newPower)
	{
		if (_debugLogging) GD.Print($"[EventBus] Weapon power changed to: {newPower}");
	}

	private void OnLoopIncremented(int newLoop)
	{
		if (_debugLogging) GD.Print($"[EventBus] Loop incremented to: {newLoop}");
	}

	private void OnLifeExtended(string reason)
	{
		if (_debugLogging) GD.Print($"[EventBus] Life extended: {reason}");
	}

	private void OnFireRateBoostActivated(float duration)
	{
		if (_debugLogging) GD.Print($"[EventBus] Fire rate boost activated for {duration} seconds");
	}

	private void OnFireRateBoostEnded()
	{
		if (_debugLogging) GD.Print("[EventBus] Fire rate boost ended");
	}

	// Visual Effects Event Handlers
	private void OnScreenShakeRequested(float intensity, float duration)
	{
		if (_debugLogging) GD.Print($"[EventBus] Screen shake requested: intensity={intensity} duration={duration}");
	}

	private void OnHitStopRequested(float duration, float scale)
	{
		if (_debugLogging) GD.Print($"[EventBus] Hit stop requested: duration={duration} scale={scale}");
	}

	private void OnFlashRequested(Color color, float duration)
	{
		if (_debugLogging) GD.Print($"[EventBus] Flash requested: color={color} duration={duration}");
	}

	private void OnExplosionRequested(Vector2 position, float size)
	{
		if (_debugLogging) GD.Print($"[EventBus] Explosion requested: position={position} size={size}");
	}

	private void OnStageTransitionRequested(int stageNumber, float duration)
	{
		if (_debugLogging) GD.Print($"[EventBus] Stage transition requested: stage={stageNumber} duration={duration}");
	}

	private void OnBackgroundChangeRequested(string backgroundType, Color tint, float ambientLighting)
	{
		if (_debugLogging) GD.Print($"[EventBus] Background change requested: type={backgroundType} tint={tint} ambient={ambientLighting}");
	}

	private void OnParticleEffectRequested(string effectName, float duration)
	{
		if (_debugLogging) GD.Print($"[EventBus] Particle effect requested: {effectName} duration={duration}");
	}

	// Audio Event Handlers
	private void OnPlaySound(string soundName, float volume)
	{
		if (_debugLogging) GD.Print($"[EventBus] Play sound: {soundName} volume={volume}");
	}

	private void OnPlayMusic(string musicName, bool fadeIn)
	{
		if (_debugLogging) GD.Print($"[EventBus] Play music: {musicName} fade_in={fadeIn}");
	}

	private void OnStopMusic(bool fadeOut)
	{
		if (_debugLogging) GD.Print($"[EventBus] Stop music: fade_out={fadeOut}");
	}

	public override void _ExitTree()
	{
		// Clean up signal connections to prevent memory leaks
		if (!_debugLogging) return;

		PlayerHit -= OnPlayerHit;
		GameOver -= OnGameOver;
		GameStarted -= OnGameStarted;
		GamePaused -= OnGamePaused;
		GameResumed -= OnGameResumed;
		LivesChanged -= OnLivesChanged;
		BombsChanged -= OnBombsChanged;
		PlayerInvincibilityStarted -= OnPlayerInvincibilityStarted;
		PlayerInvincibilityEnded -= OnPlayerInvincibilityEnded;
		BulletHitPlayer -= OnBulletHitPlayer;
		BulletHitEnemy -= OnBulletHitEnemy;
		BombUsed -= OnBombUsed;
		StageStarted -= OnStageStarted;
		StageCompleted -= OnStageCompleted;
		EnemySpawned -= OnEnemySpawned;
		BossSpawned -= OnBossSpawned;
		WaveStarted -= OnWaveStarted;
		WaveCompleted -= OnWaveCompleted;
		ItemDropped -= OnItemDropped;
		ItemCollected -= OnItemCollected;
		InputMovement -= OnInputMovement;
		InputShoot -= OnInputShoot;
		InputBomb -= OnInputBomb;
		InputPause -= OnInputPause;
		RankChanged -= OnRankChanged;
		StreakChanged -= OnStreakChanged;
		EntitySpawned -= OnEntitySpawned;
		EntityDestroyed -= OnEntityDestroyed;

		// Cho Ren Sha 68K signals
		ShieldGained -= OnShieldGained;
		ShieldLost -= OnShieldLost;
		ShieldAbsorbed -= OnShieldAbsorbed;
		WeaponPowerChanged -= OnWeaponPowerChanged;
		LoopIncremented -= OnLoopIncremented;
		LifeExtended -= OnLifeExtended;
		FireRateBoostActivated -= OnFireRateBoostActivated;
		FireRateBoostEnded -= OnFireRateBoostEnded;

		// Visual effects signals
		ScreenShakeRequested -= OnScreenShakeRequested;
		HitStopRequested -= OnHitStopRequested;
		FlashRequested -= OnFlashRequested;
		ExplosionRequested -= OnExplosionRequested;
		StageTransitionRequested -= OnStageTransitionRequested;
		BackgroundChangeRequested -= OnBackgroundChangeRequested;
		ParticleEffectRequested -= OnParticleEffectRequested;

		// Audio signals
		PlaySound -= OnPlaySound;
		PlayMusic -= OnPlayMusic;
		StopMusic -= OnStopMusic;
	}
}

