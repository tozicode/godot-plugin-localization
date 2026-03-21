## 言語によって文字列を切り替えたいテキストリソースを表すクラス。
@tool
extends Resource
class_name LocalizedString

signal changed_text_key


## 日本語におけるテキスト。
@export_multiline
var text: String:
	get: return text
	set(value):
		text = value
		changed.emit()

## テキストを参照するためのキー文字列。
@export
var text_key: String = "_undefined_":
	get: return text_key
	set(value):
		text_key = value
		changed_text_key.emit()
		update_text()


static func create_from_text_key(key: String) -> LocalizedString:
	var s = LocalizedString.new()
	s.text_key = key
	return s


func _setup_local_to_scene() -> void:
	update_text()


func update_text():
	if Engine.is_editor_hint():
		return
	if Localization.has_key(text_key):
		text = Localization.get_string(text_key)


func get_text_replaced(dict: Dictionary):
	var out = str(text)
	for key in dict.keys():
		out = out.replace("{%s}" % key, str(dict[key]))
	return out
