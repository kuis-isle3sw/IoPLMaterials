{% include head.html %}

# 京都大学工学部専門科目「プログラミング言語処理系」講義資料

講義 Web ページは[こちら](https://kuis-isle3sw.github.io/IoPLMaterials)です．

## お知らせ

- 4月1日: 2025年度版ページにしました．

## 2024年度 講義予定

| 回 | 日付 (mm/dd) | 内容（予定） | 資料 | その他 |
| --- | --- | --- | --- | --- |
| 01 | 4/14 | イントロダクション | [1章: イントロダクション](textbook/chap01.md) [2章: 概論的な話](textbook/chap02.md) |  |
| 02 | 04/21 | インタプリタ 1 | [3.1: MiniML1 のシンタックスとセマンティックス](textbook/chap03-1.md) [3.2: 各モジュールの機能 (1): `Syntax`, `Eval`, `Environment`, `Cui`](textbook/chap03-2.md) [3.3: 各モジュールの機能 (2): `Parser`, `Lexer`](textbook/chap03-3.md) |  |
| 03 | 04/28 | インタプリタ 2 | [3.4: MiniML2: 定義の導入](textbook/chap03-4.md) |  |
| 04 | 05/12 | インタプリタ 3 | [3.5: MiniML3: 関数の導入](textbook/chap03-5.md) [3.6: MiniML4: 再帰関数](textbook/chap03-6.md) |  |
| 05 | 05/19 | 型システム 1 | [4.1: 静的プログラム検証へのイントロダクション](textbook/chap04-1.md) [4.2: MiniML2 のための型推論 (1): MiniML2 の型システム](textbook/chap04-2.md) |  |
| 06 | 05/26 | 型システム 2 | [4.3: MiniML2 のための型推論 (2): 型推論アルゴリズム](textbook/chap04-3.md) [4.4: MiniML3,4 のための型推論 (1): Prelude](textbook/chap04-4.md) |  |
| 07 | 06/02 | 型システム 3 | [4.5: MiniML3,4 のための型推論 (2): 型の等式制約と単一化](textbook/chap04-5.md) [4.6: MiniML3,4 のための型推論 (3): 型推論アルゴリズムの実装](textbook/chap04-6.md) |  |
| 08 | 06/09 | 型システム 4 | [4.7: 多相的 `let` の型推論](textbook/chap04-7.md) |  |
| 09 | 06/16 | 字句解析 |  | （字句解析と構文解析パートの資料は PandA で配布する） |
| 10 | 06/23 | LL(1)構文解析 |  |  |
| 11 | 06/30 | LR(0)構文解析 |  |  |
| 12 | 07/07 | LR(0), SLR(1), LR(1)構文解析 |  |  |
| 13 | 07/14 | コンパイラ 1 | [5.1: 能書き](textbook/chap05-1.md) [5.2: ソース言語 MiniML4- と中間言語$\mathcal{C}$](textbook/chap05-2.md) [5.3: MiniML4- から$\mathcal{C}$への変換$\mathcal{I}$](textbook/chap05-3.md) [5.6: アセンブリ生成](textbook/chap05-6.md) | [5.4: MIPS アセンブリ言語入門](textbook/chap05-4.md) を事前に理解しておくこと |
| 14 | 07/17 | [MinCaml コンパイラ](https://esumii.github.io/min-caml/)概説 |  | [ソースコード](https://github.com/esumii/min-caml)をダウンロードして手元で試しておくとよい |

## レポート等の課題におけるLLMの使用について（履修者向け）

本科目におけるクイズやレポート等の課題においてLLMを使用する場合は、以下に注意してください。
- LLMを使用することを一律に禁止するものではありません。ただし、答案作成の過程で LLM を使用した場合は、その旨を明記した上で、答案に加えて (1) 使用した目的、(2) 使用したプロンプト、(3) 使用したモデル、(4) LLM からの出力、(5) それを踏まえてどのように自分の答案を作成したか、を明記してください。
- 実装課題において初めからから LLM にソースコードを生成させることは学習の効果を大きく下げてしまいます。LLM で正しいプログラムを作成させるためには、（少なくとも現状で普通にアクセスできる LLM においては）効果的なプロンプトを与え、生成されたプログラムの正しさを判断するために、ある程度の実装スキルが自身に必要です。将来 LLM をプログラム作成により効果的に使いこなすためにも、まずは自分でプログラムを書いてみることをお勧めします。

## 学習の仕方

_以下の記述は履修者でない方々向けです。履修者には課題にとりくむためのリポジトリを作成して、そこで課題に取り組んでもらいますので、授業で指示するまで実装には手をつけないでおいてください。_

- [OCaml が使えるように環境を設定](HACKING.md)しましょう．
- [教科書](https://kuis-isle3sw.github.io/IoPLMaterials/)を読みながらもりもり演習問題を解きましょう．
  - 教科書にバグを見つけたら [issue](https://github.com/kuis-isle3sw/IoPLMaterials/issues) で報告しましょう．
  - 講義の履修者は講義用 Slack で質問してもよいですね．
- プログラミング言語強者になりましょう．そのためには．．．
  - なにか自分で言語を作って処理系を作ってみましょう．作った処理系を自慢しましょう．世界中で自作の言語が使われるようになったらいいですね．
  - もしくは，プログラミング言語理論やプログラム検証を勉強してみましょう．たとえば以下の文献が参考になります。
    - Benjamin C. Pierce: [Types and Programming Languages](https://kuline.kulib.kyoto-u.ac.jp/opac/opac_link/bibid/EB13374688)
      - 本講義で与えた型システムの理論的背景を学ぶための教科書。プログラミング言語の形式的意味論の導入から関数型言語
      - 和訳: 遠藤 侑介; 住井 英二郎; 酒井 政裕; 今井 敬吾; 黒木 裕介; 今井 宜洋; 才川 隆文; 今井 健男 訳: [型システム入門 : プログラミング言語と型の理論](https://kuline.kulib.kyoto-u.ac.jp/opac/opac_link/bibid/EB07914363)
    - Glynn Winskel: [The Formal Semantics of Programming Languages---An Introduction](https://kuline.kulib.kyoto-u.ac.jp/opac/opac_link/bibid/EB13371609)
      - 本講義では自然言語でインフォーマルに与えているプログラミング言語の意味論を数学的に与え、プログラムの性質について厳密に議論する手法に関する教科書。
      - 和訳: 勝股 審也; 中澤 巧爾; 西村 進; 前田 敦司; 末永 幸平 訳: [プログラミング言語の形式的意味論入門](https://kuline.kulib.kyoto-u.ac.jp/opac/opac_link/bibid/BB08694195)

## 目次

<!-- - [オリエンテーション資料](misc/orientation.md) -->

- [OCaml の環境設定](HACKING.md) - [(講義スライド)](textbook/slides/ocaml.pdf)
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
    - [5.5: 仮想マシンコードとその生成](textbook/chap05-5.md)
    - [5.6: アセンブリ生成](textbook/chap05-6.md)
    - [5.7: $\mathcal{C}$の最適化](textbook/chap05-7.md)（まだ）
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

## (F)AQ

この講義では毎週履修者からの質問やコメントを受け付けており，質問に対しては回答を次週までに書いて公開しているのですが，その中で他の学習者にとっても有用であると思われるものを[(F)AQ](textbook/FAQ.md)としてまとめました．誤っている情報や追記すべき情報があれば Issue を立てたり PR を出したりしてもらえればと思います．

## 講義に関する情報

- 講義をする人: 末永幸平（[@ksuenaga](http://www.twitter.com/ksuenaga/), [Researchmap](https://researchmap.jp/ksuenaga/)）
- 講義が行われる時間: 月曜2限
- 講義が行われる場所: 総合研究7号館講義室1
- Language used in the class: Japanese

## ご寄付のお願い

本学学生以外の方で，もしこのページのマテリアルが有用であるとお思いになられたら，是非[京都大学基金](https://payment.kikin.kyoto-u.ac.jp/kyoto-u/entry.php?purposeCode=406000)へのご寄付をいただけると幸いです．運営費交付金が年々削減される中で，大学教員が教育と研究活動を両立させつつ，学外の方々にも有用な情報を発信し続けられるよう，ご支援をいただけると大変ありがたく思います．[京都大学へのご寄付に対しましては，法人税法，所得税法による税制上の優遇措置が受けられます．](https://www.kikin.kyoto-u.ac.jp/exemption/)

特に以下の基金へのご寄付をいただけますと大変ありがたいです．

- [京都大学修学支援基金](https://www.kikin.kyoto-u.ac.jp/contribution/student/): 意欲と能力のある学生が経済的理由で修学・進学を断念することなく，希望する教育を受けられるようにすることを目的とした基金です．
- [男女共同参画支援たちばな基金](https://www.kikin.kyoto-u.ac.jp/contribution/tachibana/): 男女共同参画支援を推進するための基金で，育児等支援の充実，保育施策の充実，男女共同参画推進事業の充実を目的とした基金です．
- [次世代白眉等若手研究者はぐくみ基金](https://www.kikin.kyoto-u.ac.jp/contribution/hagukumi/): 京都大学における、次世代の若手研究者の活動を支援するための基金です。
- [情報学研究科基金](https://www.kikin.kyoto-u.ac.jp/contribution/informatics/): 情報学研究科における大学院生の学修・研究支援，若手研究者支援，研究支援を目的とした基金です．
