extends Node2D
class_name CustomParallaxLayer

@export var texture: Texture2D
@export var scroll_scale: Vector2 = Vector2(1.0, 1.0)


var _texture_rect: TextureRect

var _current_offset: Vector2 = Vector2.ZERO
var _shader_material: ShaderMaterial



func _ready():

	_texture_rect = TextureRect.new()

	_texture_rect.texture = texture

	_texture_rect.stretch_mode = TextureRect.STRETCH_TILE

	# Create a simple shader to apply UV offset for scrolling since TextureRect has no tile_offset property.
	var shader := Shader.new()
	shader.code = """
		shader_type canvas_item;
		uniform vec2 uv_offset = vec2(0.0, 0.0);
		void fragment() {
			vec2 uv = UV + uv_offset;
			COLOR = texture(TEXTURE, uv);
		}
	"""
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = shader
	_texture_rect.material = _shader_material


	# Make the TextureRect large enough to not have visible edges when scrolling
	var viewport_size = get_viewport().get_visible_rect().size
	_texture_rect.size = viewport_size * 4
	_texture_rect.position = -viewport_size * 1.5

	add_child(_texture_rect)



func update_scroll(scroll_delta: Vector2):

	var scaled_delta = scroll_delta * scroll_scale

	_current_offset += scaled_delta


	# Apply UV offset via shader (convert pixel offset to normalized UV space using rect size to reduce drift speed)
	if _shader_material and _texture_rect:
		var size_vec = _texture_rect.size
		if size_vec.x != 0.0 and size_vec.y != 0.0:
			var uv_offset = Vector2(_current_offset.x / size_vec.x, _current_offset.y / size_vec.y) * -1.0
			_shader_material.set("shader_parameter/uv_offset", uv_offset)



func reset_scroll():

	_current_offset = Vector2.ZERO

	if _shader_material:
		_shader_material.set("shader_parameter/uv_offset", Vector2.ZERO)
