## 言語設定によって文字列を変更する RichTextLabel。
## フォント・フォントサイズは Theme から自動適用される。
## text_key を設定しない場合は通常の RichTextLabel として使用可能（Theme のフォントのみ適用）。
## label_settings を設定すると、色・アウトラインを BBCode で再現する。
## ※ 影（shadow）は BBCode に対応するタグが無いため非対応。
extends RichTextLabel
class_name LocalizedRichTextLabel

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

## 文字修飾の設定。色・アウトラインを BBCode として適用する。
## フォントとフォントサイズは theme_style 経由の Theme から適用されるため無視される。
@export
var label_settings: LabelSettings = null


func _ready():
	bbcode_enabled = true
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
		var raw_text = Localization.get_string(text_key)
		text = _wrap_with_label_settings_bbcode(raw_text)


## LabelSettings の設定を BBCode タグで囲んだ文字列を返す。
## label_settings が未設定の場合はそのまま返す。
func _wrap_with_label_settings_bbcode(raw_text: String) -> String:
	if label_settings == null:
		return raw_text

	var prefix := ""
	var suffix := ""

	## アウトラインサイズ
	if label_settings.outline_size > 0:
		prefix += "[outline_size=%d]" % label_settings.outline_size
		suffix = "[/outline_size]" + suffix

	## アウトライン色
	if label_settings.outline_size > 0 and label_settings.outline_color != Color.BLACK:
		prefix += "[outline_color=%s]" % label_settings.outline_color.to_html()
		suffix = "[/outline_color]" + suffix

	## フォント色
	if label_settings.font_color != Color.WHITE:
		prefix += "[color=%s]" % label_settings.font_color.to_html()
		suffix = "[/color]" + suffix

	return prefix + raw_text + suffix
