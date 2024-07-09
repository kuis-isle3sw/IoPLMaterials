{% include head.html %}

# opam のインストール方法

このドキュメントは本科目の履修者向けに OCaml 開発環境を構築する方法を説明したものである．開発環境の構築のために一番簡単なのは opam という OCaml 用のパッケージマネージャをインストールする方法である．このドキュメントでは，opam の公式ドキュメントのうち[インストール方法](https://opam.ocaml.org/doc/Install.html)に関する部分を（注を付けつつ）翻訳してある．

このページでは opam のインストール方法と設定方法について説明する．その他の opam の使い方についてのは [`opam --help`](https://opam.ocaml.org/doc/man/opam.html) を読むか，あるいは[使い方](https://opam.ocaml.org/doc/Usage.html) のページを参照されたい．

## Windows について

OCaml 開発環境は一般

## opam 1.x からのアップグレード（ほとんどの学生には関係ないはず）

一般には，単に前のバージョンのインストール方法を繰り返せばよい．すなわち，yum や apt や Homebrew や MacPorts 等システムのパッケージマネージャからアップグレードするか，バイナリインストーラをもう一度使えばよい．opam は `~/.opam` に内部のリポジトリを持っており，必要であればこれを初回にアップグレードする．（インストーラスクリプトを使った場合，自動的にバックアップが取られる．）

シェルスクリプトをアップグレードしてサンドボックスを有効にするには、`opam init --reinit -ni`を実行すればよい．

変更点は[Upgrade guide](https://opam.ocaml.org/doc/Upgrade_guide.html)にまとめてある．


## <a name="Binary-distribution">バイナリディストリビューション</a>

最新の opam を起動して動作させる一番手っ取り早い方法は，[このスクリプト](https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)を，実行することである．以下のコマンドをシェルで実行せよ．
```sh
sh <(curl -sL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)
```

このスクリプトは，コンピュータのアーキテクチャをチェックし，適切なコンパイル済みバイナリをダウンロードしてインストールする．（古いバージョンを使っている場合はデータをバックアップする．）その後，`opam init`を実行する．

もし `curl` に問題がある場合は[スクリプトをブラウザ等でダウンロード](https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)してから，ダウンロード先で `sh install.sh` を実行すればよい．

以下のプラットフォームについては，コンパイル済みのバイナリが提供されている．
- Linux i686, amd64, arm7, arm64
- OSX (intel 64 bits)
これら以外のプラットフォームにおいては，下で述べる方法を使うこと．

よくわからないスクリプトを自分のコンピュータで実行するのが嫌な人は（良い見識である）[このページ](https://github.com/ocaml/opam/releases) から自分のプラットフォームに適したバイナリをダウンロードし，実行可能パスの下に置いて（あるいは環境変数 PATH にダウンロードしたファイルが置いてあるパスを入れて），ダウンロードしたファイルを実行可能にして（`chmod u+x <ダウンロードしたファイル>`）以下を実行する．

```sh
sudo install <ダウンロードしたファイル> /usr/local/bin/opam
```

> なお，このスクリプトはユーザが自分のコンピュータに opam 実行環境を構築するためのものであり，CI向けではない．CI に使いたい場合は[Dockerイメージ](https://hub.docker.com/r/ocaml/opam2/)を使用すること．

## システムのパッケージシステムを使う

これは， **もし自分のディストリビューションのパッケージシステムで opam が利用可能で，かつそれが最新であれば** オススメの方法である．（**逆に言えば，そうでない場合があるので気をつけなければならない．**）[このページ](https://opam.ocaml.org/doc/Distribution.html)に，ディストリビューションのパッケージシステムでどのバージョンが入手可能かが書かれているので，チェックすること．以下は現在サポートされているディストリビューションでのインストール方法である．（主要なものだけ翻訳してあるので，自分の使っているディストリビューションが翻訳されていない場合は，講義用 Slack か PandA でリクエストを出すこと．）

### Arch Linux

[opam](https://www.archlinux.org/packages/community/x86_64/opam/) パッケージは公式ディストリビューションで利用可能である．
以下のコマンドを実行すればよい．

```sh
pacman -S opam
```

開発版を使いたい場合は [opam-git](https://aur.archlinux.org/packages/opam-git/) パッケージが [AUR](https://aur.archlinux.org/) にある．
[yay](https://github.com/Jguer/yay) がインストールされているなら，以下のコマンドを実行すればよい．

```sh
yay -S opam-git
```

### Debian

opam のバイナリパッケージは
[stable](https://packages.debian.org/stable/ocaml/opam)，
[testing](https://packages.debian.org/testing/ocaml/opam)，
[unstable](https://packages.debian.org/unstable/ocaml/opam)，では公式のリポジトリから利用可能である．
以下のコマンドを実行すればよい．

```sh
apt install opam
```

### [Exherbo](https://exherbo.org)

[dev-ocaml/opam](https://git.exherbo.org/summer/packages/dev-ocaml/opam/index.html) パッケージはopam 1.x である．
[バイナリディストリビューション](#Binary-distribution)を利用せよ．

### [Fedora](https://fedoraproject.org), [CentOS](https://centos.org) and RHEL

Fedora の opam パッケージは以下のコマンドでインストールできる．

```sh
dnf install opam
```

現在 CentOS/RHEL のパッケージはない．上記のビルド済みバイナリを使うか，ソースファイルからビルドすること．

### Mageia

Mageia の opam パッケージは以下のコマンドでインストールできる．

```sh
urpmi opam
```

### OpenBSD
OpenBSD の opam パッケージは以下のコマンドでインストールできる．

```sh
pkg_add opam
```

### FreeBSD

opam は FreeBSD 11 以上の Ports/Packages Collection で利用可能である．

```sh
cd /usr/ports/devel/ocaml-opam
make install
```

### macOS (Mac)

[homebrew](https://brew.sh/) か [MacPorts](https://www.macports.org/) をインストールせよ．これは macOS で UNIX 系ツールを使うために使うパッケージシステムである．これを使うとインストールが可能である．それぞれ以下のようにすればよい．

#### Homebrew

```sh
brew install gpatch
brew install opam
```

#### MacPorts

```sh
port install opam
```

<!--[howto setup Emacs.app](https://github.com/ocaml/opam/wiki/Setup-Emacs.app-on-macosx-for-opam-usage) も読むとよい． -->
<!-- opam wiki 削除に伴いリンク切れ -->

### Ubuntu

**注意: この先に進む前に `cat /etc/os-release` によって表示される情報の `PRETTY_NAME` の値をチェックして，使用中の Ubuntu のバージョンを必ずチェックすること**

#### バージョン 19.04 以降
最新のバージョンに近い `opam` が公式リポジトリにて提供されている．以下のコマンドを実行すればよい．

```sh
apt install opam
```

#### バージョン 18.04 と 18.10
公式リポジトリより新しい `opam` [ppa](https://launchpad.net/~avsm/+archive/ubuntu/ppa) が提供されているが，更新が途絶えている．以下のようにしてインストールせよ．

```sh
add-apt-repository ppa:avsm/ppa
apt update
apt install opam
```

#### 18.04よりも古いバージョンの場合

[バイナリディストリビューション](#Binary-distribution)を利用せよ．

### Guix & Guix System

[Guix](https://guix.gnu.org/) の opam パッケージは以下のコマンドでインストールできる．

```sh
guix install opam
```

## ソースコードからビルドする方法

### ソースコードの入手

opam の最新バージョンのソースコードは Github から入手できる．

* [Opam releases on Github](https://github.com/ocaml/opam/releases)

また，opam が依存しているコードを含んだフルのアーカイブも用意されている．

* [2.0.7](https://github.com/ocaml/opam/releases/download/2.0.7/opam-full-2.0.7.tar.gz)
 - MD5: d784c5670de657905c55db715044deca
 - SHA384: 19d4ddb625c97e5aa6e7ea7f68699d9f498d406f5270fec0dbbdd96f1c3a43f857e18f0a411f81fd55e91d8a36f6372e
* [1.2.2](https://github.com/ocaml/opam/releases/download/1.2.2/opam-full-1.2.2.tar.gz)
 - MD5: 7d348c2898795e9f325fb80eaaf5eae8
 - SHA384: 3a0a7868b5f510c1248959ed350eecacfe1abd886e373fd31066ce10871354010ef057934df026e5fad389ead6c2857d

ダウンロードして `tar xzvf <ダウンロードしたファイル>` で解凍したら，出てくる[`README.md`](https://github.com/ocaml/opam#readme) に書いてある指示に従ってビルドしてインストールせよ．

> opam1.2.2 は OCaml 4.06.0 ではソースからはコンパイルできない．`lib_ext` をコンパイルするために以下のコマンドを使うこと．
> ```sh
> OCAMLPARAM="safe-string=0,_" make lib-ext
> ```
