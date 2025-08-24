extends Control

var main_scene: PackedScene = preload("res://main.tscn")

@onready var single_player_button: Button = $VBoxContainer/SinglePlayerButton
@onready var multiplayer_button: Button = $VBoxContainer/MultiplayerButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var options_button: Button = $VBoxContainer/OptionsButton

@onready var multiplayer_menu_scene: PackedScene = load("res://ui/multiplayer_menu/multiplayer_menu.tscn")
var options_menu: PackedScene = preload("res://ui/options_menu/options_menu.tscn")

func _ready() -> void:
    single_player_button.pressed.connect(_on_single_player_pressed)
    multiplayer_button.pressed.connect(_on_multiplayer_pressed)
    quit_button.pressed.connect(_on_quit_pressed)
    options_button.pressed.connect(_on_options_pressed)
    UIAudioManager.register_buttons([single_player_button, multiplayer_button, quit_button, options_button])

func _on_single_player_pressed() -> void:
    get_tree().change_scene_to_packed(main_scene)

func _on_multiplayer_pressed() -> void:
    get_tree().change_scene_to_packed(multiplayer_menu_scene)

func _on_quit_pressed() -> void:
    get_tree().quit()

func _on_options_pressed() -> void:
    var options_menu_instance := options_menu.instantiate()
    add_child(options_menu_instance)