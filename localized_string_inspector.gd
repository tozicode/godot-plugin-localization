@tool
extends EditorInspectorPlugin
class_name LocalizedStringInspectorPlugin


## 選択されたノード、ファイルがこのスクリプトの対象かどうか判定する。
func _can_handle(object: Object) -> bool:
	return object is LocalizedString


## インスペクタに表示されるときに 1 回呼ばれる処理。
## 1 つのオブジェクトに LocalizedString プロパティが複数ある場合 (例: GeneralButton
## の text と help_text)、_parse_begin はそれぞれの LocalizedString に対して呼ばれる。
## そのためメンバ変数に保持すると最後に呼ばれた LocalizedString で上書きされ、
## どのボタンを押しても最後のものに対する操作になってしまう。
## ローカル変数 (target / inspector) を bind() で各コールバックに渡すことで、
## 1 つの LocalizedString に対して 1 つのボタン/ラベル群を独立して扱う。
func _parse_begin(object: Object) -> void:
	var target := object as LocalizedString
	var inspector := preload("res://addons/localization/localized_string_inspector.tscn").instantiate()
	add_custom_control(inspector)
	var button := inspector.get_child(0) as Button
	button.pressed.connect(on_button_pressed.bind(target, inspector))
	target.changed_text_key.connect(update_message.bind(target, inspector))
	update_message(target, inspector)


func on_button_pressed(target: LocalizedString, inspector: Node):
	Localization.register_string(target.text_key, target.text)
	update_message(target, inspector)


func update_message(target: LocalizedString, inspector: Node):
	if Localization.has_key(target.text_key):
		if Localization.is_equal_text(target.text_key, target.text):
			show_message(inspector, 3)
		else:
			show_message(inspector, 2)
	else:
		show_message(inspector, 1)


func show_message(inspector: Node, index: int):
	for i in 3:
		var m = inspector.get_child(1 + i) as Label
		if index == 1 + i:
			m.show()
		else:
			m.hide()
