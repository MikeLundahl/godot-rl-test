class_name Enemy
extends CharacterBody3D


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Character:
		body.ai_controller.reward -= 2
