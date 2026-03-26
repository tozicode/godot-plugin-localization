## 言語データの管理を行うエディタドック。
## 指定ディレクトリの .tres ファイルを走査し、含まれる LocalizedString を
## Localization に自動登録する汎用機能を提供する。
## キーフォーマット文字列を指定すると、text_key の自動命名も行う。
@tool
extends VBoxContainer

@onready
var line_edit_item_count: LineEdit = $"ItemCount/LineEdit"

@onready
var line_edit_scan_path: LineEdit = $"ScanPath/LineEdit"

@onready
var line_edit_key_format: LineEdit = $"KeyFormat/LineEdit"

@onready
var button_scan: Button = $"ScanPath/ButtonScan"

@onready
var line_edit_remove_prefix: LineEdit = $"RemoveItems/LineEdit"

@onready
var button_remove: Button = $"RemoveItems/Button"

@onready
var label_scan_result: Label = $"ScanResult"

@onready
var button_generate_themes: Button = $"ButtonGenerateThemes"

@onready
var label_theme_result: Label = $"ThemeResult"


func _ready():
	button_scan.pressed.connect(on_pressed_button_scan)
	button_remove.pressed.connect(on_pressed_button_remove)
	button_generate_themes.pressed.connect(on_pressed_button_generate_themes)
	Localization.wrote_file.connect(update_statistics)
	update_statistics()
	label_scan_result.text = ""
	label_theme_result.text = ""


## 指定ディレクトリを再帰的にスキャンし、LocalizedString を登録する。
func on_pressed_button_scan():
	var dirpath = line_edit_scan_path.text.strip_edges()
	if dirpath.is_empty():
		label_scan_result.text = "パスを入力してください。"
		return

	var key_format = line_edit_key_format.text.strip_edges()

	# フォーマット指定がある場合、プレフィックスを抽出して既存エントリを削除
	if not key_format.is_empty():
		var prefix = extract_prefix(key_format)
		if not prefix.is_empty():
			Localization.remove_strings_begins_with(prefix)

	var count = scan_directory(dirpath, key_format)
	label_scan_result.text = "%d 件の LocalizedString を登録しました。" % count
	update_statistics()


## フォーマット文字列からプレフィックス部分を抽出する。
## 最初の {, [ より前の部分を返す。
static func extract_prefix(key_format: String) -> String:
	var idx_brace = key_format.find("{")
	var idx_bracket = key_format.find("[")
	var end_idx = key_format.length()
	if idx_brace >= 0:
		end_idx = mini(end_idx, idx_brace)
	if idx_bracket >= 0:
		end_idx = mini(end_idx, idx_bracket)
	return key_format.substr(0, end_idx)


## フォーマット文字列から [aaa,bbb,ccc] 部分のラベル配列を抽出する。
## 見つからない場合は空配列を返す。
static func extract_labels(key_format: String) -> PackedStringArray:
	var idx_start = key_format.find("[")
	var idx_end = key_format.find("]", idx_start + 1)
	if idx_start < 0 or idx_end < 0:
		return PackedStringArray()
	var content = key_format.substr(idx_start + 1, idx_end - idx_start - 1)
	return content.split(",")


## フォーマット文字列とパラメータから text_key を生成する。
static func format_key(key_format: String, basename: String, count: int, labels: PackedStringArray) -> String:
	var key = key_format

	# {basename} を置換
	key = key.replace("{basename}", basename)

	# {count} を置換
	key = key.replace("{count}", str(count))

	# [aaa,bbb,ccc] を該当ラベルで置換
	var idx_start = key.find("[")
	var idx_end = key.find("]", idx_start + 1)
	if idx_start >= 0 and idx_end >= 0:
		var label = ""
		if count < labels.size():
			label = labels[count].strip_edges()
		key = key.substr(0, idx_start) + label + key.substr(idx_end + 1)

	return key


## 指定ディレクトリの .tres ファイルを再帰的に走査し、
## リソース内の LocalizedString プロパティを自動検出して Localization に登録する。
## key_format が指定されている場合は text_key を自動命名する。
## 登録した件数を返す。
func scan_directory(dirpath: String, key_format: String = "") -> int:
	var count := 0
	print("[LocalizationDock] scan directory: ", dirpath)

	var labels = extract_labels(key_format) if not key_format.is_empty() else PackedStringArray()

	# ファイルを走査
	for filename in DirAccess.get_files_at(dirpath):
		if not filename.ends_with(".tres"):
			continue
		var filepath = dirpath + "/" + filename
		var resource = load(filepath)
		if resource == null:
			continue
		var basename = filename.get_basename()
		count += scan_resource(resource, key_format, basename, labels)
		# フォーマット指定がある場合はリソースを保存
		if not key_format.is_empty():
			ResourceSaver.save(resource, filepath)

	# サブディレクトリを再帰的に処理
	for subdir in DirAccess.get_directories_at(dirpath):
		count += scan_directory(dirpath + "/" + subdir, key_format)

	return count


## リソース内の LocalizedString プロパティを検出して登録する。
## key_format が指定されている場合は text_key を自動命名する。
## 登録した件数を返す。
func scan_resource(resource: Resource, key_format: String = "", basename: String = "", labels: PackedStringArray = PackedStringArray()) -> int:
	var count := 0
	for prop in resource.get_property_list():
		var value = resource.get(prop.name)
		if value is LocalizedString:
			if key_format.is_empty():
				# フォーマット未指定: 既存の text_key をそのまま登録
				if value.text_key != "_undefined_" and not value.text.is_empty():
					Localization.register_localized_string(value)
					count += 1
			else:
				# フォーマット指定: text_key を自動命名して登録
				value.text_key = format_key(key_format, basename, count, labels)
				if not value.text.is_empty():
					Localization.register_localized_string(value)
				count += 1
	return count


## プレフィックス指定で言語データを削除する。
func on_pressed_button_remove():
	var prefix = line_edit_remove_prefix.text
	if prefix.is_empty():
		return
	Localization.remove_strings_begins_with(prefix)


## theme_paths に対応する Theme ファイルを生成する。
func on_pressed_button_generate_themes():
	var paths = Localization.theme_paths  ## 2次元配列
	var created := 0
	var skipped := 0
	for style_paths in paths:
		for theme_path: String in style_paths:
			# ディレクトリが存在しなければ作成
			var dir_path = theme_path.get_base_dir()
			if not DirAccess.dir_exists_absolute(dir_path):
				DirAccess.make_dir_recursive_absolute(dir_path)
			# ファイルが既に存在する場合はスキップ
			if ResourceLoader.exists(theme_path):
				skipped += 1
				continue
			# 空の Theme リソースを生成して保存
			var theme = Theme.new()
			var err = ResourceSaver.save(theme, theme_path)
			if err == OK:
				created += 1
				print("[LocalizationDock] created theme: %s" % theme_path)
			else:
				printerr("[LocalizationDock] failed to save theme: %s (error: %d)" % [theme_path, err])
	label_theme_result.text = "%d 件生成、%d 件スキップ。" % [created, skipped]


## 統計データを更新する。
func update_statistics():
	line_edit_item_count.text = str(Localization.size())
