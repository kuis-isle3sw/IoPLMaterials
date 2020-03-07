# IoPLMaterials
Materials for the class "Implementation of Programming Languages" in Kyoto University.

## お知らせ

- 3月4日: 2020年の講義資料ページを作りました．

## リンク集

- 実験3ホームページ: https://kuis-isle3sw.github.io/kuis-isle3sw-portal/
- 専門科目「プログラミング言語」ホームページ: https://github.com/aigarashi/PL-LectureNotes
  - の中の OCaml のページ（最低このくらいはわかってないとキツイ）: http://www.fos.kuis.kyoto-u.ac.jp/~igarashi/class/pl/03-ocaml.html
  - の中の OCaml で二分探索木を書くページ（これもわかってないとキツイ）: http://www.fos.kuis.kyoto-u.ac.jp/~igarashi/class/pl/04-bst-ocaml.html

## 講義に関する情報

- 講義をする人: 末永幸平（[@ksuenaga](http://www.twitter.com/ksuenaga/), https://researchmap.jp/ksuenaga/）
- 講義が行われる時間: 月曜2限
- 講義が行われる場所: 総合研究7号館講義室1
- Language used in the class: Japanese

## 講義予定

一部の資料と過去問は PandA で配布するので，PandA を見られる状態にしておくこと．
   
| 日付 | 内容 | 対応する教科書中の場所 |
|------|-----------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 4/13 | オリエンテーション，イントロダクション，OCaml入門 | [オリエンテーション資料](misc/orientation.md), [教科書1章](textbook/chap01.pdf), [教科書2章](textbook/chap02.pdf), [OCaml入門テキスト](textbook/mltext.pdf) |
| 4/20 | OCaml入門 | [OCaml入門テキスト](textbook/mltext.pdf) |
| 4/27 | ML1インタプリタ，ML2インタプリタ | [教科書3章 (ML1インタプリタ)](textbook/chap03-1.pdf), [教科書3章 (ML2インタプリタ)](textbook/chap03-2.pdf) |
| 5/11 | ML1インタプリタ，ML2インタプリタ，ML3インタプリタ | [教科書3章 (ML1インタプリタ)](textbook/chap03-1.pdf), [教科書3章 (ML2インタプリタ)](textbook/chap03-2.pdf), [教科書3章 (ML3インタプリタ)](textbook/chap03-3.pdf) |
| 5/18 | ML3インタプリタ，ML4インタプリタ，ML2の型推論 | [教科書3章 (ML3インタプリタ)](textbook/chap03-3.pdf), [教科書3章 (ML4インタプリタ)](textbook/chap03-4.pdf), [教科書4章 (ML2型推論)](textbook/chap04-1.pdf) |
| 5/25 | ML2の型推論，ML3の型推論，多相型の型推論 | [教科書4章 (ML2型推論)](textbook/chap04-1.pdf), [教科書4章 (ML3,4型推論)](textbook/chap04-2.pdf), [教科書4章 (多相型)](textbook/chap04-3.pdf) |
| 6/1 | ML2の型推論，ML3の型推論，多相型の型推論 | [教科書4章 (ML2型推論)](textbook/chap04-1.pdf), [教科書4章 (ML3,4型推論)](textbook/chap04-2.pdf), [教科書4章 (多相型)](textbook/chap04-3.pdf) |
| 6/8 | 中間試験 | |
| 6/15 | ML3の型推論，多相型の型推論 | [教科書4章 (ML3,4型推論)](textbook/chap04-2.pdf), [教科書4章 (多相型)](textbook/chap04-3.pdf) |
| 6/22 | 字句解析 | PandA で配布しているスライド |
| 6/29 | 構文解析 (LL(1)) | PandA で配布しているスライド |
| 7/6 | 構文解析 (LL(1), LR(0)) | PandA で配布しているスライド |
| 7/13 | 構文解析 (LR(0), SLR, LR(1))，コンパイラの導入，MIPSアセンブリ入門 | PandA で配布しているスライド，[MIPSアセンブリ入門](textbook/MIPS.pptx) |
| 7/20 | コンパイラ | [MIPSアセンブリ入門](textbook/MIPS.pptx)，[教科書5章](textbook/chap05.pdf)|
| ?/?? | 期末試験 | |

## OCaml の設定方法

OCaml のパッケージシステムである OPAM を用いてインストールするのが簡単である．
https://opam.ocaml.org/doc/Install.html を読んでインストールすること．
以下は簡便のために抜粋したものであるが，最新の情報ではないかもしれないので，できれば上記ページを読むこと．

- `sh <(curl -sL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)`
  - `curl` 関係のエラーが出る場合は https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh のスクリプトをダウンロードして `sh install.sh` を実行．
  - 各自のパッケージ管理システム（Mac なら homebrew や macport，Linux なら yum や apt 等）を用いて opam をインストールしてもよい．
- _以下では実行ログの最後に`eval $(opam env)`を実行せよと書いてあることがあるので，その時は次の作業に移る前に `eval $(opam env)` を実行すること．_
- `opam init` を実行
  - 途中設定ファイルに opam が書き込んでよいか聞かれる．全部 `y` にしておくと楽は楽である．
- `opam switch create 4.07.1`を実行
- `opam install depext`
- `opam install user-setup`

演習にはいくつかのパッケージが必要である．OPAM が入った状態であれば，以下のコマンドを順に実行することでこれらのパッケージを導入できる．

- `opam depext menhir dune ounit`
- `opam install menhir dune ounit`

便利情報がいくつかある．

- Emacs を使う人は tuareg-mode を使うとよい．`opam install tuareg` のあとに `opam user-setup install` を実行．
- emacs と vim では merlin https://ocaml.github.io/merlin/ が便利である．これがあるとエディタが IDE になる．`opam install merlin` のあとに `opam user-setup install` を実行．
  - Sublime-Text バージョンもベータ版として提供されている https://github.com/let-def/sublime-text-merlin
- VSCode で OCaml を使う方法がいくつかあるらしい．（調べた人は情報ください．）
  
