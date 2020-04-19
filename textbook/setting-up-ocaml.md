{% include head.html %}

# OCaml 処理系のインストール

この科目では実装言語として OCaml を使用する．演習問題を進めるためには，自分のマシンに OCaml プログラムの開発環境を整えることが必須である．以下では，OCaml の開発環境をセットアップする方法を説明する．

## 要するに

- まず[「プログラミング言語」の講義ページの環境設定に関する資料](http://www.fos.kuis.kyoto-u.ac.jp/~igarashi/class/pl/setup.html)を読んで OPAM をセットアップ
- 以下のコマンドを順に実行．ログの最後に `eval $(opam env)` を実行せよみたいなメッセージが出たら，`eval $(opam env)` を実行してから次のコマンドを実行．
  ```
  opam install depext
  opam install user-setup
  opam depext menhir dune ounit
  opam install menhir dune ounit tuareg
  opam user-setup install
  ```
- `ocaml` コマンドを実行して，インタプリタが起動すれば OK
- うまく行かなければ以下を読む．それでもダメなら，講義用 Slack か PandA かここに issue を立てて質問．
- OPAM のセットアップのことはさておいても，履修者は講義用 Slack に入っておいてね．

## Windows について

OCaml を Windows で動作させるのは従来かなり大変だったのだが，Windows 10 からは WSL をインストールして Ubuntu 環境を作ることでうまくいくようになっているようである．（末永は Windows を使っていないので，WSL がどのようなものかあまり分かっていない．）それ以前のバージョンの Windows では，[VMWare Workstation Player（個人利用は無料）](https://www.vmware.com/jp/products/workstation-player.html) や [VirtualBox（無料）](https://www.virtualbox.org/) 等を用いて，Linux 等の UNIX 系 OS の仮想環境を作った上で，その中で OCaml をインストールして開発を進めることになる．いずれにしても，まず[「プログラミング言語」の講義ページの環境設定に関する資料](http://www.fos.kuis.kyoto-u.ac.jp/~igarashi/class/pl/setup.html)を読んでセットアップすること．

というわけで，以下では，MacOS か UNIX 系の環境があると仮定して話が進む．

## OCaml のパッケージマネージャ OPAM をインストールする

[OPAM](https://opam.ocaml.org/) は OCaml のパッケージマネージャである．（ところで，Google で日本語を使う設定にしておいて OPAM を検索すると，[大分県立美術館](http://www.opam.jp/)が最初にヒットする．いつか行ってみたいものである．）これを導入するのが OCaml の開発環境を作る上で一番の早道である．

OPAM のページに [OPAM のインストール方法](https://opam.ocaml.org/doc/Install.html) が載っている．基本的にはこれを読んでほしいのだが，一応2020年4月5日時点の内容を[和訳](install_opam.jp.md)しておいた．こっちを読んでもよい．

## OPAM の初期設定

OPAM を使うには初期設定が必要である．[「プログラミング言語」の講義ページの環境設定に関する資料](http://www.fos.kuis.kyoto-u.ac.jp/~igarashi/class/pl/setup.html)に書いてある通りにやればよいが，ここにも実行すべきコマンドを書いておく．

```
opam init -y --disable-sandboxing
opam switch create 4.10.0
eval $(opam env)
```

最初のコマンド `opam init -y --disable-sandboxing` についているオプション `--disable-sandboxing` は，WSL 上にインストールするならば必須，そうでなければつけなくてもよいはず．

## 授業に必要なライブラリやツールのインストール

以下のコマンドを順に実行しよう．

```
opam install depext
opam install user-setup
opam depext menhir dune ounit
opam install menhir dune ounit tuareg
opam user-setup install
```

各コマンドの意味は次の通り．

- `opam install depext`: `depext` というツールをインストール．これは `opam` があるライブラリをインストールしようとしたときに，そのライブラリがシステムのパッケージマネージャでインストールしないと入らないようなライブラリに依存していた場合に，それらの依存先ライブラリのリストを返してくれる．
- `opam install user-setup`: `user-setup` というツールをインストール．`.bash_profile` や `.emacs` のような個人設定ファイルの書き換えを自動で行ってくれる．
- `opam depext menhir dune ounit`: `menhir`（構文解析ツール）`dune`（自動ビルドツール）, `ounit`（ユニットテストツール）というツール群が依存しているシステム側のライブラリをチェックする．必要ならばインストールする．
- `opam install menhir dune ounit`: `menhir`, `dune`, `ounit` をインストール．

## 便利情報

- Emacs を使う人は `tuareg-mode` を使うとよい．`opam install tuareg` を実行して `opam user-setup install` を実行．
- Emacs と Vim では `merlin` が便利である．これがあるとエディタが IDE になる．`opam install merlin` を実行してから `opam user-setup install` を実行．
  - Sublime-Text バージョンもベータ版として提供されている
- VSCode で OCaml を使う場合には [`vscode-ocaml-platform`](https://github.com/ocamllabs/vscode-ocaml-platform) を使うとよい. 
  - また, `vscode-ocaml-platform` が必要とする [`ocaml-lsp`](https://github.com/ocaml/ocaml-lsp) を別途インストール必要がある. 以下の手順でインストールができる. 
  ```bash
  $ opam pin add ocaml-lsp-server https://github.com/ocaml/ocaml-lsp.git
  $ opam install ocaml-lsp-server
  ```
  - また,作業ディレクトリに`.ocamlformat`ファイルを(空でもよいので)用意するとインデント等を自動的に整理されてよい.