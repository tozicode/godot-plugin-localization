## 言語データの管理を行うエディタドック。
## 指定ディレクトリの .tres ファイルを走査し、含まれる LocalizedString を
## Localization に自動登録する汎用機能を提供する。
@tool
extends VBoxContainer

@onready
var line_edit_item_count: LineEdit = $"ItemCount/LineEdit"

@onready
var line_edit_scan_path: LineEdit = $"ScanPath/LineEdit"

@onready
var button_scan: Button = $"ScanPath/ButtonScan"

@onready
var line_edit_remove_prefix: LineEdit = $"RemoveItems/LineEdit"

@onready
var button_remove: Button = $"RemoveItems/Button"

@onready
var label_scan_result: Label = $"ScanResult"


func _ready():
	button_scan.pressed.connect(on_pressed_button_scan)
	button_remove.pressed.connect(on_pressed_button_remove)
	Localization.wrote_file.connect(update_statistics)
	update_statistics()
	label_scan_result.text = ""


## 指定ディレクトリを再帰的にスキャンし、LocalizedString を登録する。
func on_pressed_button_scan():
	var dirpath = line_edit_scan_path.text.strip_edges()
	if dirpath.is_empty():
		label_scan_result.text = "パスを入力してください。"
		return
	var count = scan_directory(dirpath)
	label_scan_result.text = "%d 件の LocalizedString を登録しました。" % count
	update_statistics()


## 指定ディレクトリの .tres ファイルを再帰的に走査し、
## リソース内の LocalizedString プロパティを自動検出して Localization に登録する。
## 登録した件数を返す。
func scan_directory(dirpath: String) -> int:
	var count := 0
	print("[LocalizationDock] scan directory: ", dirpath)

	# ファイルを走査
	for filename in DirAccess.get_files_at(dirpath):
		if not filename.ends_with(".tres"):
			continue
		var filepath = dirpath + "/" + filename
		var resource = load(filepath)
		if resource == null:
			continue
		count += scan_resource(resource)

	# サブディレクトリを再帰的に処理
	for subdir in DirAccess.get_directories_at(dirpath):
		count += scan_directory(dirpath + "/" + subdir)

	return count


## リソース内の LocalizedString プロパティを検出して登録する。
## 登録した件数を返す。
func scan_resource(resource: Resource) -> int:
	var count := 0
	for prop in resource.get_property_list():
		var value = resource.get(prop.name)
		if value is LocalizedString:
			if value.text_key != "_undefined_" and not value.text.is_empty():
				Localization.register_localized_string(value)
				count += 1
	return count


## プレフィックス指定で言語データを削除する。
func on_pressed_button_remove():
	var prefix = line_edit_remove_prefix.text
	if prefix.is_empty():
		return
	Localization.remove_strings_begins_with(prefix)


## 統計データを更新する。
func update_statistics():
	line_edit_item_count.text = str(Localization.size())
