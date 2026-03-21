@tool
extends EditorInspectorPlugin
class_name LocalizedStringInspectorPlugin

var target: LocalizedString
var inspector: VBoxContainer


## 選択されたノード、ファイルがこのスクリプトの対象かどうか判定する。
func _can_handle(object: Object) -> bool:
	return object is LocalizedString


## インスペクタに表示されるときに1回呼ばれる処理。
func _parse_begin(object: Object) -> void:
	# インスペクターに表示しているオブジェクトを保存
	target = object as LocalizedString
	# ボタンを作る
	inspector = preload("res://addons/localization/localized_string_inspector.tscn").instantiate()
	add_custom_control(inspector)
	# イベント登録
	var button = inspector.get_child(0) as Button
	button.pressed.connect(on_button_pressed)
	target.changed_text_key.connect(update_message)
	update_message()


func on_button_pressed():
	Localization.register_string(target.text_key, target.text)
	update_message()


func update_message():
	var message: Label = inspector.get_child(1) as Label
	if Localization.has_key(target.text_key):
		if Localization.is_equal_text(target.text_key, target.text):
			show_message(3)
		else:
			show_message(2)
	else:
		show_message(1)


func show_message(index: int):
	for i in 3:
		var m = inspector.get_child(1 + i) as Label
		if index == 1 + i:
			m.show()
		else:
			m.hide()
