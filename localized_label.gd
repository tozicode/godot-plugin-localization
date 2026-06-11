## 言語設定によって文字列を変更するラベル。
## フォント・フォントサイズ・文字修飾はすべて Theme から適用される。
## 文字修飾 (色・アウトライン等) も Theme に統合する設計のため、label_settings は使用しない。
@tool
extends Label
class_name LocalizedLabel

## テキストに対応するキー文字列。
@export
var text_key: String = "_undefined_":
	get: return text_key
	set(value):
		text_key = value
		update_text_by_key()

## 適用する Theme のスタイル名。空の場合はルートの Theme がそのまま適用される。
@export
var theme_style: String = "":
	set(value):
		theme_style = value
		_apply_style_theme()


func _ready():
	update_text_by_key()
	_apply_style_theme()
	if not Localization.changed_language.is_connected(_on_changed_language):
		Localization.changed_language.connect(_on_changed_language)


## 言語が変更されたときのコールバック。
func _on_changed_language():
	update_text_by_key()
	_apply_style_theme()


## スタイルに対応する Theme を自身に適用する。
func _apply_style_theme():
	if theme_style.is_empty():
		theme = null
		return
	var t = Localization.get_theme(theme_style)
	if t == null:
		theme = null
		return
	theme = t


## キー文字列によって Localization から参照される文字列で text を更新する。
func update_text_by_key():
	if text_key == "_undefined_" or text_key.is_empty():
		return
	if Localization.has_key(text_key):
		text = Localization.get_string(text_key)
