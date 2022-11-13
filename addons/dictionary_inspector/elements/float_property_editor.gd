tool
class_name FloatPropertyEditor
extends MarginContainer

signal value_changed(new_value)

var dragged := false
var edited := false
var cur_value := 0.0
var step := 0.0
var click_start := Vector2()


func _init(value = 0.0, step = 0.001):
	add_child(Label.new())
	add_child(LineEdit.new())
	get_child(1).hide()
	get_child(1).connect("text_entered", self, "_release_focus")
	size_flags_horizontal = SIZE_EXPAND_FILL

	set_value(value)
	rect_min_size.x = 32.0
	self.step = step


func set_value(value):
	if value is String:
		var script = GDScript.new()
		script.source_code = "func f():\n  return " + value
		script.reload()
		value = float(script.new().f())
	
	cur_value = value
	get_child(0).text = str(value)
	get_child(1).text = str(value)
	get_child(1).hide()
	emit_signal("value_changed", cur_value)


func _input(event):
	if event is InputEventMouseMotion:
		if edited: return
		if dragged:
			set_value(cur_value + event.relative.x * step)
			get_tree().set_input_as_handled()

		if !get_global_rect().has_point(event.position):
			return
			
		if Input.is_mouse_button_pressed(BUTTON_LEFT) && abs(event.position.x - click_start.x) > 6:
			dragged = true
		
		
	if event is InputEventMouseButton:
		if !event.button_index == BUTTON_LEFT:
			return
		
		if !get_global_rect().has_point(event.position):
			if edited:
				set_value(get_child(1).text)

			edited = false
			dragged = false


func _gui_input(event):
	if event is InputEventMouseButton:
		if !event.button_index == BUTTON_LEFT:
			return
		
		# Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if event.pressed:
			# Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			dragged = true
			click_start = event.position

		elif !dragged:
			get_child(1).show()
			get_child(1).grab_focus()
			edited = true

		dragged = false


func _release_focus(arg0 = null):
	get_child(1).hide()
	get_child(1).release_focus()
	set_value(get_child(1).text)
	edited = false
	dragged = false
