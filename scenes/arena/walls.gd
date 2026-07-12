extends Area3D
class_name Wall


func _on_body_entered(body: Node3D) -> void:
	if body is Character:
		body.game_over(-20.0)
