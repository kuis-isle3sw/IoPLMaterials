{% include head.html %}

# opam のインストール方法

このドキュメントは本科目の履修者向けに OCaml 開発環境を構築する方法を説明したものである．開発環境の構築のために一番簡単なのは opam という OCaml 用のパッケージマネージャをインストールする方法である．このドキュメントでは，opam の公式ドキュメントのうち[インストール方法](https://opam.ocaml.org/doc/Install.html)に関する部分を（注を付けつつ）翻訳してある．

このページでは opam のインストール方法と設定方法について説明する．その他の opam の使い方についてのは [`opam --help`](https://opam.ocaml.org/doc/man/opam.html) を読むか，あるいは[使い方](https://opam.ocaml.org/doc/Usage.html) のページを参照されたい．

## Windows について

OCaml 開発環境は一般

## opam 1.x からのアップグレード（ほとんどの学生には関係ないはず）

一般には，単に前のバージョンのインストール方法を繰り返せばよい．すなわち，yum や apt や Homebrew や MacPort 等システムのパッケージマネージャからアップグレードするか，バイナリインストーラをもう一度使えばよい．opam `~/.opam` に内部のリポジトリを持っており，必要であればこれを初回にアップグレードする．（インストーラスクリプトを使った場合，自動的にバックアップが取られる．）

シェルスクリプトをアップグレードしてサンドボックスを有効にするには、`opam init --reinit -ni`を実行すればよい．

変更点は[Upgrade guide](https://opam.ocaml.org/doc/Upgrade_guide.html)にまとめてある．


## <a name="Binary-distribution">バイナリディストリビューション</a>

最新の opam を起動して動作させる一番手っ取り早い方法は，[このスクリプト](https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)を，実行することである．以下のコマンドをシェルで実行せよ．
```
sh <(curl -sL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)
```

このスクリプトは，コンピュータのアーキテクチャをチェックし，適切なコンパイル済みバイナリをダウンロードしてインストールする．（古いバージョンを使っている場合はデータをバックアップする．）その後，`opam init`を実行する．

もし `curl` に問題がある場合は[スクリプトをブラウザ等でダウンロード](https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)してから，ダウンロード先で `sh install.sh` を実行すればよい．

以下のプラットフォームについては，コンパイル済みのバイナリが提供されている．
- Linux i686, amd64, arm7, arm64
- OSX (intel 64 bits)
これら以外のプラットフォームにおいては，下で述べる方法を使うこと．

よくわからないスクリプトを自分のコンピュータで実行するのが嫌な人は（良い見識である）[このページ](https://github.com/ocaml/opam/releases) から自分のプラットフォームに適したバイナリをダウンロードし，実行可能パスの下に置いて（あるいは環境変数 PATH にダウンロードしたファイルが置いてあるパスを入れて），ダウンロードしたファイルを実行可能にして（`chmod u+x <ダウンロードしたファイル>`）以下を実行する．

```
sudo install <ダウンロードしたファイル> /usr/local/bin/opam
```

> なお，このスクリプトはユーザが自分のコンピュータに opam 実行環境を構築するためのものであり，CI向けではない．CI に使いたい場合は[Dockerイメージ](https://hub.docker.com/r/ocaml/opam2/)を使用すること．

## システムのパッケージシステムを使う

これは， **もし自分のディストリビューションのパッケージシステムで opam が利用可能で，かつそれが最新であれば** オススメの方法である．（**逆に言えば，そうでない場合があるので気をつけなければならない．**）[このページ](https://github.com/ocaml/opam/wiki/Distributions)に，ディストリビューションのパッケージシステムでどのバージョンが入手可能かが書かれているので，チェックすること．以下は現在サポートされているディストリビューションでのインストール方法である．（主要なものだけ翻訳してあるので，自分の使っているディストリビューションが翻訳されていない場合は，講義用 Slack か PandA でリクエストを出すこと．）

### Archlinux

### Debian

opam のバイナリパッケージは
[stable](http://packages.debian.org/jessie/opam)，
[testing](http://packages.debian.org/stretch/opam)，
[unstable](http://packages.debian.org/sid/opam)，では公式のリポジトリから利用可能である．
以下のコマンドを実行すればよい．

```
apt-get install opam
```

### [Exherbo](http://exherbo.org)


### [Fedora](http://fedoraproject.org), [CentOS](http://centos.org) and RHEL

Fedora の opam パッケージは以下のコマンドでインストールできる．

```
dnf install opam
```

現在 CentOS/RHEL のパッケージはない．上記のビルド済みバイナリを使うか，ソースファイルからビルドすること．

### Mageia

### OpenBSD

### FreeBSD

### OSX (Mac)

[homebrew](http://mxcl.github.com/homebrew/) か [MacPorts](http://www.macports.org/) をインストールせよ．これは OSX で UNIX 系ツールを使うために使うパッケージシステムである．これを使うとインストールが可能である．それぞれ以下のようにすればよい．

#### Homebrew

```
brew install gpatch
brew install opam
```

#### MacPort

```
port install opam
```

[howto setup Emacs.app](https://github.com/ocaml/opam/wiki/Setup-Emacs.app-on-macosx-for-opam-usage) も読むとよい．

### Ubuntu

**注意: この先に進む前に `cat /etc/os-release` によって表示される情報の `PRETTY_NAME` の値をチェックして，使用中の Ubuntu のバージョンを必ずチェックすること**

#### バージョン 18.04 かそれ以降
現在の `opam` の安定バージョンを含む [ppa](https://launchpad.net/~avsm/+archive/ubuntu/ppa) が提供されている．以下のようにしてインストールせよ．

```
add-apt-repository ppa:avsm/ppa
apt update
apt install opam
```

#### 18.04よりも古いバージョンの場合

[バイナリディストリビューション](#Binary-distribution)を利用せよ．

### Guix & Guix System

## ソースコードからビルドする方法

### ソースコードの入手

opam の最新バージョンのソースコードは Github から入手できる．

* [Opam releases on Github](https://github.com/ocaml/opam/releases)

また，opam が依存しているコードを含んだフルのアーカイブも用意されている．

* [2.0.2](https://github.com/ocaml/opam/releases/download/2.0.2/opam-full-2.0.2.tar.gz)
 - MD5: 8780b0dc4209451e21330b6a3e663fe9
 - SHA384: 2ecbdd28840564f873af2f56fcb337d49477f4b63a39ed3878a38eb55bbda67d7561a8deee697c36d7be50ff36a8fe21
* [1.2.2](https://github.com/ocaml/opam/releases/download/1.2.2/opam-full-1.2.2.tar.gz)
 - MD5: 7d348c2898795e9f325fb80eaaf5eae8
 - SHA384: 3a0a7868b5f510c1248959ed350eecacfe1abd886e373fd31066ce10871354010ef057934df026e5fad389ead6c2857d

ダウンロードして `tar xzvf <ダウンロードしたファイル>` で解凍したら，出てくる[`README.md`](https://github.com/ocaml/opam#readme) に書いてある指示に従ってビルドしてインストールせよ．

> opam1.2.2 は OCaml 4.06.0 ではソースからはコンパイルできない．`lib_ext` をコンパイルするために以下のコマンドを使うこと．
> ```
> OCAMLPARAM="safe-string=0,_" make lib-ext
> ```
