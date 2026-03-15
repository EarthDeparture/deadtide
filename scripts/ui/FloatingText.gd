class_name FloatingText
extends Label

func show_text(t: String, is_special: bool = false) -> void:
	text = t
	if is_special:
		modulate = Color(1.0, 0.2, 0.2, 1.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 50.0, 0.9)
	tween.tween_property(self, "modulate:a", 0.0, 0.9)
	tween.chain().tween_callback(queue_free)
