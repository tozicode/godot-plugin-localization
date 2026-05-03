# addons/localization について

このディレクトリは `godot_plugins` モノレポから `git subtree split` で個別リポジトリ
(`tozicode/godot-plugin-localization`) に分離されたものを、各プロジェクトが
git submodule として参照しているものです。

複数プロジェクトで共有されているため、編集時には以下のワークフローに必ず従ってください。

## プラグイン同期ワークフロー

### 1. 編集前: ブランチを当てて最新化

`git submodule update` 直後の submodule は detached HEAD 状態のため、
そのまま commit してもブランチに記録されません。編集前に必ずブランチを当て、
最新を取り込んでください。

```bash
cd <project>/addons/localization
git checkout main
git pull origin main
```

### 2. 編集後: 即座に個別リポジトリへ push

push を後回しにすると、他プロジェクトの独自系統と衝突して解消が複雑化します。
**commit したら必ず即座に push してください。**

```bash
cd <project>/addons/localization
git add .
git commit -m "..."
git push origin main      # ← 必ず即 push
```

### 3. 親プロジェクトで submodule pointer をコミット

```bash
cd ../..
git add addons/localization
git commit -m "chore: localization プラグインを更新"
```

## このプラグインを共有しているプロジェクト

- `dungeons_and_slaves`
- `kanade_loop`
- `uchinoko_fantasia`
- `zunko-kiritan`

## 詳細仕様

詳細は `godot_plugins` モノレポの `KNOWLEDGE.md` の「プラグイン同期ワークフロー」を参照。
