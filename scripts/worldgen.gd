extends Node3D

# Constants for terrain generation
const CHUNK_SIZE = 16  # Size of one chunk (in blocks)
const CHUNK_HEIGHT = 16  # Height of one chunk (in blocks)
const VIEW_DISTANCE = 2  # Number of chunks to render around the player
const BLOCK_SIZE = 1.0  # Size of one block

# Player tracking and chunk storage
var player_chunk_position = Vector3.ZERO
var active_chunks = {}

func _ready():
	update_visible_chunks()

func _process(delta):
	var new_chunk_position = get_player_chunk_position()
	if new_chunk_position != player_chunk_position:
		player_chunk_position = new_chunk_position
		update_visible_chunks()

# Get the player's current chunk position
func get_player_chunk_position() -> Vector3:
	var player_pos = $Player.global_position
	return Vector3(
		floor(player_pos.x / (CHUNK_SIZE * BLOCK_SIZE)),
		0,
		floor(player_pos.z / (CHUNK_SIZE * BLOCK_SIZE))
	)

# Update the visible chunks based on player's position
func update_visible_chunks():
	var visible_chunks = []

	for x_offset in range(-VIEW_DISTANCE, VIEW_DISTANCE + 1):
		for z_offset in range(-VIEW_DISTANCE, VIEW_DISTANCE + 1):
			var chunk_pos = player_chunk_position + Vector3(x_offset, 0, z_offset)
			visible_chunks.append(chunk_pos)
			if chunk_pos not in active_chunks:
				load_chunk(chunk_pos)

	# Unload chunks no longer visible
	for chunk_pos in active_chunks.keys():
		if chunk_pos not in visible_chunks:
			unload_chunk(chunk_pos)

# Generate a chunk and add it to the scene
func load_chunk(chunk_pos: Vector3):
	var chunk = MeshInstance3D.new()
	chunk.mesh = generate_chunk_mesh(chunk_pos)
	chunk.translation = Vector3(
		chunk_pos.x * CHUNK_SIZE * BLOCK_SIZE,
		0,
		chunk_pos.z * CHUNK_SIZE * BLOCK_SIZE
	)
	add_child(chunk)
	active_chunks[chunk_pos] = chunk

# Remove a chunk and free its memory
func unload_chunk(chunk_pos: Vector3):
	if chunk_pos in active_chunks:
		active_chunks[chunk_pos].queue_free()
		active_chunks.erase(chunk_pos)

# Generate a simple chunk mesh
func generate_chunk_mesh(chunk_pos: Vector3) -> ArrayMesh:
	var mesh = ArrayMesh.new()

	var vertices = PackedVector3Array()
	var indices = []
	var uvs = PackedVector2Array()

	# Simple flat terrain: blocks at height 1
	for x in range(CHUNK_SIZE):
		for z in range(CHUNK_SIZE):
			var height = 1  # Fixed height for simplicity
			add_block_mesh(vertices, indices, uvs, Vector3(x, height, z))

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_TEX_UV] = uvs

	if vertices.size() > 0:
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	return mesh

# Add a cube to the mesh
func add_block_mesh(vertices: PackedVector3Array, indices: Array, uvs: PackedVector2Array, block_pos: Vector3):
	var s = BLOCK_SIZE / 2.0
	var base_index = vertices.size()

	# Cube vertices
	var v = [
		Vector3(-s, -s, -s) + block_pos,
		Vector3(s, -s, -s) + block_pos,
		Vector3(s, s, -s) + block_pos,
		Vector3(-s, s, -s) + block_pos,
		Vector3(-s, -s, s) + block_pos,
		Vector3(s, -s, s) + block_pos,
		Vector3(s, s, s) + block_pos,
		Vector3(-s, s, s) + block_pos
	]
	vertices.append_array(v)

	# Cube indices (2 triangles per face)
	var i = [
		base_index + 0, base_index + 1, base_index + 2, base_index + 2, base_index + 3, base_index + 0,  # Front
		base_index + 4, base_index + 5, base_index + 6, base_index + 6, base_index + 7, base_index + 4,  # Back
		base_index + 0, base_index + 4, base_index + 7, base_index + 7, base_index + 3, base_index + 0,  # Left
		base_index + 1, base_index + 5, base_index + 6, base_index + 6, base_index + 2, base_index + 1,  # Right
		base_index + 3, base_index + 2, base_index + 6, base_index + 6, base_index + 7, base_index + 3,  # Top
		base_index + 0, base_index + 1, base_index + 5, base_index + 5, base_index + 4, base_index + 0   # Bottom
	]
	indices.append_array(i)

	# Cube UVs (placeholder)
	for _i in range(8):
		uvs.append(Vector2(0, 0))
