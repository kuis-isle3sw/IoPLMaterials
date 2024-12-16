# HACKING

## OCaml 処理系のインストール

この科目では実装言語として OCaml を使用する。演習問題を進めるためには、自分のマシンに OCaml プログラムの開発環境を整えることが必須である。以下では、OCaml の開発環境をセットアップする方法を説明する。

### 1. [opam] をインストール

> このガイドでは [opam] 2.2以上を前提としている。2.2よりも古い [opam] バージョンをインストールしている場合は更新する必要がある。

#### Unix

```sh
bash -c "sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)"
```

#### Windows

```powershell
Invoke-Expression "& { $(Invoke-RestMethod https://raw.githubusercontent.com/ocaml/opam/master/shell/install.ps1) }"
```

### 2. [opam] の初回セットアップ

- [opam] ルート
  - デフォルトでは `~/.opam` に作成される。
  - [opam] が動作するために必要な設定やデータが保存される場所。
  - パッケージの定義や設定、ダウンロードしたファイルのキャッシュなどが保存される。
- [opam] スイッチ
  - 複数の OCaml 環境を分けて管理するための機能。
  - 異なるプロジェクトやバージョンの OCaml を使い分けたり、パッケージのインストールを分離したり出来る。
  - 各スイッチは独立しており、それぞれの環境に合わせてパッケージを管理することが出来る。
- [opam] グローバルスイッチ
  - デフォルトでは `~/.opam/<switch>` に作成される。
  - システム全体で使用される OCaml 環境を設定する場合に便利。
- [opam] ローカルスイッチ
  - 特定のプロジェクトや作業ディレクトリ内に設定される OCaml 環境。
  - プロジェクトのルートディレクトリ内の `_opam` サブディレクトリに OCaml 関連ファイルやパッケージが入る。

```sh
opam init --bare --no-setup
```

`opam init` コマンドを実行し、[opam] の初回セットアップを実行する。

- `--bare`
  - `opam init` を実行することで通常は [opam] ルートとデフォルトの [opam] グローバルスイッチが作成される。
  - しかし、最近では混乱を避けるために一般的には [opam] グローバルスイッチを使用しないことが推奨されており、ここでは `--bare` オプションを追加することで、デフォルトの [opam] グローバルスイッチを作成しないように設定する。
- `--no-setup`
  - [opam] はオプションの設定次第ではシェルの設定などを自動で追加したりしてくれるが、[direnv] を使用した方法が推奨されるため、ここでは全ての自動設定を無効化する。

### 3. リポジトリをクローン

```sh
git clone git@github.com:kuis-isle3sw/IoPLMaterials.git
cd IoPLMaterials
```

> SSH キーを使った方法でリポジトリをクローンすることが出来ない場合は[こちら](https://docs.github.com/repositories/creating-and-managing-repositories/cloning-a-repository) を参照。

### 4. [direnv] をセットアップ

[direnv] は現在のディレクトリに基づいて環境変数を設定出来るツールであり、[opam] スイッチの管理や、プロジェクト固有の環境のセットアップに特に役立つ。

1. [direnv] をインストール
   - https://direnv.net/docs/installation.html
2. [direnv] をセットアップ
   - https://direnv.net/docs/hook.html
3. `.envrc` を許可
   - `direnv allow` を実行。
   - クローンしたリポジトリ内にある `.envrc` を許可するまで [direnv] は `.envrc` の中身を実行しない。
     - 主にセキュリティのため。

必須のツールではないが、これがあると作業が楽になる。

> - [Zed](https://zed.dev) などの一部エディタでは [OCaml 拡張機能](https://github.com/zed-industries/zed/tree/main/extensions/ocaml) をインストールしても LSP が機能しないことがある。
>   - このような場合には必要なパッケージを全てインストールしていることを確認した上で `opam exec -- zed .` とする必要がある。

### 5. ローカルスイッチを作成

```sh
opam switch create . 5.2.0 --no-install
```

`opam switch create [スイッチ名] [コンパイラ]` コマンドを実行し、[opam] ローカルスイッチを作成する。この時、スイッチ名に絶対または相対のディレクトリを指定すると [opam] ローカルスイッチが作成される。

- `--no-install`
  - [opam] ローカルスイッチを作成する際にローカルパッケージを無視するようにする。
    - 依存関係などは通常 `opam install` コマンドを介してインストールするため、このオプションを追加することによって OCaml コンパイラのみをインストールするようにする。

詳細は `man opam-switch` を実行するとよい。

### 6. 必要な [opam] パッケージをインストール

```sh
opam install . --deps-only --with-dev-setup
```

`opam install [パッケージ名]` を実行し、必要な [opam] パッケージをインストールする。この際、パッケージ名に `*.opam` ファイル、もしくは `*.opam` ファイルを含むディレクトリを指定する事も可能であり、この場合はディレクトリ内に存在する `*.opam` ファイルの中身に基づいて [opam] パッケージがインストールされる。

- `--deps-only`
  - 依存関係のみインストールするために必要。
- `--with-dev-setup`
  - 開発者向けツール ([OCaml-LSP] や [ocamlformat] など) をインストールするために必要。
  - 他にも `--with-doc` や `--with-test` などのオプションなども存在するが、ここでは必要ない。
    - https://opam.ocaml.org/doc/Manual.html#Package-variables

詳細は `man opam-install` を実行するとよい。

### 7. ビルド

#### [direnv] を使用している場合

```sh
dune build
```

#### [direnv] を使用していない場合

```sh
opam exec -- dune build
```

## エディタのセットアップ

### [VSCode]

推奨するのは [VSCode] と、その拡張機能の [OCaml Platform](https://marketplace.visualstudio.com/items?itemName=ocamllabs.ocaml-platform) の組み合わせである。

クローンしたリポジトリに移動し、次のコマンドを実行すると [VSCode] が起動される。

> 事前に `.vscode/settings.json` に次のような設定ファイルを置いておく必要がある。
>
> ```json
> {
>   "ocaml.sandbox": {
>     "kind": "opam",
>     "switch": "${workspaceFolder:IoPLMaterials}"
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
- OPAM: [OCaml Package Manager][opam]
- VSCode: [Visual Studio Code][VSCode]

[direnv]: https://github.com/direnv/direnv
[LSP]: https://microsoft.github.io/language-server-protocol
[Merlin]: https://github.com/ocaml/merlin
[OCaml-LSP]: https://github.com/ocaml/ocaml-lsp
[ocamlformat]: https://github.com/ocaml-ppx/ocamlformat
[opam]: https://github.com/ocaml/opam
[VSCode]: https://code.visualstudio.com
