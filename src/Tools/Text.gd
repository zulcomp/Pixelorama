extends "res://src/Tools/Base.gd"


var loaded_fonts := [
	preload("res://assets/fonts/Roboto-Regular.ttf"),
	preload("res://assets/fonts/CJK/NotoSansCJKtc-Regular.otf")
]
var text_edit : TextEdit
var text_edit_pos := Vector2.ZERO
var text_size := 16
var font_data : DynamicFontData

onready var font := DynamicFont.new()
onready var font_optionbutton : OptionButton = $FontOptionButton
onready var font_filedialog : FileDialog = $FontFileDialog


func _ready() -> void:
	font_data = loaded_fonts[0]
	font.font_data = font_data
	font.size = text_size


func draw_start(position : Vector2) -> void:
	if text_edit:
		text_to_pixels()

	text_edit = TextEdit.new()
	text_edit.text = ""
	text_edit.rect_position = get_viewport().get_mouse_position()
	text_edit_pos = position
	text_edit.rect_min_size = Vector2(100, 60)
	Global.control.add_child(text_edit)


func draw_move(_position : Vector2) -> void:
	pass


func draw_end(_position : Vector2) -> void:
	pass


func text_to_pixels() -> void:
	if !text_edit:
		return
	if !text_edit.text:
		text_edit.queue_free()
		text_edit = null
		return

	var project : Project = Global.current_project
	var size : Vector2 = project.size
	var current_cel = project.frames[project.current_frame].cels[project.current_layer].image
	var viewport_texture := Image.new()

	var vp = VisualServer.viewport_create()
	var canvas = VisualServer.canvas_create()
	VisualServer.viewport_attach_canvas(vp, canvas)
	VisualServer.viewport_set_size(vp, size.x, size.y)
	VisualServer.viewport_set_disable_3d(vp, true)
	VisualServer.viewport_set_usage(vp, VisualServer.VIEWPORT_USAGE_2D)
	VisualServer.viewport_set_hdr(vp, true)
	VisualServer.viewport_set_active(vp, true)
	VisualServer.viewport_set_transparent_background(vp, true)

	var ci_rid = VisualServer.canvas_item_create()
	VisualServer.viewport_set_canvas_transform(vp, canvas, Transform())
	VisualServer.canvas_item_set_parent(ci_rid, canvas)
	var texture = ImageTexture.new()
	texture.create_from_image(current_cel)
	VisualServer.canvas_item_add_texture_rect(ci_rid, Rect2(Vector2(0, 0), size), texture)

	font.draw(ci_rid, text_edit_pos, text_edit.text, tool_slot.color)

	VisualServer.viewport_set_update_mode(vp, VisualServer.VIEWPORT_UPDATE_ONCE)
	VisualServer.viewport_set_vflip(vp, true)
	VisualServer.force_draw(false)
	viewport_texture = VisualServer.texture_get_data(VisualServer.viewport_get_texture(vp))
	VisualServer.free_rid(vp)
	VisualServer.free_rid(canvas)
	VisualServer.free_rid(ci_rid)
	viewport_texture.convert(Image.FORMAT_RGBA8)
	print(viewport_texture.get_size())
	if !viewport_texture.is_empty():
		Global.canvas.handle_undo("Draw")
		current_cel.unlock()
		current_cel.copy_from(viewport_texture)
		current_cel.lock()
		Global.canvas.handle_redo("Draw")

	text_edit.queue_free()
	text_edit = null


func _on_TextSizeSpinBox_value_changed(value : int) -> void:
	text_size = value
	font.size = text_size


func _on_FontOptionButton_item_selected(index : int):
	if index >= loaded_fonts.size():
		return
	font_data = loaded_fonts[index]
	font.font_data = font_data


func _on_LoadFontButton_pressed() -> void:
	font_filedialog.popup_centered()
	Global.dialog_open(true)


func _on_FontFileDialog_files_selected(paths : PoolStringArray) -> void:
	for path in paths:
		var file = DynamicFont.new()
		file = load(path)
		if !file:
			print("Failed ", path)
			continue
		loaded_fonts.append(file)
		var file_name = path.get_file().get_basename()
		font_optionbutton.add_item(file_name)
		print("Success ", path)


func _on_FontFileDialog_popup_hide() -> void:
	Global.dialog_open(false)
