using Godot;
using System.Collections.Generic;

public partial class EntityFactory : Node
{
	// Scene refs
	private PackedScene _playerScene;
	private PackedScene _bulletScene;
	private PackedScene _enemyBulletScene;
	private PackedScene _enemyScene;

	// Safety caps
	private const int MaxEnemyBullets = 300;  // Increased from 140
	private const int MaxEnemyBulletsPerSec = 200;  // Increased from 90

	// Rate limiter
	private int _bulletRateWindowStartMs = 0;
	private int _bulletRateCount = 0;

	// Object pools
	private List<Node> _bulletPool = new();
	private List<Node> _enemyBulletPool = new();
	private int _maxPoolSize = 200;  // Increased pool size
	private float _poolCleanupTimer = 0.0f;
	private float _poolCleanupInterval = 3.0f;  // Clean pools every 3 seconds

	private Node _gameViewport;
	private Node _bulletsContainer;
	private Node _enemiesContainer;

	private EventBus _eventBus;

	public override void _Ready()
	{
		GD.Print("[EntityFactory] Entity factory initialized");
		LoadScenes();
		InitializePools();
		_eventBus = GetNodeOrNull<EventBus>("/root/EventBus");
	}

	public override void _Process(double delta)
	{
		// Pool cleanup
		_poolCleanupTimer += (float)delta;
		if (_poolCleanupTimer >= _poolCleanupInterval)
		{
			CleanupPools();
			_poolCleanupTimer = 0.0f;
		}
	}

	private async void LoadScenes()
	{
		// Wait for validator
		await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);

		var rv = GetNodeOrNull("/root/ResourceValidator");
		if (rv != null && GodotObject.IsInstanceValid(rv) && rv.HasMethod("safe_load_scene"))
		{
			_playerScene = (PackedScene)rv.Call("safe_load_scene", "res://scenes/player/Player.tscn");
			_bulletScene = (PackedScene)rv.Call("safe_load_scene", "res://scenes/bullet/Bullet.tscn");
			_enemyBulletScene = (PackedScene)rv.Call("safe_load_scene", "res://scenes/bullet/EnemyBullet.tscn");
			_enemyScene = (PackedScene)rv.Call("safe_load_scene", "res://scenes/enemy/Enemy.tscn");
		}
		else
		{
			// Fallback to direct loading
			_playerScene = GD.Load<PackedScene>("res://scenes/player/Player.tscn");
			_bulletScene = GD.Load<PackedScene>("res://scenes/bullet/Bullet.tscn");
			_enemyBulletScene = GD.Load<PackedScene>("res://scenes/bullet/EnemyBullet.tscn");
			_enemyScene = GD.Load<PackedScene>("res://scenes/enemy/Enemy.tscn");
		}

		// Validate critical scenes
		if (_playerScene == null)
			GD.PushError("[EntityFactory] Failed to load player scene");
		if (_bulletScene == null)
			GD.PushError("[EntityFactory] Failed to load bullet scene");
		if (_enemyBulletScene == null)
			GD.PushError("[EntityFactory] Failed to load enemy bullet scene");
		if (_enemyScene == null)
			GD.PushError("[EntityFactory] Failed to load enemy scene");
	}

	private void InitializePools()
	{
		// Pre-populate bullet pools
		if (_bulletScene != null)
		{
			for (int i = 0; i < 50; i++)  // Increased pool size
			{
				var bullet = _bulletScene.Instantiate();
				if (bullet != null && GodotObject.IsInstanceValid(bullet))
				{
					if (bullet is CanvasItem canvasItem)
					{
						canvasItem.Visible = false;
					}
					bullet.SetMeta("pooled", true);
					bullet.SetMeta("pool_kind", "player");
					bullet.SetMeta("pool_created_time", (long)(ulong)Time.GetTicksMsec());
					_bulletPool.Add(bullet);
				}
			}
		}

		if (_enemyBulletScene != null)
		{
			for (int i = 0; i < 100; i++)  // Larger pool for enemy bullets
			{
				var enemyBullet = _enemyBulletScene.Instantiate();
				if (enemyBullet != null && GodotObject.IsInstanceValid(enemyBullet))
				{
					if (enemyBullet is CanvasItem canvasItem)
					{
						canvasItem.Visible = false;
					}
					enemyBullet.SetMeta("pooled", true);
					enemyBullet.SetMeta("pool_kind", "enemy");
					enemyBullet.SetMeta("pool_created_time", (long)(ulong)Time.GetTicksMsec());
					_enemyBulletPool.Add(enemyBullet);
				}
			}
		}
	}

	public void SetContainers(Node gameViewportNode)
	{
		_gameViewport = gameViewportNode;
		_bulletsContainer = _gameViewport.GetNodeOrNull("Bullets");
		_enemiesContainer = _gameViewport.GetNodeOrNull("Enemies");

		if (_bulletsContainer == null)
		{
			_bulletsContainer = new Node();
			_bulletsContainer.Name = "Bullets";
			_gameViewport.CallDeferred("add_child", _bulletsContainer);
		}

		if (_enemiesContainer == null)
		{
			_enemiesContainer = new Node();
			_enemiesContainer.Name = "Enemies";
			_gameViewport.CallDeferred("add_child", _enemiesContainer);
		}
	}

	// Player Spawning
	public Node SpawnPlayer(Vector2 spawnPosition = default)
	{
		if (spawnPosition == default)
			spawnPosition = new Vector2(160, 150);

		var player = _playerScene.Instantiate();
		player.Set("position", spawnPosition);

		var container = _gameViewport ?? GetTree().CurrentScene;
		container.CallDeferred("add_child", player);

		// Setup player hurtbox
		SetupPlayerHurtbox(player);

		// Connect player signals to EventBus
		ConnectPlayerSignals(player);

		_eventBus?.EmitSignal(EventBus.SignalName.EntitySpawned, player, "player");
		return player;
	}

	private void SetupPlayerHurtbox(Node player)
	{
		var hurtbox = player.GetNodeOrNull<Area2D>("Hurtbox");
		if (hurtbox == null)
		{
			hurtbox = new Area2D();
			hurtbox.Name = "Hurtbox";
			var collisionShape = new CollisionShape2D();
			var circleShape = new CircleShape2D();
			circleShape.Radius = 6.0f;
			collisionShape.Shape = circleShape;
			hurtbox.AddChild(collisionShape);
			player.AddChild(hurtbox);
		}

		hurtbox.AddToGroup("player_hurtbox");
		hurtbox.Monitoring = true;
		hurtbox.Monitorable = true;
		hurtbox.CollisionLayer = 1;   // Player layer
		hurtbox.CollisionMask = 2;    // Enemy bullet layer
	}

	private void ConnectPlayerSignals(Node player)
	{
		if (player.HasSignal("damaged"))
		{
			player.Connect("damaged", Callable.From<int>(OnPlayerDamaged));
		}
		if (player.HasSignal("hit"))
		{
			player.Connect("hit", Callable.From(OnPlayerHit));
		}
	}

	private void OnPlayerDamaged(int amount)
	{
		_eventBus?.EmitSignal(EventBus.SignalName.PlayerDamaged, amount);
	}

	private void OnPlayerHit()
	{
		_eventBus?.EmitSignal(EventBus.SignalName.PlayerHit);
	}

	// Bullet Spawning
	public Node SpawnPlayerBullet(Vector2 spawnPosition, Vector2 direction = default, float speed = 400.0f)
	{
		if (direction == default)
			direction = Vector2.Up;

		if (_bulletScene == null)
		{
			GD.PushError("[EntityFactory] Player bullet scene not loaded");
			return null;
		}

		var bullet = GetPooledBullet(_bulletPool, _bulletScene);
		if (bullet == null || !GodotObject.IsInstanceValid(bullet))
		{
			GD.PushError("[EntityFactory] Failed to get pooled bullet for player");
			return null;
		}

		bullet.Set("position", spawnPosition);
		if (bullet.HasMethod("set"))
		{
			bullet.Set("direction", direction);
			bullet.Set("speed", speed);
		}
		bullet.Visible = true;

		var container = GetBulletContainer();
		if (container != null && GodotObject.IsInstanceValid(container))
		{
			container.CallDeferred("add_child", bullet);
		}
		else
		{
			GD.PushError("EntityFactory: No valid container found for player bullet");
			if ((bool)bullet.GetMeta("pooled", false))
			{
				bullet.Visible = false;
			}
			else
			{
				bullet.QueueFree();
			}
			return null;
		}

		ConnectBulletSignals(bullet, "player");
		if (_eventBus != null && _eventBus.HasSignal("entity_spawned"))
		{
			_eventBus.EmitSignal(EventBus.SignalName.EntitySpawned, bullet, "player_bullet");
		}
		return bullet;
	}

	// Generic bullet spawn method for testing
	public Node SpawnBullet(Vector2 spawnPosition, Vector2 direction = default, float speed = 200.0f)
	{
		// Generic bullet spawn method for testing - defaults to player bullet
		return SpawnPlayerBullet(spawnPosition, direction, speed);
	}

	public Node SpawnEnemyBullet(Vector2 spawnPosition, Vector2 direction = default, float speed = 140.0f, int damage = 1)
	{
		if (direction == default)
			direction = Vector2.Down;

		if (_enemyBulletScene == null)
		{
			GD.PushError("[EntityFactory] Enemy bullet scene not loaded");
			return null;
		}

		// Global cap to prevent runaway spawning/lockups
		var containerCheck = GetBulletContainer();
		if (containerCheck != null && GodotObject.IsInstanceValid(containerCheck) && containerCheck.GetChildCount() >= MaxEnemyBullets)
		{
			return null;
		}

		// Skip spawning during heavy hit-stop to avoid visible bullet walls
		if (Engine.TimeScale < 0.2)
		{
			return null;
		}

		// Rate limit enemy bullet spawns
		int nowMs = (int)Time.GetTicksMsec();
		if (_bulletRateWindowStartMs == 0 || nowMs - _bulletRateWindowStartMs >= 1000)
		{
			_bulletRateWindowStartMs = nowMs;
			_bulletRateCount = 0;
		}
		else
		{
			if (_bulletRateCount >= MaxEnemyBulletsPerSec)
			{
				return null;
			}
			_bulletRateCount += 1;
		}

		var bullet = GetPooledBullet(_enemyBulletPool, _enemyBulletScene);
		if (bullet == null || !GodotObject.IsInstanceValid(bullet))
		{
			GD.PushError("[EntityFactory] Failed to get pooled bullet for enemy");
			return null;
		}

		bullet.Set("position", spawnPosition);
		if (bullet.HasMethod("set"))
		{
			bullet.Set("direction", direction);
			bullet.Set("speed", speed);
			bullet.Set("damage", damage);
		}
		bullet.Visible = true;

		var container = GetBulletContainer();
		if (container != null && GodotObject.IsInstanceValid(container))
		{
			container.CallDeferred("add_child", bullet);
		}
		else
		{
			GD.PushError("EntityFactory: No valid container found for enemy bullet");
			if ((bool)bullet.GetMeta("pooled", false))
			{
				bullet.Visible = false;
			}
			else
			{
				bullet.QueueFree();
			}
			return null;
		}

		ConnectBulletSignals(bullet, "enemy");
		if (_eventBus != null && _eventBus.HasSignal("entity_spawned"))
		{
			_eventBus.EmitSignal(EventBus.SignalName.EntitySpawned, bullet, "enemy_bullet");
		}
		return bullet;
	}

	private Node GetBulletContainer()
	{
		// Try bullets_container first
		if (_bulletsContainer != null && GodotObject.IsInstanceValid(_bulletsContainer))
		{
			return _bulletsContainer;
		}

		// Try game_viewport
		if (_gameViewport != null && GodotObject.IsInstanceValid(_gameViewport))
		{
			// Try to find or create Bullets container
			var bulletsNode = _gameViewport.GetNodeOrNull("Bullets");
			if (bulletsNode != null)
			{
				_bulletsContainer = bulletsNode;
				return _bulletsContainer;
			}
			else
			{
				// Create Bullets container
				_bulletsContainer = new Node();
				_bulletsContainer.Name = "Bullets";
				_gameViewport.AddChild(_bulletsContainer);
				GD.PushWarning("[EntityFactory] Created missing 'Bullets' container under game_viewport");
				return _bulletsContainer;
			}
		}

		// Fallback: try to get current scene
		var currentScene = GetTree().CurrentScene;
		if (currentScene != null)
		{
			var bulletsNode = currentScene.GetNodeOrNull("Bullets");
			if (bulletsNode != null)
			{
				return bulletsNode;
			}
			else
			{
				// Create Bullets container in current scene
				_bulletsContainer = new Node();
				_bulletsContainer.Name = "Bullets";
				currentScene.AddChild(_bulletsContainer);
				GD.PushWarning("[EntityFactory] Created missing 'Bullets' container under current scene");
				return _bulletsContainer;
			}
		}

		GD.PushError("[EntityFactory] Failed to obtain a valid bullets container");
		return null;
	}

	private Node GetPooledBullet(List<Node> pool, PackedScene scene)
	{
		// Safety check for scene
		if (scene == null || !GodotObject.IsInstanceValid(scene))
		{
			GD.PushError("[EntityFactory] Invalid scene provided to GetPooledBullet");
			return null;
		}

		// Fast path: try to get from pool without full cleanup
		for (int i = pool.Count - 1; i >= 0; i--)
		{
			var bullet = pool[i];
			if (bullet != null && GodotObject.IsInstanceValid(bullet) && bullet.GetParent() == null)
			{
				pool.RemoveAt(i);
				return bullet;
			}
			else if (bullet == null || !GodotObject.IsInstanceValid(bullet))
			{
				// Remove invalid bullets immediately
				pool.RemoveAt(i);
			}
		}

		// Create new if pool is empty or all bullets are in use
		var newBullet = scene.Instantiate();
		if (newBullet != null && GodotObject.IsInstanceValid(newBullet))
		{
			newBullet.SetMeta("pooled", true);
			newBullet.SetMeta("pool_created_time", Time.GetTicksMsec());
			return newBullet;
		}
		else
		{
			GD.PushError("[EntityFactory] Failed to instantiate bullet from scene");
			return null;
		}
	}

	private void ConnectBulletSignals(Node bullet, string bulletType)
	{
		if (bullet == null || !GodotObject.IsInstanceValid(bullet))
		{
			return;
		}

		if (bulletType == "player")
		{
			if (bullet.HasSignal("area_entered"))
			{
				if (!bullet.IsConnected("area_entered", Callable.From<Area2D>(OnPlayerBulletHit)))
				{
					bullet.Connect("area_entered", Callable.From<Area2D>(OnPlayerBulletHit));
				}
			}
		}
		else if (bulletType == "enemy")
		{
			if (bullet.HasSignal("hit_player"))
			{
				if (!bullet.IsConnected("hit_player", Callable.From(OnEnemyBulletHitPlayer)))
				{
					bullet.Connect("hit_player", Callable.From(OnEnemyBulletHitPlayer));
				}
			}
		}
	}

	private void OnPlayerBulletHit(Area2D area)
	{
		if (area.IsInGroup("enemy"))
		{
			_eventBus?.EmitSignal(EventBus.SignalName.BulletHitEnemy, area.GlobalPosition, 2);
			_eventBus?.EmitAudio("enemy_shot", new Godot.Collections.Dictionary());
		}
	}

	private void OnEnemyBulletHitPlayer()
	{
		_eventBus?.EmitSignal(EventBus.SignalName.BulletHitPlayer, Vector2.Zero);
		_eventBus?.EmitAudio("player_hit", new Godot.Collections.Dictionary());
	}

	// Enemy Spawning
	public Node SpawnEnemy(PackedScene enemyScene, Vector2 spawnPosition, Godot.Collections.Dictionary properties = null)
	{
		properties ??= new Godot.Collections.Dictionary();
		
		var enemy = enemyScene.Instantiate();
		enemy.Set("global_position", spawnPosition);

		// Apply properties
		foreach (var key in properties.Keys)
		{
			var keyStr = key.ToString();
			var value = enemy.Get(keyStr);
			if (enemy.HasMethod("set") || value.VariantType != Variant.Type.Nil)
			{
				enemy.Set(keyStr, properties[key]);
			}
		}

		var container = _enemiesContainer ?? _gameViewport;
		container?.CallDeferred("add_child", enemy);

		ConnectEnemySignals(enemy);
		_eventBus?.EmitSignal(EventBus.SignalName.EntitySpawned, enemy, "enemy");
		_eventBus?.EmitSignal(EventBus.SignalName.EnemySpawned, enemy, properties.GetValueOrDefault("enemy_type", "enemy").ToString());
		return enemy;
	}

	private void ConnectEnemySignals(Node enemy)
	{
		if (enemy.HasSignal("killed"))
		{
			if (!enemy.IsConnected("killed", Callable.From<int, string>(OnEnemyKilled)))
			{
				enemy.Connect("killed", Callable.From<int, string>(OnEnemyKilled));
			}
		}
		if (enemy.HasSignal("hit_player"))
		{
			if (!enemy.IsConnected("hit_player", Callable.From(OnEnemyHitPlayer)))
			{
				enemy.Connect("hit_player", Callable.From(OnEnemyHitPlayer));
			}
		}
	}

	private void OnEnemyKilled(int points, string enemyType)
	{
		_eventBus?.EmitEnemyKill(points, Vector2.Zero, enemyType);
		_eventBus?.EmitAudio("enemy_death", new Godot.Collections.Dictionary());
	}

	private void OnEnemyHitPlayer()
	{
		_eventBus?.EmitSignal(EventBus.SignalName.PlayerHit);
		_eventBus?.EmitAudio("player_hit", new Godot.Collections.Dictionary());
	}

	// Boss Spawning
	public Node SpawnBoss(PackedScene bossScene, Vector2 spawnPosition, Godot.Collections.Dictionary properties = null)
	{
		properties ??= new Godot.Collections.Dictionary();

		var boss = bossScene.Instantiate();
		boss.Set("global_position", spawnPosition);

		// Apply properties
		foreach (var key in properties.Keys)
		{
			var keyStr = key.ToString();
			var value = boss.Get(keyStr);
			if (boss.HasMethod("set") || value.VariantType != Variant.Type.Nil)
			{
				boss.Set(keyStr, properties[key]);
			}
		}

		var container = _enemiesContainer ?? _gameViewport;
		container?.CallDeferred("add_child", boss);

		ConnectBossSignals(boss);
		_eventBus?.EmitSignal(EventBus.SignalName.EntitySpawned, boss, "boss");
		_eventBus?.EmitSignal(EventBus.SignalName.BossSpawned, boss, properties.GetValueOrDefault("boss_name", "boss").ToString());
		return boss;
	}

	private void ConnectBossSignals(Node boss)
	{
		if (boss.HasSignal("defeated"))
		{
			if (!boss.IsConnected("defeated", Callable.From(OnBossDefeated)))
			{
				boss.Connect("defeated", Callable.From(OnBossDefeated));
			}
		}
		else if (boss.HasSignal("killed"))
		{
			if (!boss.IsConnected("killed", Callable.From(OnBossDefeated)))
			{
				boss.Connect("killed", Callable.From(OnBossDefeated));
			}
		}
		if (boss.HasSignal("hit_player"))
		{
			if (!boss.IsConnected("hit_player", Callable.From(OnBossHitPlayer)))
			{
				boss.Connect("hit_player", Callable.From(OnBossHitPlayer));
			}
		}
	}

	private void OnBossDefeated()
	{
		_eventBus?.EmitBossDefeat("boss", 10000);
		_eventBus?.EmitAudio("enemy_death", new Godot.Collections.Dictionary());
	}

	private void OnBossHitPlayer()
	{
		_eventBus?.EmitSignal(EventBus.SignalName.PlayerHit);
		_eventBus?.EmitAudio("player_hit", new Godot.Collections.Dictionary());
	}

	// Cleanup
	public void DestroyEntity(Node entity)
	{
		if (entity == null || !GodotObject.IsInstanceValid(entity))
		{
			return;
		}

		if ((bool)entity.GetMeta("pooled", false))
		{
			entity.Visible = false;
			// Safely detach from parent so pooled objects are eligible for reuse
			var parent = entity.GetParent();
			if (parent != null && GodotObject.IsInstanceValid(parent))
			{
				parent.RemoveChild(entity);
			}
			// Return to the appropriate pool if below max size
			string kind = entity.GetMeta("pool_kind", "").ToString();
			if (kind == "player")
			{
				if (_bulletPool.Count < _maxPoolSize)
				{
					_bulletPool.Add(entity);
				}
			}
			else if (kind == "enemy")
			{
				if (_enemyBulletPool.Count < _maxPoolSize)
				{
					_enemyBulletPool.Add(entity);
				}
			}
			// Leave instance alive (not freed) so pooling can reuse it
		}
		else
		{
			entity.QueueFree();
		}

		_eventBus?.EmitSignal(EventBus.SignalName.EntityDestroyed, entity, "entity");
	}

	private void CleanupPools()
	{
		// Clean up invalid entries in pools to prevent memory leaks
		long currentTime = Time.GetTicksMsec();
		long maxAge = 30000;  // 30 seconds

		// Clean player bullet pool
		for (int i = _bulletPool.Count - 1; i >= 0; i--)
		{
			var bullet = _bulletPool[i];
			if (bullet == null || !GodotObject.IsInstanceValid(bullet))
			{
				_bulletPool.RemoveAt(i);
			}
			else if ((long)bullet.GetMeta("pool_created_time", 0L) + maxAge < currentTime)
			{
				// Remove old bullets to prevent memory buildup
				bullet.QueueFree();
				_bulletPool.RemoveAt(i);
			}
		}

		// Clean enemy bullet pool
		for (int i = _enemyBulletPool.Count - 1; i >= 0; i--)
		{
			var bullet = _enemyBulletPool[i];
			if (bullet == null || !GodotObject.IsInstanceValid(bullet))
			{
				_enemyBulletPool.RemoveAt(i);
			}
			else if ((long)bullet.GetMeta("pool_created_time", 0L) + maxAge < currentTime)
			{
				// Remove old bullets to prevent memory buildup
				bullet.QueueFree();
				_enemyBulletPool.RemoveAt(i);
			}
		}
	}

	public void CleanupAllEntities()
	{
		// Clean up all bullets
		var allBullets = new List<Node>();
		allBullets.AddRange(GetTree().GetNodesInGroup("player_bullet"));
		allBullets.AddRange(GetTree().GetNodesInGroup("enemy_bullet"));
		
		foreach (var bullet in allBullets)
		{
			if (bullet != null && GodotObject.IsInstanceValid(bullet))
			{
				DisconnectBulletSignals(bullet);
				DestroyEntity(bullet);
			}
		}

		// Clean up all enemies
		var allEnemies = GetTree().GetNodesInGroup("enemy");
		foreach (Node enemy in allEnemies)
		{
			if (enemy != null && GodotObject.IsInstanceValid(enemy))
			{
				DisconnectEnemySignals(enemy);
				DestroyEntity(enemy);
			}
		}

		// Clean up pools
		CleanupPools();
	}

	private void DisconnectBulletSignals(Node bullet)
	{
		// Disconnect bullet signals to prevent memory leaks
		if (bullet == null || !GodotObject.IsInstanceValid(bullet))
		{
			return;
		}

		// Safely disconnect player bullet signals
		if (bullet.HasSignal("area_entered"))
		{
			if (bullet.IsConnected("area_entered", Callable.From<Area2D>(OnPlayerBulletHit)))
			{
				bullet.Disconnect("area_entered", Callable.From<Area2D>(OnPlayerBulletHit));
			}
		}

		// Safely disconnect enemy bullet signals
		if (bullet.HasSignal("hit_player"))
		{
			if (bullet.IsConnected("hit_player", Callable.From(OnEnemyBulletHitPlayer)))
			{
				bullet.Disconnect("hit_player", Callable.From(OnEnemyBulletHitPlayer));
			}
		}
	}

	private void DisconnectEnemySignals(Node enemy)
	{
		// Disconnect enemy signals to prevent memory leaks
		if (enemy == null || !GodotObject.IsInstanceValid(enemy))
		{
			return;
		}

		if (enemy.HasSignal("killed") && enemy.IsConnected("killed", Callable.From<int, string>(OnEnemyKilled)))
		{
			enemy.Disconnect("killed", Callable.From<int, string>(OnEnemyKilled));
		}

		if (enemy.HasSignal("hit_player") && enemy.IsConnected("hit_player", Callable.From(OnEnemyHitPlayer)))
		{
			enemy.Disconnect("hit_player", Callable.From(OnEnemyHitPlayer));
		}
	}
}

