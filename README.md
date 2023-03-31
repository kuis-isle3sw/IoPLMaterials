{% include head.html %}

# 京都大学工学部専門科目「プログラミング言語処理系」講義資料

講義 Web ページは[こちら](https://kuis-isle3sw.github.io/IoPLMaterials)です．

## お知らせ

- 4月1日: 本科目の履修を検討している人は，必ず[PandAの本科目のページ](https://panda.ecs.kyoto-u.ac.jp/portal/site/2022-110-9128-000/page/23850a9f-f535-41a1-8cb9-147f9cba50bf) をチェックしておいてください．
- 4月1日: 2023年度版ページにしました．

## 学習の仕方

_計算機科学コースの学生には講義中に別途やり方を指示します．（実験3SWもやるので．）_

- [この講義資料の GitHub のページ](https://github.com/kuis-isle3sw/IoPLMaterials)からリポジトリを clone しましょう．
- [OCaml が使えるように環境を設定](textbook/setting-up-ocaml.md)しましょう．
- 落ちてきたソースコード中の `textbook/interpreter/` ディレクトリの中にインタプリタのソースコードが入っているので，`dune`コマンドでビルドしましょう．
- [教科書](https://kuis-isle3sw.github.io/IoPLMaterials/)を読みながらもりもり演習問題を解きましょう．
  - 教科書にバグを見つけたら [issue](https://github.com/kuis-isle3sw/IoPLMaterials/issues) で報告しましょう．
  - 講義の履修者は講義用 Slack で質問してもよいですね．
- プログラミング言語強者になりましょう．そのためには．．．
  - なにか自分で言語を作って処理系を作ってみましょう．作った処理系を自慢しましょう．世界中で自作の言語が使われるようになったらいいですね．
  - もしくは，プログラミング言語理論やプログラム検証を勉強してみましょう．
    TODO: 参考文献

## 教科書 <a name="textbook"></a>

（鋭意 Markdown 化中．）

### リンク

<https://kuis-isle3sw.github.io/IoPLMaterials/>

### 目次

<!-- - [オリエンテーション資料](misc/orientation.md) -->
- [OCaml の環境設定](textbook/setting-up-ocaml.md) [(講義スライド)](textbook/slides/ocaml.pdf)
<!--  - [opamのインストール方法](textbook/install_opam.jp.md) -->
- OCaml あまり知らない人向け: 前提となる OCaml の知識を身に付ける．
  - [OCaml 爆速入門 by 五十嵐淳](http://www.fos.kuis.kyoto-u.ac.jp/~igarashi/class/pl/03-ocaml.html)
  - [OCaml で二分探索木を書く by 五十嵐淳](http://www.fos.kuis.kyoto-u.ac.jp/~igarashi/class/pl/04-bst-ocaml.html)
  - [この資料の「多相二分木 in OCaml」のところ](http://www.fos.kuis.kyoto-u.ac.jp/~igarashi/class/pl/09-polymorphism.html)
  - [高階関数 (OCamlに関するところのみ)](http://www.fos.kuis.kyoto-u.ac.jp/~igarashi/class/pl/10-hofuns.html)
  - [多相性についてもう少し & 例外処理 (OCamlに関するところのみ)](http://www.fos.kuis.kyoto-u.ac.jp/~igarashi/class/pl/11-polyBST.html)
- もう少しちゃんとした OCaml のテキスト: [OCaml入門テキスト by 五十嵐淳](textbook/mltext.pdf)
  - _1章は古くなっているので，2章から読むこと_
- プログラミング言語処理系テキスト by 五十嵐淳，馬谷誠二，末永幸平
  - [1章: イントロダクション](textbook/chap01.md)
  - [2章: 概論的な話](textbook/chap02.md) [(講義スライド)](textbook/slides/intro.pdf)
  - 3章: 型無し MiniML インタプリタの実装 [(講義スライド)](textbook/slides/interpreter.pdf)
    - [3.1: MiniML1 のシンタックス](textbook/chap03-1.md)
    - [3.2: 各モジュールの機能 (1): `Syntax`, `Eval`, `Environment`, `Cui`](textbook/chap03-2.md)
    - [3.3: 各モジュールの機能 (2): `Parser`, `Lexer`](textbook/chap03-3.md)
    - [3.4: MiniML2: 定義の導入](textbook/chap03-4.md)
    - [3.5: MiniML3: 関数の導入](textbook/chap03-5.md)
    - [3.6: MiniML4: 再帰関数](textbook/chap03-6.md)
    - [3.7: MiniML5 and beyond: やりこみのための演習問題](textbook/chap03-7.md)
  - 4章: 型推論機能付き MiniML インタプリタの実装（あるいは，型システムを用いた形式検証の初歩）[(講義スライド)](textbook/slides/typing.pdf)
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
  - 6章: 字句解析と構文解析のためのアルゴリズム（まだ）
    - 7.1: 字句解析
    - 7.2: LL(1)アルゴリズム
    - 7.3: LR(0)アルゴリズム
    - 7.4: SLR(1), LR(1)アルゴリズム
  - 7章: さらに学びたい人のための参考文献
  - 8章: [参考文献](textbook/reference.md)
  - 付録: [問題リンク集](textbook/exercises.md)

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

## ご寄付のお願い

本学学生以外の方で，もしこのページのマテリアルが有用であるとお思いになられたら，是非[京都大学基金](https://payment.kikin.kyoto-u.ac.jp/kyoto-u/entry.php?purposeCode=406000)へのご寄付をいただけると幸いです．運営費交付金が年々削減される中で，大学教員が教育と研究活動を両立させつつ，学外の方々にも有用な情報を発信し続けられるよう，ご支援をいただけると大変ありがたく思います．[京都大学へのご寄付に対しましては，法人税法，所得税法による税制上の優遇措置が受けられます．](https://www.kikin.kyoto-u.ac.jp/exemption/)

特に以下の基金へのご寄付をいただけますと大変ありがたいです．

+ [京都大学修学支援基金](https://www.kikin.kyoto-u.ac.jp/contribution/student/): 意欲と能力のある学生が経済的理由で修学・進学を断念することなく，希望する教育を受けられるようにすることを目的とした基金です．
+ [男女共同参画支援たちばな基金](https://www.kikin.kyoto-u.ac.jp/contribution/tachibana/): 男女共同参画支援を推進するための基金で，育児等支援の充実，保育施策の充実，男女共同参画推進事業の充実を目的とした基金です．
+ [情報学研究科基金](https://www.kikin.kyoto-u.ac.jp/contribution/informatics/): 情報学研究科における大学院生の学修・研究支援，若手研究者支援，研究支援を目的とした基金です．

## ローカル環境でのビルド方法

この資料は [Jekyll](http://jekyllrb-ja.github.io/) を使用して構築されています．動作確認などのためにこの資料をローカル環境で表示させる場合は，[Ruby](https://www.ruby-lang.org/ja/) を導入した上で，次の通りコマンドを実行してください．
```
$ gem install bundler jekyll
$ bundle exec jekyll serve --baseurl '/IoPLMaterials'
```
その後 [http://127.0.0.1:4000/IoPLMaterials/](http://127.0.0.1:4000/IoPLMaterials/) にアクセスしてください。

<!--
Some notes on the documentation:
- build commands:
  ```sh
  ❯ bundle install # required for the first time
  [...]

  ❯ bundle exec jekyll serve --livereload
  [...]
  # Open the local server address and keep editting.
  # The `--livereload` option is particularly helpful to see update immediatelly when you make change.
  ```
- 各ファイルのはじめに \{\% include head.html \%\} がおいてある．`_includes/head.html` をここに読み込むことを表してる．
  - head.html には MathJax を使うための設定等が書いてある．
-->
