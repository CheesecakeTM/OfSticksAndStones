class_name Menu
extends Control


func play():
	get_tree().change_scene_to_file("res://scenes/world/main.tscn")


func quit():
	get_tree().quit()
