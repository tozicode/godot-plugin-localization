# Localization Plugin — Theme 運用ガイド

このアドオンは「テキストの多言語管理」と「言語別 Theme の切り替え」を一体で扱う。本ドキュメントでは Theme 運用に関する設計方針と使い方を整理する。

## 全体像

Localization では各言語ごとに専用の `Theme` リソースを用意し、ノードに割り当てる Theme を言語切替に応じて差し替える。
ノード側はテーマファイルを直接参照せず、**スタイル名** (例: `"main"` `"sub"`) で間接的に参照する。

```
LocalizedLabel
└─ theme_style = "main"        ← スタイル名で指定
   └─ Localization.get_theme("main")
      └─ res://themes/theme_main_<lang>.tres  ← 言語別 Theme
```

## 用語と規約

### theme_styles (プロジェクト設定)

`localization/theme_styles` で利用するスタイル名のリストを定義する。

```
theme_styles = PackedStringArray("main", "sub", "small")
```

各スタイルは「テキストの用途」を表す (例: 本文、見出し、補足)。

### 言語別 Theme ファイルの命名規約

`res://themes/theme_<style>_<lang>.tres` の形式で配置する。

```
res://themes/theme_main_ja.tres
res://themes/theme_main_en.tres
res://themes/theme_sub_ja.tres
res://themes/theme_sub_en.tres
...
```

対応言語コード (lang) は `localization.gd` の `LANGUAGE_NAMES` 配列で定義 (`ja`, `en`, `zhch`, `zhtw`, `kr`)。

### Theme リソースの基本構造

最低限フォントとフォントサイズを定義する。

```
[gd_resource type="Theme" format=3]
[ext_resource type="FontFile" path="res://fonts/DotGothic16-Regular.ttf" id="1_font"]

[resource]
default_font = ExtResource("1_font")
default_font_size = 24
Label/fonts/font = ExtResource("1_font")
Label/font_sizes/font_size = 24
```

## 文字修飾は Theme に書く (LabelSettings を併用しない)

### 原則

色、アウトライン、影などの文字修飾は **Theme** で表現する。**`LabelSettings` は使わない**。

### なぜ Theme と LabelSettings を併用してはいけないか

Godot の `Label` は `theme` と `label_settings` の両方を保持できるが、両者の値を**部分的にマージすることはできない**。`label_settings` を割り当てた瞬間に、`font_size` などのプロパティは LabelSettings 側の値 (未設定の場合はクラス既定値 16) に強制的に上書きされる。

例: Theme で `font_size = 24`、LabelSettings に `outline_size = 4` のみ指定すると、フォントサイズは Theme の 24 ではなく LabelSettings の既定 16 になってしまう。

このため、装飾を Theme に統合し、LabelSettings は使わないことを推奨する。

### Theme で書ける Label の文字修飾プロパティ

| 用途 | プロパティ |
|---|---|
| フォント色 | `Label/colors/font_color` |
| フォント | `Label/fonts/font` |
| フォントサイズ | `Label/font_sizes/font_size` |
| アウトラインサイズ | `Label/constants/outline_size` |
| アウトライン色 | `Label/colors/font_outline_color` |
| 影色 | `Label/colors/font_shadow_color` |
| 影オフセット | `Label/constants/shadow_offset_x`, `shadow_offset_y` |
| 行間 | `Label/constants/line_spacing` |

`RichTextLabel` では `RichTextLabel/normal_font`, `RichTextLabel/colors/font_outline_color`, `RichTextLabel/constants/outline_size` などを使う。

### 言語間で装飾を共通化する場合

Theme は継承を持たないため、共通の装飾 (例: 全言語でアウトライン 5pt) は各言語別 Theme ファイルに同じ値を書く運用となる。複製のコストはあるが、フレームワークレベルでマージする仕組みは現状提供しない。

## LocalizedLabel の使い方

通常の `Label` の代わりに `LocalizedLabel` ノードを使う。

```
[node name="NameLabel" type="Label" parent="."]
text = "(未設定)"
script = ExtResource("localized_label.gd")
text_key = "status_name"        ## 多言語テキストのキー
theme_style = "main"            ## スタイル名 (theme_main_<lang>.tres が適用される)
```

### プロパティ

- `text_key`: 多言語テキストのキー文字列。空または `_undefined_` の場合は `text` の値をそのまま使う
- `theme_style`: 使用する Theme のスタイル名 (例: `"main"`)。空の場合は `theme = null` となり、親ノードの Theme が継承される

### 動作

- `_ready()` / `text_key` 変更 / `theme_style` 変更 / 言語変更 のタイミングで自動的に Theme とテキストが更新される
- `theme` プロパティをエディタで直接設定しても、`_ready()` で `theme_style` の値に従って上書きされる。**`theme` ではなく `theme_style` を使うこと**

### `label_settings` は使わない

LocalizedLabel は `label_settings` を扱わない。文字修飾は Theme に書く方針のため。

## LocalizedRichTextLabel の使い方

RichTextLabel 版。基本構造は LocalizedLabel と同じ。`theme_style` で Theme を切り替える。

```
[node name="MessageLog" type="RichTextLabel" parent="."]
script = ExtResource("localized_rich_text_label.gd")
text_key = "msg_attack"
theme_style = "small"
```

### `label_settings` についての注意

`LocalizedRichTextLabel` は歴史的経緯で `label_settings` プロパティを残している (BBCode への変換による文字修飾の適用)。ただし Theme での文字修飾統合方針に従い、新規実装では `label_settings` を使わず、装飾はすべて Theme に書くことを推奨する。

## 言語非依存の Theme

特定のフォント/装飾を使いたいが**言語切替の対象外**としたい場合 (例: 数字専用のフォント) は、Localization の `theme_styles` には登録せず、単独の `.tres` を作って **`theme` プロパティで直接** 割り当てる。

```
res://themes/theme_numeric.tres         ## 言語非依存 (Jacquard フォント)
```

```
[node name="HpLabel" type="Label" parent="."]
theme = ExtResource("res://themes/theme_numeric.tres")
text = "300/300"
```

スタイル別言語別 Theme を生成する Localization の仕組みに**乗せない**ことが重要。乗せると `res://themes/theme_numeric_ja.tres` などのファイルが要求されてしまう。

## バリエーション (派生スタイル)

同じスタイル内で派生バリエーション (例: 警告用の赤文字、強調用の太字) を作りたい場合は Godot 標準の **Theme Type Variation** を使う。

Theme リソース内で `Label` の派生として `WarningLabel` などを定義し、ノード側で `theme_type_variation = "WarningLabel"` を指定する。スタイル数を増やすより軽量で、フォントの共通化もしやすい。

## チェックリスト

新しく Label を配置するとき:

- [ ] テキストは `text_key` を指定して `Localization` 経由で取得しているか
- [ ] フォントとサイズは Theme で指定しているか (LabelSettings ではなく)
- [ ] アウトライン/色などの文字修飾も Theme で指定しているか
- [ ] `theme_style` を指定しているか (言語切替対象の場合)
- [ ] 言語非依存の場合は `theme` プロパティで直接割り当てているか

## 関連ファイル

- [localization.gd](localization.gd) — オートロード。`get_theme(style)` で言語に応じた Theme を返す
- [localized_label.gd](localized_label.gd) — Label の Localized 版
- [localized_rich_text_label.gd](localized_rich_text_label.gd) — RichTextLabel の Localized 版
- [localized_string.gd](localized_string.gd) — エクスポート用の多言語文字列リソース
- [.claude/CLAUDE.md](.claude/CLAUDE.md) — このプラグイン編集時の同期ワークフロー
