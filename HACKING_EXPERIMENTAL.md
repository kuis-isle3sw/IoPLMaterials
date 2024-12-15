# HACKING (EXPERIMENTAL)

## OCaml 処理系のインストール

この科目では実装言語として OCaml を使用する。演習問題を進めるためには、自分のマシンに OCaml プログラムの開発環境を整えることが必須である。以下では、[Dune] を使って OCaml の開発環境をセットアップする方法を説明する。

### 1. [Dune] をインストール

> このガイドでは [Dune] の実験的なリリースを利用することを前提としている。また、現時点ではネイティブ Windows 環境はサポートされていない。

```sh
curl -fsSL https://get.dune.build/install | sh
```

### 2. リポジトリをクローン

```sh
git clone git@github.com:kuis-isle3sw/IoPLMaterials.git
cd IoPLMaterials
```

### 3. ロックファイルを作成

`dune pkg lock` を実行し、コンパイラを含む全ての依存関係のロックファイルを作成する。この際、[Dune] は `dune-project` ファイルを参照する。

```sh
dune pkg lock
```

### 4. ビルド

```sh
dune build
```

### 5. [OCaml-LSP] と [ocamlformat] をインストール

```sh
dune tools exec ocamllsp -- --version
dune tools exec ocamlformat -- --version
```

## エディタのセットアップ

[VSCode] 以外のエディタを含む、より詳細なセットアップ手順は [Dune] のプレビューリリースの[公式ページ](https://preview.dune.build)を参照するとよい。

### [VSCode]

推奨するのは [VSCode] と、その拡張機能の [OCaml Platform](https://marketplace.visualstudio.com/items?itemName=ocamllabs.ocaml-platform) の組み合わせである。

クローンしたリポジトリに移動し、次のコマンドを実行すると [VSCode] が起動される。

> 事前に `.vscode/settings.json` に次のような設定ファイルを置いておく必要がある。
>
> ```json
> {
>   "ocaml.sandbox": {
>     "kind": "custom",
>     "template": "$prog $args"
>   }
> }
> ```

```sh
code .
```

> `code` コマンドが存在しないとエラーが出る場合は[こちら](https://code.visualstudio.com/docs/editor/command-line#_code-is-not-recognized-as-an-internal-or-external-command)を参照。

### 便利情報

- [VSCode] を利用しない場合でも、各エディタで [LSP] を使用する方法を調べた上で [OCaml-LSP] を使うとよい。
  - [Merlin] を使用するよう書かれた資料もあるが、[OCaml-LSP] は内部的には [Merlin] を使用しており、[Merlin] にしか存在しない機能を使いたい場合などを除いて [OCaml-LSP] の利用が推奨される。
  - [ocamlformat] をインストールして作業ディレクトリに `.ocamlformat` ファイルを用意するとインデント等が自動的に整理されてよい。
    - LSP の [`textDocument/formatting`](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_formatting) を介して実行されるため、各種エディタの設定で保存時にフォーマットするようにすると尚よい。
      - [VSCode] では `editor.formatOnSave` として設定が用意されている。

## Acronyms

- LSP: [Language Server Protocol][LSP]
- VSCode: [Visual Studio Code][VSCode]

[Dune]: https://dune.build
[LSP]: https://microsoft.github.io/language-server-protocol
[Merlin]: https://github.com/ocaml/merlin
[OCaml-LSP]: https://github.com/ocaml/ocaml-lsp
[ocamlformat]: https://github.com/ocaml-ppx/ocamlformat
[VSCode]: https://code.visualstudio.com
