{% include head.html %}

# OCaml 処理系のインストール

この科目では実装言語として OCaml を使用する．演習問題を進めるためには，自分のマシンに OCaml プログラムの開発環境を整えることが必須である．以下では，OCaml の開発環境をセットアップする方法を説明する．

## 要するに

- まず[「プログラミング言語」の講義ページの環境設定に関する資料](https://hackmd.io/BGPHkpvJRYCvA2j3D9KVhw)を読んで OPAM をセットアップ
- 以下のコマンドを順に実行．ログの最後に `eval $(opam env)` を実行せよみたいなメッセージが出たら，`eval $(opam env)` を実行してから次のコマンドを実行．
  ```sh
  opam install -y user-setup menhir dune ounit tuareg
      # 上のコマンドが失敗する場合（OPAMのバージョンが古い場合）は以下のコマンドを試すこと。
      # それでもダメならOPAMのバージョンを2.1にしてから上のコマンドを試すこと。
      # opam install depext && opam depext --install user-setup menhir dune ounit tuareg

  opam user-setup install
  ```
- `ocaml` コマンドを実行して，インタプリタが起動すれば OK
- うまく行かなければ以下を読む．それでもダメなら，講義用 Slack か PandA かここに issue を立てて質問．
- OPAM のセットアップのことはさておいても，履修者は講義用 Slack に入っておいてね．

## Windows について

OCaml を Windows で動作させるのは従来かなり大変だったのだが，Windows 10 からは WSL をインストールして Ubuntu 環境を作ることでうまくいくようになっているようである．（末永は Windows を使っていないので，WSL がどのようなものかあまり分かっていない．）それ以前のバージョンの Windows では，[VMWare Workstation Player（個人利用は無料）](https://www.vmware.com/jp/products/workstation-player.html) や [VirtualBox（無料）](https://www.virtualbox.org/) 等を用いて，Linux 等の UNIX 系 OS の仮想環境を作った上で，その中で OCaml をインストールして開発を進めることになる．いずれにしても，まず[「プログラミング言語」の講義ページの環境設定に関する資料](https://hackmd.io/BGPHkpvJRYCvA2j3D9KVhw)を読んでセットアップすること．

というわけで，以下では，macOS か UNIX 系の環境があると仮定して話が進む．

## OCaml のパッケージマネージャ OPAM をインストールする

[OPAM](https://opam.ocaml.org/) は OCaml のパッケージマネージャである．（ところで，Google で日本語を使う設定にしておいて OPAM を検索すると，[大分県立美術館](http://www.opam.jp/)が最初にヒットする．いつか行ってみたいものである．）これを導入するのが OCaml の開発環境を作る上で一番の早道である．

OPAM のページに [OPAM のインストール方法](https://opam.ocaml.org/doc/Install.html) が載っている．基本的にはこれを読んでほしいのだが，一応2020年4月5日時点の内容を[和訳](install_opam.jp.md)しておいた．こっちを読んでもよい．

## OPAM の初期設定

OPAM を使うには初期設定が必要である．[「プログラミング言語」の講義ページの環境設定に関する資料](https://hackmd.io/BGPHkpvJRYCvA2j3D9KVhw)に書いてある通りにやればよいが，ここにも実行すべきコマンドを書いておく．

```sh
opam init -y
opam switch create 4.14.0
eval $(opam env)
```

もしくは

```sh
opam init -y --disable-sandboxing
opam switch create 4.14.0
eval $(opam env)
```

`--disable-sandboxing` は,Windows Cygwin,もしくはWSL1にインストールするならば必須．
WSL2はDocker for Mac/Windowsなどのように完全なLinuxカーネルなので,opamの全ての機能が利用可能.

## 授業に必要なライブラリやツールのインストール

以下のコマンドを順に実行しよう．

```sh
opam install -y user-setup menhir dune ounit tuareg
opam user-setup install
```

各コマンドの意味は次の通り．

- `opam install -y user-setup menhir dune ounit tuareg`: 以下のソフトウェアをインストールする
  - `menhir`: 構文解析ツール
  - `dune`: 自動ビルドツール
  - `ounit`: ユニットテストツール
  - `user-setup`: `.bash_profile` や `.emacs` のような個人設定ファイルの書き換えを自動で行ってくれる．

### 古いOPAM（バージョン2.0以前）を使用している場合
古いOPAM（バージョン2.0以前）を使用している場合、`opam install`コマンドが失敗することがある。これは、システム側に必要なパッケージをOPAMが自動でインストールしてくれないためである。この場合は、次のコマンドを試す。

```sh
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
  - また, `vscode-ocaml-platform` が必要とする [`ocaml-lsp`](https://github.com/ocaml/ocaml-lsp) を別途インストールする必要がある. 以下の手順でインストールができる.
  ```sh
  opam install ocaml-lsp-server
  ```
  - また,作業ディレクトリに`.ocamlformat`ファイルを(空でもよいので)用意するとインデント等が自動的に整理されてよい.
    - `ocamlformat`をインストールしていない場合はエラーが発生するので,その場合は`opam install ocamlformat`を実行し,`ocamlformat`をインストールする.

## よくある質問

- 毎回`eval $(opam env)`をしないとOCamlを実行できない。
  - `opam init`を`-y`オプションつきで（`opam init -y`あるいは`opam init -y --disable-sandboxing`）実行したか確認する。していない場合は`-y`つきで再度実行する。
  - どうやらこれでも上手く設定が反映されない場合もあるらしい。そういう場合は `~/.profile` や `~/.bash_profile` などに `eval "$(opam env)"` という行を手動で追加する。
    - これらのファイルのどれに書けば良さそうか、は例えば https://blog1.mammb.com/entry/2019/12/01/090000 を参照
