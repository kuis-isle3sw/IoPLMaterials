{% include head.html %}

# 京都大学工学部専門科目「プログラミング言語処理系」講義資料

## お知らせ

- 7月24日: 講義スライドを一部公開しました．
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
- [OCaml の環境設定](textbook/setting-up-ocaml.md) [講義スライド](textbook/slides/ocaml.pdf)
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
  - [2章: 概論的な話](textbook/chap02.md) [講義スライド](textbook/slides/intro.pdf)
  - 3章: 型無し MiniML インタプリタの実装 [講義スライド](textbook/slides/interpreter.pdf)
    - [3.1: MiniML1 のシンタックス](textbook/chap03-1.md)
    - [3.2: 各モジュールの機能 (1): `Syntax`, `Eval`, `Environment`, `Cui`](textbook/chap03-2.md)
    - [3.3: 各モジュールの機能 (2): `Parser`, `Lexer`](textbook/chap03-3.md)
    - [3.4: MiniML2: 定義の導入](textbook/chap03-4.md)
    - [3.5: MiniML3: 関数の導入](textbook/chap03-5.md)
    - [3.6: MiniML4: 再帰関数](textbook/chap03-6.md)
    - [3.7: MiniML5 and beyond: やりこみのための演習問題](textbook/chap03-7.md)
  - 4章: 型推論機能付き MiniML インタプリタの実装（あるいは，型システムを用いた形式検証の初歩）[講義スライド](textbook/slides/typing.pdf)
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
    - [5.5: 仮想マシンコードとその生成](textbook/chap05-5.md)
    - [5.6: アセンブリ生成](textbook/chap05-6.md)
    - 5.7: $\mathcal{C}$の最適化（まだ）
    - 5.8: $\mathcal{V}$におけるデータフロー解析（まだ）
    - 5.9: レジスタ割り付け（まだ）
    - 5.10: 高階関数（まだ）
    - 5.11: 動的メモリ管理（やるの？）
    - 5.12: オブジェクト指向（やるの？）
    - 5.13: 分割コンパイルとリンカ（やるの？）
  - 6章: 字句解析と構文解析のためのアルゴリズム（まだ．今学期はスライドで講義済み．）
    - 7.1: 字句解析
    - 7.2: LL(1)アルゴリズム
    - 7.3: LR(0)アルゴリズム
    - 7.4: SLR(1), LR(1)アルゴリズム
  - 7章: さらに学びたい人のための参考文献

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
- 各ファイルのはじめに \{\% include head.html \%\} がおいてある．`_includes/head.html` をここに読み込むことを表してる．
  - head.html には MathJax を使うための設定等が書いてある．
-->