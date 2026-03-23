@tool
## 言語設定によって文字列を変更するラベル。
## フォント・フォントサイズは Theme から自動適用される。
## text_key を設定しない場合は通常の Label として使用可能（Theme のフォントのみ適用）。
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
	if Localization.changed_language.is_connected(update_text_by_key):
		return
	Localization.changed_language.connect(update_text_by_key)


## キー文字列によって Localization から参照される文字列で text を更新する。
func update_text_by_key():
	if text_key == "_undefined_" or text_key.is_empty():
		return
	if Localization.has_key(text_key):
		text = Localization.get_string(text_key)
