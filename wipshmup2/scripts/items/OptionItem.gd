extends Area2D

@export var fall_speed: float = 80.0

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
	if not has_node("Sprite2D"):
		var spr := Sprite2D.new()
		add_child(spr)
	if not has_node("CollisionShape2D"):
		var cs := CollisionShape2D.new()
		cs.shape = CircleShape2D.new()
		(cs.shape as CircleShape2D).radius = 6.0
		add_child(cs)
	# Enable monitoring deferred to avoid state change during query flush
	set_deferred("monitoring", true)

func _physics_process(delta: float) -> void:
	_apply_magnet(delta)
	position.y += fall_speed * delta
	position = position.round()

func _apply_magnet(delta: float) -> void:
	var root := get_tree().current_scene
	if not root:
		return
	var players := root.get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var p := players[0] as Node2D
	if not p:
		return
	var to_player := (p.global_position - global_position)
	var dist := to_player.length()
	if dist < 40.0:
		global_position += to_player.normalized() * min(180.0, 60.0 + (40.0 - dist) * 6.0) * delta

func _collect() -> void:
	if _collected:
		return
	_collected = true
	var root := get_tree().current_scene
	if root:
		var player_nodes := root.get_tree().get_nodes_in_group("player")
		if player_nodes.size() > 0:
			var p := player_nodes[0]
			if p and p.has_method("apply_option_item"):
				p.apply_option_item()
	var rm := get_node_or_null("/root/RankManager")
	if rm and rm.has_method("on_item_picked"):
		rm.on_item_picked("option", true)
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		_collect()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_collect()

func _on_screen_exited() -> void:
	queue_free()


