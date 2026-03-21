## 言語設定によって文字列やフォントを変更するラベル。
extends Label
class_name LocalizedLabel

## テキストに対応するキー文字列。
@export
var text_key: String = "_undefined_":
	get: return text_key
	set(value):
		text_key = value
		update_text_by_key()


func _ready():
	update_text_by_key()


## キー文字列によって Localization から参照される文字列で text を更新する。
func update_text_by_key():
	if not text_key.is_empty() and Localization.has_key(text_key):
		text = Localization.get_string(text_key)
