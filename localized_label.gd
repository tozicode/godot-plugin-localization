## 言語設定によって文字列を変更するラベル。
## フォント・フォントサイズは Theme から自動適用される。
## text_key を設定しない場合は通常の Label として使用可能（Theme のフォントのみ適用）。
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
## LabelSettings が設定されている場合は、フォントとフォントサイズのみ Theme から上書きし、
## LabelSettings による文字修飾（色、アウトライン、影など）は維持する。
func _apply_style_theme():
	if theme_style.is_empty():
		theme = null
		return
	var t = Localization.get_theme(theme_style)
	if t == null:
		theme = null
		return
	theme = t
	if label_settings != null:
		_apply_theme_font_to_label_settings(t)


## Theme のフォント情報を LabelSettings に反映する。
func _apply_theme_font_to_label_settings(t: Theme):
	## LabelSettings を複製して元リソースを変更しないようにする。
	label_settings = label_settings.duplicate()
	if t.has_font("font", "Label"):
		label_settings.font = t.get_font("font", "Label")
	if t.has_font_size("font_size", "Label"):
		label_settings.font_size = t.get_font_size("font_size", "Label")


## キー文字列によって Localization から参照される文字列で text を更新する。
func update_text_by_key():
	if text_key == "_undefined_" or text_key.is_empty():
		return
	if Localization.has_key(text_key):
		text = Localization.get_string(text_key)
