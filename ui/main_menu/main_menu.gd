extends Control

var main_scene: PackedScene = preload("res://main.tscn")

@onready var single_player_button: Button = $VBoxContainer/SinglePlayerButton
@onready var multiplayer_button: Button = $VBoxContainer/MultiplayerButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

@onready var multiplayer_menu_scene: PackedScene = load("res://ui/multiplayer_menu/multiplayer_menu.tscn")

func _ready() -> void:
    single_player_button.pressed.connect(_on_single_player_pressed)
    multiplayer_button.pressed.connect(_on_multiplayer_pressed)
    quit_button.pressed.connect(_on_quit_pressed)

func _on_single_player_pressed() -> void:
    get_tree().change_scene_to_packed(main_scene)

func _on_multiplayer_pressed() -> void:
    get_tree().change_scene_to_packed(multiplayer_menu_scene)

func _on_quit_pressed() -> void:
    get_tree().quit()