{% include head.html %}

# 京都大学工学部専門科目「プログラミング言語処理系」講義資料

## お知らせ

- 6月13日: [4.7: 多相的 `let` の型推論](textbook/chap04-7.md)の説明が結構間違っていたのでこっそり修正しました．
- 6月2日: 演習問題に問題番号をつけました．
- 5月18日: 今年は中間試験を行いません．成績評価については別途講義で説明した通りとなります．
- **4月5日: 講義について重要なお知らせがあります．KULASIS と PandA をチェックしてください．また，履修を検討している人は講義用 Slack ワークスペースに入ってください．**
- 3月4日: 2020年の講義資料ページを作りました．

## 学習の仕方

_計算機科学コースの学生には講義中に別途やり方を指示します．（実験3SWもやるので．）_

- [この講義資料の GitHub のページ](https://github.com/kuis-isle3sw/IoPLMaterials)からリポジトリを clone しましょう．
- [OCaml が使えるように環境を設定](textbook/setting-up-ocaml.md)しましょう．
- 落ちてきたソースコード中の `textbook/interpreter/` ディレクトリの中にインタプリタのソースコードが入っているので，`dune`コマンドでビルドしましょう．
- [教科書](#textbook)を読みながらもりもり演習問題を解きましょう．
  - 教科書にバグを見つけたら [issue](https://github.com/kuis-isle3sw/IoPLMaterials/issues) で報告しましょう．
  - 講義の履修者は講義用 Slack で質問してもよいですね．
- プログラミング言語強者になりましょう．そのためには．．．
  - なにか自分で言語を作って処理系を作ってみましょう．作った処理系を自慢しましょう．世界中で自作の言語が使われるようになったらいいですね．
  - もしくは，プログラミング言語理論やプログラム検証を勉強してみましょう．
    TODO: 参考文献

## 教科書 <a name="textbook"></a>

（鋭意 Markdown 化中．）

<!-- - [オリエンテーション資料](misc/orientation.md) -->
- [OCaml の環境設定](textbook/setting-up-ocaml.md)
<!--  - [opamのインストール方法](textbook/install_opam.jp.md) -->
- OCaml あまり知らない人向け: 前提となる OCaml の知識を身に付ける．
  - [OCaml 爆速入門 by 五十嵐淳](http://www.fos.kuis.kyoto-u.ac.jp/~igarashi/class/pl/03-ocaml.html)
  - [OCaml で二分探索木を書く by 五十嵐淳](http://www.fos.kuis.kyoto-u.ac.jp/~igarashi/class/pl/04-bst-ocaml.html)
  - [この資料の「多相二分木 in OCaml」のところ](http://www.fos.kuis.kyoto-u.ac.jp/~igarashi/class/pl/09-polymorphism.html)
  - [高階関数 (OCamlに関するところのみ)](http://www.fos.kuis.kyoto-u.ac.jp/~igarashi/class/pl/10-hofuns.html)
- もう少しちゃんとした OCaml のテキスト: [OCaml入門テキスト by 五十嵐淳](textbook/mltext.pdf)
  - _1章は古くなっているので，2章から読むこと_
- プログラミング言語処理系テキスト by 五十嵐淳，馬谷誠二，末永幸平
  - [1章: イントロダクション](textbook/chap01.md)
  - [2章: 概論的な話](textbook/chap02.md)
  - 3章: 型無し MiniML インタプリタの実装
    - [3.1: MiniML1 のシンタックス](textbook/chap03-1.md)
    - [3.2: 各モジュールの機能 (1): `Syntax`, `Eval`, `Environment`, `Cui`](textbook/chap03-2.md)
    - [3.3: 各モジュールの機能 (2): `Parser`, `Lexer`](textbook/chap03-3.md)
    - [3.4: MiniML2: 定義の導入](textbook/chap03-4.md)
    - [3.5: MiniML3: 関数の導入](textbook/chap03-5.md)
    - [3.6: MiniML4: 再帰関数](textbook/chap03-6.md)
    - [3.7: MiniML5 and beyond: やりこみのための演習問題](textbook/chap03-7.md)
  - 4章: 型推論機能付き MiniML インタプリタの実装（あるいは，型システムを用いた形式検証の初歩）
    - [4.1: 静的プログラム検証へのイントロダクション](textbook/chap04-1.md)
    - [4.2: MiniML2 のための型推論 (1): MiniML2 の型システム](textbook/chap04-2.md)
    - [4.3: MiniML2 のための型推論 (2): 型推論アルゴリズム](textbook/chap04-3.md)
    - [4.4: MiniML3,4 のための型推論 (1): Prelude](textbook/chap04-4.md)
    - [4.5: MiniML3,4 のための型推論 (2): 型の等式制約と単一化](textbook/chap04-5.md)
    - [4.6: MiniML3,4 のための型推論 (3): 型推論アルゴリズムの実装](textbook/chap04-6.md)
    - [4.7: 多相的 `let` の型推論](textbook/chap04-7.md)
    - 4.8: やりこみのための演習問題
  - 5章: MiniML コンパイラの実装
    - [5.1: 能書き](textbook/chap05-1.md)
    - [5.2: ソース言語 MiniML4- と中間言語$\mathcal{C}$](textbook/chap05-2.md)
    - [5.3: MiniML4- から$\mathcal{C}$への変換$\mathcal{I}$](textbook/chap05-3.md)
    - [5.4: MIPS アセンブリ言語入門](textbook/chap05-4.md)
    - [5.5: 執筆中](textbook/chap05-5.md)
  - 6章: 字句解析と構文解析のためのアルゴリズム

## リンク集

- [実験3ホームページ](https://kuis-isle3sw.github.io/kuis-isle3sw-portal/)
- [専門科目「プログラミング言語」ホームページ](https://github.com/aigarashi/PL-LectureNotes)
  - [の中の OCaml のページ（最低このくらいはわかってないとキツイ）](http://www.fos.kuis.kyoto-u.ac.jp/~igarashi/class/pl/03-ocaml.html)
  - [の中の OCaml で二分探索木を書くページ（これもわかってないとキツイ）](http://www.fos.kuis.kyoto-u.ac.jp/~igarashi/class/pl/04-bst-ocaml.html)
- [OCaml の標準ライブラリの話](textbook/chap03-2.md#standardLib)を教科書に書いてあるので読んでおくととても良い違いない．

## 講義に関する情報

- 講義をする人: 末永幸平（[@ksuenaga](http://www.twitter.com/ksuenaga/), [Researchmap](https://researchmap.jp/ksuenaga/)）
- 講義が行われる時間: 月曜2限
- 講義が行われる場所: 総合研究7号館講義室1
- Language used in the class: Japanese

<!--
jekyll 等メモ:

- Gemfile を置いて bundle exec jekyll s を実行．出てきた URL を開く．
  - 初回は bundle install が必要?
- 各ファイルのはじめに {% include head.html %} がおいてある．_includes/head.html をここに読み込むことを表してる．
  - head.html には MathJax を使うための設定等が書いてある．
-->

<!-- ## 講義予定 -->

<!-- 一部の資料と過去問は PandA で配布するので，PandA を見られる状態にしておくこと． -->
   
<!-- | 日付 | 内容 | 対応する教科書中の場所 | -->
<!-- |------|-----------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------| -->
<!-- | 4/13 | オリエンテーション，イントロダクション，OCaml復習| [教科書1章](textbook/chap01.md), [教科書2章](textbook/chap02.md), [OCaml入門テキスト](textbook/mltext.pdf) | -->
<!-- | 4/20 | OCaml復習| [OCaml入門テキスト](textbook/mltext.pdf) | -->
<!-- | 4/27 | | | -->
<!-- | 5/11 | | | -->
<!-- | 5/18 | | | -->
<!-- | 5/25 | <s>中間試験</s>今年度はやりません | | -->
<!-- | 6/1 | | | -->
<!-- | 6/8 |  | | -->
<!-- | 6/15 | | | -->
<!-- | 6/22 | | | -->
<!-- | 6/29 | | | -->
<!-- | 7/6 | | | -->
<!-- | 7/13 | | | -->
<!-- | 7/20 | | | -->
<!-- | ?/?? | 期末試験 | | -->

<!-- ## OCaml の設定方法 <a name="ocaml"></a> -->

<!-- OCaml のパッケージシステムである OPAM を用いてインストールするのが簡単である．[このページ](https://opam.ocaml.org/doc/Install.html) を読んでインストールすること． -->
<!-- 以下は簡便のために抜粋したものであるが，最新の情報ではないかもしれないので，できれば上記ページを読むこと． -->

<!-- - `sh <(curl -sL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)` -->
<!--   - `curl` 関係のエラーが出る場合は https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh のスクリプトをダウンロードして `sh install.sh` を実行． -->
<!--   - 各自のパッケージ管理システム（Mac なら homebrew や macport，Linux なら yum や apt 等）を用いて opam をインストールしてもよい． -->
<!-- - _以下では実行ログの最後に`eval $(opam env)`を実行せよと書いてあることがあるので，その時は次の作業に移る前に `eval $(opam env)` を実行すること．_ -->
<!-- - `opam init` を実行 -->
<!--   - 途中設定ファイルに opam が書き込んでよいか聞かれる．全部 `y` にしておくと楽は楽である． -->
<!-- - `opam switch create 4.07.1`を実行 -->
<!-- - `opam install depext` -->
<!-- - `opam install user-setup` -->

<!-- 演習にはいくつかのパッケージが必要である．OPAM が入った状態であれば，以下のコマンドを順に実行することでこれらのパッケージを導入できる． -->

<!-- - `opam depext menhir dune ounit` -->
<!-- - `opam install menhir dune ounit` -->

<!-- 便利情報がいくつかある． -->

<!-- - Emacs を使う人は tuareg-mode を使うとよい．`opam install tuareg` のあとに `opam user-setup install` を実行． -->
<!-- - emacs と vim では [merlin](https://ocaml.github.io/merlin/) が便利である．これがあるとエディタが IDE になる．`opam install merlin` のあとに `opam user-setup install` を実行． -->
<!--   - Sublime-Text バージョンも[ベータ版](https://github.com/let-def/sublime-text-merlin)として提供されている  -->
<!-- - VSCode で OCaml を使う方法がいくつかあるらしい．（調べた人は情報ください．） -->
  
