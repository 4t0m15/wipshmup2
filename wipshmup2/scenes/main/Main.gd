extends Node2D

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy/Enemy.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const STAGE_CONTROLLER_SCRIPT: Script = preload("res://scripts/StageController.gd")

var score: int = 0
var game_over: bool = false
var player: CharacterBody2D
var stage_controller: Node

func _ready() -> void:
	# Start in windowed mode; fullscreen can cause issues on some platforms/drivers
	# Use Command+F (macOS) or Alt+Enter (others) to toggle fullscreen from the editor.
	add_to_group("game")
	_spawn_player()
	# Use StageController instead of random spawns
	stage_controller = STAGE_CONTROLLER_SCRIPT.new()
	add_child(stage_controller)
	stage_controller.enemy_killed.connect(_on_enemy_killed)
	stage_controller.start_run()
	_update_score_label()
	$CanvasLayer/GameOverLabel.visible = false

func _process(_delta: float) -> void:
	if game_over and Input.is_action_just_pressed("ui_accept"):
		get_tree().reload_current_scene()

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	var rect := get_viewport().get_visible_rect()
	player.global_position = Vector2(rect.size.x / 2.0, rect.size.y - 80.0)
	player.hit.connect(_on_player_hit)
	add_child(player)

func _on_spawn_timer_timeout() -> void:
	# Disabled: StageController handles enemy spawns
	pass

func _on_enemy_killed(points: int) -> void:
	score += points
	_update_score_label()

func _on_enemy_hit_player() -> void:
	_on_player_hit()

func _on_player_hit() -> void:
	if game_over:
		return
	game_over = true
	$SpawnTimer.stop()
	$CanvasLayer/GameOverLabel.visible = true

func _update_score_label() -> void:
	$CanvasLayer/ScoreLabel.text = "Score: %d" % score


