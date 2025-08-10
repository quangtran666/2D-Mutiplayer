extends Node

var player_scene: PackedScene = preload("res://entities/player/player.tscn")
var enemy_scene: PackedScene = preload("res://entities/enemy/enemy.tscn")

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var player_spawn_position: Marker2D = $PlayerSpawnPosition

func _ready() -> void:
	multiplayer_spawner.spawn_function = func (data: Variant) -> Node:
		var player := player_scene.instantiate() as Player
		player.name = str(data.peer_id)
		player.input_multiplayer_authority = data.peer_id
		player.global_position = player_spawn_position.global_position
		return player

	peer_ready.rpc_id(1)

	if is_multiplayer_authority():
		var enemy = enemy_scene.instantiate() as Enemy
		enemy.position = Vector2.ONE * 200
		add_child(enemy)

@rpc("any_peer", "call_local", "reliable")
func peer_ready() -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	multiplayer_spawner.spawn({ "peer_id": sender_id })
