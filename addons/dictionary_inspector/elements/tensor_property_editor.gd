tool
class_name TensorPropertyEditor
extends GridContainer

enum ComponentId {
  X,
  Y,
  Z,
  W,
  D,
  SIZE_W,
  SIZE_H,
  SIZE_D,
  POSITION_X,
  POSITION_Y,
  POSITION_Z,
  X_X,
  X_Y,
  X_Z,
  Y_X,
  Y_Y,
  Y_Z,
  Z_X,
  Z_Y,
  Z_Z,
}
const component_letters := ["x", "y", "z", "w", "d", "w", "h", "d"]
const colors := [
  Color("886556"), Color("4c785a"), Color("5f5182"),
  Color("696a6b"), Color("696a6b"),
  Color("886556"), Color("4c785a"), Color("5f5182"),
]

signal value_changed(new_value)

var value
var type := 0
var float_step := 0.01


func _init(value, type, float_step):
  self.value = value
  self.float_step = float_step
  call("init_" + str(type), value)


func add_field_with_label(component_id, value):
  var new_editor = EditorSpinSlider.new()
  new_editor.step = float_step
  new_editor.value = value
  new_editor.size_flags_horizontal = SIZE_EXPAND_FILL
  new_editor.hide_slider = true
  new_editor.max_value = INF
  new_editor.min_value = -INF
  new_editor.connect("value_changed", self, "_on_field_edited", [component_id])

  var new_label = Label.new()
  add_child(new_label)
  add_child(new_editor)

  if component_id > ComponentId.SIZE_D:
    # For XYZWD, use their numbers. The rest are just XYZ,XYZ,XYZ,XYZ
    component_id = (component_id + 1) % 3

  new_label.text = component_letters[component_id]
  new_label.self_modulate = colors[component_id] * 1.3
  # multiplied cause they kinda look too dim and i can't bother with getting the actual correct color


func _on_field_edited(value, component_id):
  if self.value is Transform:
    if component_id <= ComponentId.Z:
      self.value.origin = get_with_component_changed(self.value.origin, value, component_id)
    
    else:
      self.value.basis = get_with_component_changed(self.value.basis, value, component_id)

  elif self.value is Transform2D:
    if component_id <= ComponentId.Z:
      self.value.origin = get_with_component_changed(self.value.origin, value, component_id)

  else:
    self.value = get_with_component_changed(self.value, value, component_id)

  emit_signal("value_changed", self.value)


func get_with_component_changed(tensor, value, component_id):
  match component_id:
    ComponentId.X:
      tensor.x = value
    ComponentId.Y:
      tensor.y = value
    ComponentId.Z:
      tensor.z = value
    ComponentId.W:
      tensor.w = value
    ComponentId.D:
      tensor.d = value
    ComponentId.POSITION_X:
      tensor.position.x = value
    ComponentId.POSITION_Y:
      tensor.position.y = value
    ComponentId.POSITION_Z:
      tensor.position.z = value
    ComponentId.SIZE_W:
      tensor.size.x = value
    ComponentId.SIZE_H:
      tensor.size.y = value
    ComponentId.SIZE_D:
      tensor.size.z = value
    ComponentId.X_X:
      tensor.x.x = value
    ComponentId.X_Y:
      tensor.x.y = value
    ComponentId.X_Z:
      tensor.x.z = value
    ComponentId.Y_X:
      tensor.y.x = value
    ComponentId.Y_Y:
      tensor.y.y = value
    ComponentId.Y_Z:
      tensor.y.z = value
    ComponentId.Z_X:
      tensor.z.x = value
    ComponentId.Z_Y:
      tensor.z.y = value
    ComponentId.Z_Z:
      tensor.z.z = value

  return tensor

# Vector2
func init_5(value):
  columns = 4
  add_field_with_label(ComponentId.X, value.x)
  add_field_with_label(ComponentId.Y, value.y)

# Rect2
func init_6(value):
  columns = 8
  add_field_with_label(ComponentId.POSITION_X, value.position.x)
  add_field_with_label(ComponentId.POSITION_Y, value.position.y)
  add_field_with_label(ComponentId.SIZE_W, value.size.x)
  add_field_with_label(ComponentId.SIZE_H, value.size.y)

# Vector3
func init_7(value):
  columns = 6
  add_field_with_label(ComponentId.X, value.x)
  add_field_with_label(ComponentId.Y, value.y)
  add_field_with_label(ComponentId.Z, value.z)

# Xform2
func init_8(value):
  columns = 4
  add_field_with_label(ComponentId.X_X, value.x.x)
  add_field_with_label(ComponentId.X_Y, value.x.y)
  add_field_with_label(ComponentId.Y_X, value.y.x)
  add_field_with_label(ComponentId.Y_Y, value.y.y)
  add_field_with_label(ComponentId.X, value.origin.x)
  add_field_with_label(ComponentId.Y, value.origin.y)

# ✈
func init_9(value):
  columns = 8
  add_field_with_label(ComponentId.X, value.x)
  add_field_with_label(ComponentId.Y, value.y)
  add_field_with_label(ComponentId.Z, value.z)
  add_field_with_label(ComponentId.D, value.d)

# Quat
func init_10(value):
  columns = 8
  add_field_with_label(ComponentId.X, value.x)
  add_field_with_label(ComponentId.Y, value.y)
  add_field_with_label(ComponentId.Z, value.z)
  add_field_with_label(ComponentId.W, value.w)

# Rect3
func init_11(value):
  columns = 6
  add_field_with_label(ComponentId.POSITION_X, value.position.x)
  add_field_with_label(ComponentId.POSITION_Y, value.position.y)
  add_field_with_label(ComponentId.POSITION_Z, value.position.z)
  add_field_with_label(ComponentId.SIZE_W, value.size.x)
  add_field_with_label(ComponentId.SIZE_H, value.size.y)
  add_field_with_label(ComponentId.SIZE_D, value.size.z)

# Based
func init_12(value):
  columns = 6
  add_field_with_label(ComponentId.X_X, value.x.x)
  add_field_with_label(ComponentId.X_Y, value.x.y)
  add_field_with_label(ComponentId.X_Z, value.x.z)
  add_field_with_label(ComponentId.Y_X, value.y.x)
  add_field_with_label(ComponentId.Y_Y, value.y.y)
  add_field_with_label(ComponentId.Y_Z, value.y.z)
  add_field_with_label(ComponentId.Z_X, value.z.x)
  add_field_with_label(ComponentId.Z_Y, value.z.y)
  add_field_with_label(ComponentId.Z_Z, value.z.z)

# Xform3
func init_13(value):
  columns = 6
  
  # Thank Goodness I have the Naruto Cloning Technique.
  add_field_with_label(ComponentId.X_X, value.basis.x.x)
  add_field_with_label(ComponentId.X_Y, value.basis.x.y)
  add_field_with_label(ComponentId.X_Z, value.basis.x.z)
  add_field_with_label(ComponentId.Y_X, value.basis.y.x)
  add_field_with_label(ComponentId.Y_Y, value.basis.y.y)
  add_field_with_label(ComponentId.Y_Z, value.basis.y.z)
  add_field_with_label(ComponentId.Z_X, value.basis.z.x)
  add_field_with_label(ComponentId.Z_Y, value.basis.z.y)
  add_field_with_label(ComponentId.Z_Z, value.basis.z.z)
  add_field_with_label(ComponentId.X, value.origin.x)
  add_field_with_label(ComponentId.Y, value.origin.y)
  add_field_with_label(ComponentId.Z, value.origin.z)

# Vector4 (nah jk colors use a different control)
func init_14(value):
  pass
