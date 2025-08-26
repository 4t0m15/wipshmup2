extends Area2D

@export var value: int = 100
@export var fall_speed: float = 80.0
@export var sprite_target_height_px: float = 8.0

var _collected: bool = false

func _ready() -> void:
	add_to_group("item")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	if has_node("VisibleOnScreenNotifier2D"):
		$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)
	else:
		var vsn := VisibleOnScreenNotifier2D.new()
		add_child(vsn)
		vsn.screen_exited.connect(_on_screen_exited)
	# Visuals
	if not has_node("Sprite2D"):
		var spr := Sprite2D.new()
		add_child(spr)
	if not has_node("CollisionShape2D"):
		var cs := CollisionShape2D.new()
		cs.shape = CircleShape2D.new()
		(cs.shape as CircleShape2D).radius = 4.0
		add_child(cs)
	# Size sprite
	var spr2 := get_node_or_null("Sprite2D") as Sprite2D
	if spr2:
		# Use player bullet sprite as placeholder if available
		# Otherwise just scale down
		spr2.scale = Vector2(0.5, 0.5)
	# Enable monitoring deferred to avoid state change during query flush
	set_deferred("monitoring", true)

func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta
	position = position.round()

func _collect() -> void:
	if _collected:
		return
	_collected = true
	# Score
	var main := _find_main()
	if main and main.has_method("add_score"):
		main.add_score(max(0, value))
	# Medal chain progression
	var idm := get_node_or_null("/root/ItemDropManager")
	if idm and idm.has_method("on_medal_collected"):
		idm.on_medal_collected()
		# Also update HUD immediately if signal dispatch is delayed
		if is_instance_valid(get_tree().current_scene):
			var hud := get_tree().current_scene.get_node_or_null("HUD")
			if hud:
				hud.call_deferred("set_medal_value", max(100, value))
	# Sparkle effect
	_spawn_sparkle()
	_play_pickup_ping()
	# Rank: medal pickup slightly increases rank
	var rm := get_node_or_null("/root/RankManager")
	if rm and rm.has_method("on_item_picked"):
		rm.on_item_picked("medal", value >= 1000)
	queue_free()

func _spawn_sparkle() -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2.ZERO
	p.one_shot = true
	p.lifetime = 0.35
	p.amount = 24
	p.emitting = true
	# Emit upwards
	p.direction = Vector2.UP
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 120.0
	p.scale_amount_min = 0.4
	p.scale_amount_max = 0.8
	p.gravity = Vector2(0, 120)
	p.color = Color(1.0, 0.9, 0.4)
	add_child(p)
	await get_tree().create_timer(0.5, false).timeout
	if is_instance_valid(p):
		p.queue_free()

func _play_pickup_ping() -> void:
	var player := AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 44100
	gen.buffer_length = 0.1
	player.stream = gen
	add_child(player)
	player.play()
	await get_tree().process_frame
	var pb := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb:
		var sr := gen.mix_rate
		var frames := int(sr * 0.06)
		for i in frames:
			var t := float(i) / float(sr)
			var v := sin(TAU * 1200.0 * t) * 0.2
			pb.push_frame(Vector2(v, v))
	await get_tree().create_timer(0.2, false).timeout
	if is_instance_valid(player):
		player.queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		_collect()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_collect()

func _on_screen_exited() -> void:
	if _collected:
		return
	var idm := get_node_or_null("/root/ItemDropManager")
	if idm and idm.has_method("on_medal_missed"):
		idm.on_medal_missed()
	queue_free()

func _find_main() -> Node:
	var root := get_tree().current_scene
	return root


