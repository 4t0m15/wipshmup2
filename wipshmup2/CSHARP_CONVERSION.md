# Quick Conversion Patterns

## Syntax

- `func _ready() -> void:` → `public override void _Ready()`
- `func _process(delta: float) -> void:` → `public override void _Process(double delta)`
- `func _physics_process(delta: float) -> void:` → `public override void _PhysicsProcess(double delta)`
- `@export var speed: float = 100.0` → `[Export] public float Speed { get; set; } = 100.0f;`
- `@onready var sprite = $Sprite2D` → Cache in `_Ready()`: `_sprite = GetNode<Sprite2D>("Sprite2D");`
- `signal player_died` → `[Signal] public delegate void PlayerDiedEventHandler();`
- `player_died.emit()` → `EmitSignal(SignalName.PlayerDied);`
- `player_died.emit(arg1, arg2)` → `EmitSignal(SignalName.PlayerDied, arg1, arg2);`
- `signal.connect(method)` → `signal += Method;` or `Connect(SignalName.X, Callable.From(Method))`
- `get_node("Path")` → `GetNode<Type>("Path")`
- `get_node_or_null("Path")` → `GetNodeOrNull<Type>("Path")`
- `randf()` → `GD.Randf()`
- `randi()` → `GD.Randi()`
- `print()` → `GD.Print()`
- `push_error()` → `GD.PushError()`
- `push_warning()` → `GD.PushWarning()`
- `queue_free()` → `QueueFree()`
- `is_instance_valid()` → `IsInstanceValid()`

## Types

- `int` → `int`
- `float` → `float` (add `f` suffix: `1.0f`)
- `bool` → `bool`
- `String` → `string`
- `Array[Type]` → `List<Type>` or `Godot.Collections.Array<Type>`
- `Dictionary` → `Dictionary<TKey, TValue>` or `Godot.Collections.Dictionary<TKey, TValue>`
- `Vector2` → `Vector2` (same)
- `Vector3` → `Vector3` (same)
- `Color` → `Color` (same)
- `Rect2` → `Rect2` (same)
- `PackedScene` → `PackedScene` (same)
- `Node` → `Node` (same)
- `Node2D` → `Node2D` (same)

## Common Issues

- `_process` takes `double delta` not `float`
- `_physics_process` takes `double delta` not `float`
- C# method names are PascalCase: `_Ready()`, `_Process()`, `_PhysicsProcess()`
- Floats need `f`: `100.0f`, `Mathf.PI`
- No `match` statement - use `switch`
- Enums strongly typed - cast with `(int)` if needed
- `null` checks are strict - use `IsInstanceValid()` for nodes
- Properties use PascalCase: `node.Visible` not `node.visible`

## String Formatting

```csharp
// GDScript:
var text = "Score: %d" % score
var text = "Player at %v" % position

// C#:
string text = $"Score: {score}";
string text = $"Player at {position}";
```

## Arrays and Collections

```csharp
// GDScript:
var enemies: Array[Enemy] = []
enemies.append(enemy)
enemies.size()

// C# with List:
private List<Enemy> _enemies = new();
_enemies.Add(enemy);
_enemies.Count

// C# with Godot.Collections.Array:
private Godot.Collections.Array<Enemy> _enemies = new();
_enemies.Add(enemy);
_enemies.Count
```

## Dictionaries

```csharp
// GDScript:
var data: Dictionary = {}
data["key"] = "value"
data.has("key")
data.get("key", "default")

// C#:
private Dictionary<string, string> _data = new();
_data["key"] = "value";
_data.ContainsKey("key")
_data.TryGetValue("key", out string value) ? value : "default";
// Or simpler:
_data.GetValueOrDefault("key", "default");
```

## Signals - Full Pattern

```csharp
// GDScript:
signal health_changed(new_health: int, old_health: int)

func take_damage(amount: int) -> void:
    health -= amount
    health_changed.emit(health, health + amount)

func _ready() -> void:
    health_changed.connect(_on_health_changed)

func _on_health_changed(new_health: int, old_health: int) -> void:
    print("Health: ", new_health)

// C#:
[Signal]
public delegate void HealthChangedEventHandler(int newHealth, int oldHealth);

public void TakeDamage(int amount)
{
    int oldHealth = _health;
    _health -= amount;
    EmitSignal(SignalName.HealthChanged, _health, oldHealth);
}

public override void _Ready()
{
    HealthChanged += OnHealthChanged;
}

private void OnHealthChanged(int newHealth, int oldHealth)
{
    GD.Print($"Health: {newHealth}");
}
```

## Node Access Patterns

```csharp
// GDScript:
@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
var player = get_node("/root/Main/Player")

// C#:
private Sprite2D _sprite;
private CollisionShape2D _collision;

public override void _Ready()
{
    _sprite = GetNode<Sprite2D>("Sprite2D");
    _collision = GetNode<CollisionShape2D>("CollisionShape2D");
    
    var player = GetNode<Player>("/root/Main/Player");
}

// Safe access:
var player = GetNodeOrNull<Player>("/root/Main/Player");
if (player != null)
{
    // Use player
}
```

## Export Variables

```csharp
// GDScript:
@export var speed: float = 100.0
@export var max_health: int = 100
@export var enemy_name: String = "Enemy"
@export_range(0, 10) var difficulty: int = 5
@export var texture: Texture2D

// C#:
[Export] public float Speed { get; set; } = 100.0f;
[Export] public int MaxHealth { get; set; } = 100;
[Export] public string EnemyName { get; set; } = "Enemy";
[Export(PropertyHint.Range, "0,10")] public int Difficulty { get; set; } = 5;
[Export] public Texture2D Texture { get; set; }
```

## Property Setters with Signals

```csharp
// GDScript:
var lives: int = 3:
    set(value):
        lives = max(0, value)
        EventBus.lives_changed.emit(lives)

// C#:
private int _lives = 3;

[Export]
public int Lives
{
    get => _lives;
    set
    {
        _lives = Mathf.Max(0, value);
        GetNode<EventBus>("/root/EventBus").EmitSignal(EventBus.SignalName.LivesChanged, _lives);
    }
}
```

## Math Functions

```csharp
// GDScript:
var angle = sin(time)
var dist = sqrt(x * x + y * y)
var clamped = clamp(value, 0, 100)
var rounded = round(value)
var abs_val = abs(value)

// C#:
float angle = Mathf.Sin(time);
float dist = Mathf.Sqrt(x * x + y * y);
float clamped = Mathf.Clamp(value, 0.0f, 100.0f);
float rounded = Mathf.Round(value);
float absVal = Mathf.Abs(value);

// Integer versions:
int clampedInt = Mathf.Clamp(value, 0, 100);
// Note: Use Mathf.Max/Min for integers too
```

## Control Flow

```csharp
// GDScript match → C# switch:
match enemy_type:
    "fighter":
        spawn_fighter()
    "tank":
        spawn_tank()
    _:
        spawn_default()

// C#:
switch (enemyType)
{
    case "fighter":
        SpawnFighter();
        break;
    case "tank":
        SpawnTank();
        break;
    default:
        SpawnDefault();
        break;
}

// Or with expressions (C# 8+):
var result = enemyType switch
{
    "fighter" => SpawnFighter(),
    "tank" => SpawnTank(),
    _ => SpawnDefault()
};
```

## Loops

```csharp
// GDScript:
for i in range(10):
    print(i)

for enemy in enemies:
    enemy.take_damage(10)

// C#:
for (int i = 0; i < 10; i++)
{
    GD.Print(i);
}

foreach (var enemy in _enemies)
{
    enemy.TakeDamage(10);
}
```

## Classes and Inheritance

```csharp
// GDScript:
class_name Enemy extends Area2D

// C#:
public partial class Enemy : Area2D
{
    // Note: 'partial' is required for Godot 4 C#
}
```

## Resource Loading

```csharp
// GDScript:
var scene = preload("res://scenes/enemy.tscn")
var texture = load("res://assets/enemy.png")

// C#:
private PackedScene _scene = GD.Load<PackedScene>("res://scenes/enemy.tscn");
private Texture2D _texture = GD.Load<Texture2D>("res://assets/enemy.png");

// Or load at runtime:
var scene = GD.Load<PackedScene>("res://scenes/enemy.tscn");
```

## Instantiation

```csharp
// GDScript:
var instance = scene.instantiate()
add_child(instance)

// C#:
var instance = _scene.Instantiate();
AddChild(instance);

// Type-safe:
var instance = _scene.Instantiate<Enemy>();
AddChild(instance);
```

## Timers

```csharp
// GDScript:
await get_tree().create_timer(2.0).timeout

// C#:
await ToSignal(GetTree().CreateTimer(2.0), SceneTreeTimer.SignalName.Timeout);
```

## Groups

```csharp
// GDScript:
add_to_group("enemies")
get_tree().get_nodes_in_group("enemies")

// C#:
AddToGroup("enemies");
GetTree().GetNodesInGroup("enemies");

// Type-safe access:
var enemies = GetTree().GetNodesInGroup("enemies").Cast<Enemy>();
```

## Common Gotchas

1. **Partial class required**: All C# scripts must use `partial` keyword
2. **SignalName enum**: Access signals via `SignalName.MySignal` not string
3. **PropertyName enum**: Similar for property names
4. **Callable.From()**: May need for signal connections with parameters
5. **await**: Requires `async` method and different syntax than GDScript
6. **null vs IsInstanceValid**: Use `IsInstanceValid()` for nodes that might be freed
7. **File paths**: Still use forward slashes `res://` not backslashes
8. **Case sensitivity**: C# is case-sensitive everywhere

## Quick Migration Checklist

For each file:
- [ ] Add `using Godot;` at top
- [ ] Add `using System.Collections.Generic;` if using List/Dictionary
- [ ] Change class to `public partial class`
- [ ] Convert all method signatures to PascalCase
- [ ] Add `f` suffix to all float literals
- [ ] Change `delta: float` to `delta: double`
- [ ] Convert signals to delegate declarations
- [ ] Update signal emissions to `EmitSignal()`
- [ ] Convert `@export` to `[Export]`
- [ ] Convert `@onready` to private fields set in `_Ready()`
- [ ] Update string formatting to use `$""` interpolation
- [ ] Change `match` to `switch`
- [ ] Update math functions to `Mathf.*`
- [ ] Update random functions to `GD.Randf()` / `GD.Randi()`
- [ ] Test compilation
- [ ] Delete original `.gd` file

