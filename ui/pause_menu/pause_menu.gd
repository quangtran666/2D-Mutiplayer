class_name PauseMenu
extends CanvasLayer

signal quit_requested

@onready var resume_button: Button = %ResumeButton
@onready var quit_button: Button = %QuitButton
@onready var options_button: Button = %OptionsButton

var current_paused_peer: int = -1
var options_menu: PackedScene = preload("res://ui/options_menu/options_menu.tscn")


func _ready() -> void:
    resume_button.pressed.connect(_on_resume_pressed)
    quit_button.pressed.connect(_on_quit_pressed)
    options_button.pressed.connect(_on_options_pressed)
    UIAudioManager.register_buttons([resume_button, quit_button, options_button])

    if is_multiplayer_authority():
        multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        if get_tree().paused:
            request_unpause.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER)
        else:
            request_pause.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER)
        get_viewport().set_input_as_handled()

@rpc("any_peer", "call_local", "reliable")
func request_pause() -> void:
    if current_paused_peer > -1:
        return
    pause.rpc(multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_local", "reliable")
func request_unpause() -> void:
    if current_paused_peer != multiplayer.get_remote_sender_id():
        return
    unpause.rpc()

@rpc("authority", "call_local", "reliable")
func pause(paused_peer: int) -> void:
    get_tree().paused = true
    visible = true
    current_paused_peer = paused_peer
    var is_controlling_player: bool = multiplayer.get_unique_id() == current_paused_peer
    resume_button.disabled = !is_controlling_player
    options_button.disabled = !is_controlling_player

@rpc("authority", "call_local", "reliable")
func unpause() -> void:
    get_tree().paused = false
    visible = false
    current_paused_peer = -1

func _on_resume_pressed() -> void:
    request_unpause.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER)

func _on_quit_pressed() -> void:
    quit_requested.emit()

func _on_peer_disconnected(peer_id: int) -> void:
    if current_paused_peer == peer_id:
        unpause.rpc()

func _on_options_pressed() -> void:
    var options_menu_instance := options_menu.instantiate()
    add_child(options_menu_instance)