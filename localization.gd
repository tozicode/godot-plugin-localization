## ゲーム中のテキストを一括管理するためのクラス。
## TSVファイルベースの多言語テキスト管理を提供する。
@tool
extends Node


## ファイルに書き出した時に発行されるシグナル。
signal wrote_file


enum {
	LANGUAGE_JA,
	LANGUAGE_EN,
	LANGUAGE_ZHCH,
	LANGUAGE_ZHTW,
	LANGUAGE_KR,
	LANGUAGE_COUNT,
}

## プロジェクト設定のキー。
const SETTING_TSV_FILEPATH := "localization/tsv_filepath"
const SETTING_FONT_PATHS := "localization/font_paths"

## デフォルトのフォントパス。
const DEFAULT_FONT_PATHS = [
	"res://Fonts/07LogoTypeGothic7.otf", # Ja
	"res://Fonts/07LogoTypeGothic7.otf", # En
	"res://Fonts/NotoSansSC-Regular.ttf", # ZhCh
	"res://Fonts/NotoSansTC-Regular.ttf", # ZhTw
	"res://Fonts/NanumGothic-Regular.ttf", # Kr
]

const DEFAULT_TSV_FILEPATH := "res://language.tsv.txt"
const LANGUAGE_NAMES = ["Ja", "En", "ZhCh", "ZhTw", "Kr"]

## 言語ごとのフォントパス。プロジェクト設定で上書き可能。
var font_paths: Array:
	get:
		if ProjectSettings.has_setting(SETTING_FONT_PATHS):
			return ProjectSettings.get_setting(SETTING_FONT_PATHS)
		return DEFAULT_FONT_PATHS

## TSVファイルのパス。プロジェクト設定で上書き可能。
var tsv_filepath: String:
	get:
		if ProjectSettings.has_setting(SETTING_TSV_FILEPATH):
			return ProjectSettings.get_setting(SETTING_TSV_FILEPATH)
		return DEFAULT_TSV_FILEPATH

var _strings = {}
var _coverage = []

var language_type = LANGUAGE_JA

## 編集されたかどうかのフラグ。
var editted: bool = false


func _init():
	for i in LANGUAGE_COUNT:
		_coverage.append(0.0)


func _ready():
	read_file()
	print("[Localization] initialized. (size = %d)" % _strings.size())


func _process(_delta: float) -> void:
	if editted:
		update_coverage()
		write_file()
		editted = false


## TSVファイルからテキストデータを読み込む。
func read_file(filepath: String = ""):
	if filepath.is_empty():
		filepath = tsv_filepath
	print("[Localization] read file: ", filepath)
	var file = FileAccess.open(filepath, FileAccess.READ)
	assert(file != null)
	while file.get_position() < file.get_length():
		var line = file.get_line()
		# コメントを除外する
		if line.contains("#"):
			line = line.substr(0, line.find("#"))
		var tsv = line.split("\t")
		if tsv.size() == 0:
			continue
		if tsv.size() == 1:
			tsv.append("")
		var key = tsv[0]
		if key.length() == 0:
			continue
		if has_key(key):
			printerr("[Localization] already has key: \"%s\"" % key)
			continue
		tsv.remove_at(0)
		_strings[key] = tsv
	update_coverage()


## 現在の言語データをファイルに書き出す。
func write_file(filepath: String = ""):
	assert(Engine.is_editor_hint())
	if filepath.is_empty():
		filepath = tsv_filepath
	print("[Localization] write file: ", filepath)
	var fout = FileAccess.open(filepath, FileAccess.WRITE)
	fout.store_line("# " + "\t".join(LANGUAGE_NAMES))
	var keys = _strings.keys()
	keys.sort()
	for key in keys:
		var tsv: PackedStringArray = [key]
		tsv.append_array(_strings[key])
		fout.store_csv_line(tsv, "\t")
	wrote_file.emit()


## 各言語の翻訳率を更新する。
## なお日本語は常に100%であるものとする。
func update_coverage():
	# 初期化する
	for i in LANGUAGE_COUNT:
		_coverage[i] = 0.0
	# 各言語における項目を数える
	for tsv in _strings.values():
		if tsv[0].is_empty():
			continue
		for i in LANGUAGE_COUNT:
			if i < tsv.size() and not tsv[i].is_empty():
				_coverage[i] += 1.0
	# 各言語を日本語の項目数で割る
	var n_str = _coverage[0]
	if n_str > 0:
		for i in LANGUAGE_COUNT:
			_coverage[i] /= n_str


## LocalizedString をデータベースに登録する。
func register_localized_string(s) -> void:
	register_string(s.text_key, s.text)


## 新たな文字列をデータベースに登録する。
func register_string(key: String, text_ja: String):
	text_ja = text_ja.replace("\n", "<br>")
	if has_key(key):
		if text_ja == get_string(key):
			return
		print("[Localization] override string[%s]: \"%s\"" % [key, text_ja])
		_strings[key][0] = text_ja
	else:
		print("[Localization] register new string[%s]: \"%s\"" % [key, text_ja])
		_strings.set(key, [text_ja])
	editted = true


## キーが指定の文字列から始まる要素を全て削除する。
func remove_strings_begins_with(prefix: String):
	print("[Localization] remove items which key begins with \"%s\"" % prefix)
	var key_removed = []
	for key: String in _strings.keys():
		if key.begins_with(prefix):
			key_removed.append(key)
	for key: String in key_removed:
		_strings.erase(key)
	editted = true


## 指定のキーに対応する文字列を返す。
## 対応する文字列が存在しない場合はエラー文字列を返す。
## 元データにおける <br> は改行に変換される。
## また現在の言語設定に応じた文字列が存在しない場合は、代わりに日本語の文字列を返す。
func get_string(key: String, substitution = null) -> String:
	if not _strings.has(key):
		return "LocalizationError[%s]" % key
	var strs = _strings[key]
	var idx: int = language_type if language_type < strs.size() else 0
	if strs[idx] == "":
		idx = 0
	var s: String = strs[idx].replace("<br>", "\n")
	if substitution != null:
		for s_from in substitution.keys():
			s = s.replace(s_from, substitution[s_from])
	return format_reference(s)


## 指定のキーに対応する文字列が無ければエラーログを出力する。
func assert_key(key: String):
	if not has_key(key):
		printerr("[Localization] does not have key: \"%s\"" % key)


## 指定のキーに対応する文字列が存在するかどうかを返す。
func has_key(key: String) -> bool:
	return _strings.has(key)


## 指定のキーに対応する文字列が引数と同じかどうかを返す。
func is_equal_text(key: String, text_ja: String) -> bool:
	if not has_key(key):
		return false
	return _strings[key][0] == text_ja.replace("\n", "<br>")


## 指定の言語に対する翻訳率をパーセントで返す。
func get_translation_coverage(lang_type: int) -> int:
	return int(_coverage[lang_type] * 100.0)


## 文字列に含まれる {hoge} 形式の文字列参照を実際の文字列に置換した結果を返す。
func format_reference(s: String) -> String:
	var i = s.find('{')
	var j = s.find('}', i + 1)
	while i >= 0 and j >= 0:
		var sub1 = s.substr(0, i)
		var sub2 = s.substr(j + 1)
		var key = s.substr(i + 1, j - i - 1)
		s = sub1 + get_string(key) + sub2
		i = s.find('{')
		j = s.find('}', i + 1)
	return s


## 言語データに含まれる要素数を返す。
func size() -> int:
	return _strings.size()
