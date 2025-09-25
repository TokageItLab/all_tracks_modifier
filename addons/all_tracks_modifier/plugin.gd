@tool
extends EditorPlugin


signal dialog_closed(canceled: bool)

enum UpdateMode {
	UPDATE_CONTINUOUS,
	UPDATE_DISCRETE,
	UPDATE_CAPTURE
}

enum WrapMode {
	WARP_MODE_CLAMP,
	WARP_MODE_LOOP,
}


enum InterpolationType {
	INTERPOLATION_TYPE_NEAREST,
	INTERPOLATION_TYPE_LINEAR,
	INTERPOLATION_TYPE_CUBIC,
}


enum TypeFilter {
	TYPE_FILTER_POS3D = 1,
	TYPE_FILTER_ROT3D = 2,
	TYPE_FILTER_SCL3D = 4,
	TYPE_FILTER_BS = 8,
	TYPE_FILTER_VAL = 16,
}


const _PLUGIN_NAME: String = "All Tracks Modifier..."


var _dialog: ConfirmationDialog
var _dialog_loop_option: OptionButton
var _dialog_interpolation_option: OptionButton
var _dialog_update_option: OptionButton
var _dialog_pos3d: CheckBox
var _dialog_rot3d: CheckBox
var _dialog_scl3d: CheckBox
var _dialog_bs: CheckBox
var _dialog_val: CheckBox


func _enter_tree() -> void:
	add_tool_menu_item(_PLUGIN_NAME, self._main)
	_make_dialog()


func _exit_tree() -> void:
	remove_tool_menu_item(_PLUGIN_NAME)


func _make_label(text: String) -> Label:
	var ret: Label = Label.new()
	ret.custom_minimum_size = Vector2(200, 0)
	ret.text = text
	return ret


func _make_dialog() -> void:
	# New GUI elements.
	_dialog = ConfirmationDialog.new()
	_dialog.unresizable = true
	_dialog.title = "All Tracks Modifier"
	_dialog_loop_option = OptionButton.new()
	_dialog_loop_option.add_icon_item(EditorInterface.get_base_control().get_theme_icon("InterpWrapClamp", "EditorIcons"), "Clamp", WrapMode.WARP_MODE_CLAMP)
	_dialog_loop_option.add_icon_item(EditorInterface.get_base_control().get_theme_icon("InterpWrapLoop", "EditorIcons"), "Loop", WrapMode.WARP_MODE_LOOP)
	_dialog_interpolation_option = OptionButton.new()
	_dialog_interpolation_option.add_icon_item(EditorInterface.get_base_control().get_theme_icon("InterpRaw", "EditorIcons"), "Nearest", InterpolationType.INTERPOLATION_TYPE_NEAREST)
	_dialog_interpolation_option.add_icon_item(EditorInterface.get_base_control().get_theme_icon("InterpLinear", "EditorIcons"), "Linear", InterpolationType.INTERPOLATION_TYPE_LINEAR)
	_dialog_interpolation_option.add_icon_item(EditorInterface.get_base_control().get_theme_icon("InterpCubic", "EditorIcons"), "Cubic", InterpolationType.INTERPOLATION_TYPE_CUBIC)
	_dialog_update_option = OptionButton.new()
	_dialog_update_option.add_icon_item(EditorInterface.get_base_control().get_theme_icon("TrackContinuous", "EditorIcons"), "Continuous", UpdateMode.UPDATE_CONTINUOUS)
	_dialog_update_option.add_icon_item(EditorInterface.get_base_control().get_theme_icon("TrackDiscrete", "EditorIcons"), "Discrete", UpdateMode.UPDATE_DISCRETE)
	_dialog_update_option.add_icon_item(EditorInterface.get_base_control().get_theme_icon("TrackCapture", "EditorIcons"), "Capture", UpdateMode.UPDATE_CAPTURE)
	_dialog_pos3d = CheckBox.new()
	_dialog_pos3d.button_pressed = true
	_dialog_rot3d = CheckBox.new()
	_dialog_rot3d.button_pressed = true
	_dialog_scl3d = CheckBox.new()
	_dialog_scl3d.button_pressed = true
	_dialog_bs = CheckBox.new()
	_dialog_bs.button_pressed = true
	_dialog_val = CheckBox.new()
	_dialog_val.button_pressed = true
	var grid: GridContainer = GridContainer.new()

	# Set default values.
	_dialog_loop_option.select(WrapMode.WARP_MODE_CLAMP)
	_dialog_interpolation_option.select(InterpolationType.INTERPOLATION_TYPE_LINEAR)
	_dialog_update_option.select(UpdateMode.UPDATE_CONTINUOUS)

	# Add child GUI elements.
	grid.columns = 2
	add_child(_dialog, false, InternalMode.INTERNAL_MODE_BACK)
	_dialog.add_child(grid, false, InternalMode.INTERNAL_MODE_BACK)
	grid.add_child(_make_label("Ends Wrap Mode"), false, InternalMode.INTERNAL_MODE_BACK)
	grid.add_child(_dialog_loop_option, false, InternalMode.INTERNAL_MODE_BACK)
	grid.add_child(_make_label("Interpolation Type"), false, InternalMode.INTERNAL_MODE_BACK)
	grid.add_child(_dialog_interpolation_option, false, InternalMode.INTERNAL_MODE_BACK)
	grid.add_child(_make_label("Update Type"), false, InternalMode.INTERNAL_MODE_BACK)
	grid.add_child(_dialog_update_option, false, InternalMode.INTERNAL_MODE_BACK)
	grid.add_child(_make_label("-- Target Track Type --"), false, InternalMode.INTERNAL_MODE_BACK)
	grid.add_child(HSeparator.new(), false, InternalMode.INTERNAL_MODE_BACK)
	grid.add_child(_make_label("3D Position"), false, InternalMode.INTERNAL_MODE_BACK)
	grid.add_child(_dialog_pos3d, false, InternalMode.INTERNAL_MODE_BACK)
	grid.add_child(_make_label("3D Rotation"), false, InternalMode.INTERNAL_MODE_BACK)
	grid.add_child(_dialog_rot3d, false, InternalMode.INTERNAL_MODE_BACK)
	grid.add_child(_make_label("3D Scale"), false, InternalMode.INTERNAL_MODE_BACK)
	grid.add_child(_dialog_scl3d, false, InternalMode.INTERNAL_MODE_BACK)
	grid.add_child(_make_label("Blend Shape"), false, InternalMode.INTERNAL_MODE_BACK)
	grid.add_child(_dialog_bs, false, InternalMode.INTERNAL_MODE_BACK)
	grid.add_child(_make_label("Value"), false, InternalMode.INTERNAL_MODE_BACK)
	grid.add_child(_dialog_val, false, InternalMode.INTERNAL_MODE_BACK)
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog_loop_option.custom_minimum_size = Vector2(200, 0)
	_dialog_loop_option.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog_interpolation_option.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog.connect("canceled", func (): dialog_closed.emit(true))
	_dialog.connect("confirmed", func (): dialog_closed.emit(false))


func _main() -> void:
	# Check if it select only one animation mixer.
	var selected: EditorSelection = EditorInterface.get_selection()
	if selected.get_selected_nodes().size() != 1 || selected.get_selected_nodes()[0].get_class() != "AnimationPlayer":
		printerr("AllTracksModifier: You should select only one AnimationPlayer.")
	var selected_player: AnimationPlayer = selected.get_selected_nodes()[0]
	var selected_animation: String = selected_player.assigned_animation
	if selected_animation.is_empty():
		printerr("AllTracksModifier: AnimationPlayer must assign Animation.")
		return
	var selected_animation_ref: Animation = selected_player.get_animation(selected_animation)
	var selected_animation_length: float = selected_animation_ref.length

	# Open dialog and input settings.
	_dialog.popup_centered(Vector2(400, 100) * EditorInterface.get_editor_scale())
	var is_dialog_canceled: bool = await self.dialog_closed
	if is_dialog_canceled:
		print("AllTracksModifier: Process canceled.")
		return

	var is_loop: bool = _dialog_loop_option.get_selected_id() == WrapMode.WARP_MODE_LOOP
	var intrp_type: Animation.InterpolationType = Animation.InterpolationType.INTERPOLATION_LINEAR
	match _dialog_interpolation_option.get_selected_id():
		InterpolationType.INTERPOLATION_TYPE_NEAREST:
			intrp_type = Animation.InterpolationType.INTERPOLATION_NEAREST
		InterpolationType.INTERPOLATION_TYPE_LINEAR:
			intrp_type = Animation.InterpolationType.INTERPOLATION_LINEAR
		InterpolationType.INTERPOLATION_TYPE_CUBIC:
			intrp_type = Animation.InterpolationType.INTERPOLATION_CUBIC
	var update_type: Animation.UpdateMode = Animation.UpdateMode.UPDATE_CONTINUOUS
	match _dialog_update_option.get_selected_id():
		UpdateMode.UPDATE_CONTINUOUS:
			update_type = Animation.UpdateMode.UPDATE_CONTINUOUS
		UpdateMode.UPDATE_CAPTURE:
			update_type = Animation.UpdateMode.UPDATE_CAPTURE
		UpdateMode.UPDATE_DISCRETE:
			update_type = Animation.UpdateMode.UPDATE_DISCRETE

	var filter: int = 0
	if _dialog_pos3d.button_pressed:
		filter |= TypeFilter.TYPE_FILTER_POS3D
	if _dialog_rot3d.button_pressed:
		filter |= TypeFilter.TYPE_FILTER_ROT3D
	if _dialog_scl3d.button_pressed:
		filter |= TypeFilter.TYPE_FILTER_SCL3D
	if _dialog_bs.button_pressed:
		filter |= TypeFilter.TYPE_FILTER_BS
	if _dialog_val.button_pressed:
		filter |= TypeFilter.TYPE_FILTER_VAL

	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action("AllTracksModifier: Set options")
	for i in selected_animation_ref.get_track_count():
		if selected_animation_ref.track_is_imported(i) || selected_animation_ref.track_is_compressed(i):
			continue
		match selected_animation_ref.track_get_type(i):
			Animation.TrackType.TYPE_ANIMATION, Animation.TrackType.TYPE_AUDIO, Animation.TrackType.TYPE_BEZIER, Animation.TrackType.TYPE_METHOD:
				continue
			Animation.TrackType.TYPE_POSITION_3D:
				if !(filter & TypeFilter.TYPE_FILTER_POS3D):
					continue
			Animation.TrackType.TYPE_ROTATION_3D:
				if !(filter & TypeFilter.TYPE_FILTER_ROT3D):
					continue
			Animation.TrackType.TYPE_SCALE_3D:
				if !(filter & TypeFilter.TYPE_FILTER_SCL3D):
					continue
			Animation.TrackType.TYPE_BLEND_SHAPE:
				if !(filter & TypeFilter.TYPE_FILTER_BS):
					continue
			Animation.TrackType.TYPE_VALUE:
				if !(filter & TypeFilter.TYPE_FILTER_VAL):
					continue
		
		ur.add_undo_method(selected_animation_ref, "track_set_interpolation_loop_wrap", i, selected_animation_ref.track_get_interpolation_loop_wrap(i))
		ur.add_undo_method(selected_animation_ref, "track_set_interpolation_type", i, selected_animation_ref.track_get_interpolation_type(i))
		ur.add_do_method(selected_animation_ref, "track_set_interpolation_loop_wrap", i, is_loop)
		ur.add_do_method(selected_animation_ref, "track_set_interpolation_type", i, intrp_type)
		if selected_animation_ref.track_get_type(i) == Animation.TrackType.TYPE_VALUE: #Method returns an error on non-value tracks.
			ur.add_undo_method(selected_animation_ref, "value_track_set_update_mode", i, selected_animation_ref.value_track_get_update_mode(i))
			ur.add_do_method(selected_animation_ref, "value_track_set_update_mode", i, update_type)
			
	ur.commit_action()
	print("AllTracksModifier: Process completed.")
