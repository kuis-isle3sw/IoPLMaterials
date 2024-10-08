{% include head.html %}

# Chapter 1

## はじめに

本書は工学部専門科目「プログラミング言語処理系」と「計算機科学実験及演習３（ソフトウェア）」のテキストである．プログラミング言語の設計と実装に関わるトピックをカバーしている．

本書では (1) 工学部専門科目「プログラミング入門」と (2) 「言語・オートマトン」の内容を既知とする．実装課題に取り組む場合は特に (3) git の基本的な操作法と (4) OCaml の知識とある程度の実装力が必要である．本講義でも OCaml の復習を少しやる予定であるが，あまり時間をかけることはできないので，以下の問題が解ける程度になるまで各自自習されたい．五十嵐淳による [OCaml 入門テキスト](mltext.pdf) が参考になるであろう．

なお，この教科書は五十嵐淳によって書かれた教科書を馬谷誠二と末永幸平が加筆したものである．

## OCaml 力をチェックするための問題

本書中の実装課題に取り組む場合，以下の問題を解ける程度の OCaml 力が必要である．

### Exercise 1.1

OCamlインタプリタに以下の入力を与えたところ，

```ocaml
# let rec f x = if x = 0 then x else false;;
Error: This expression has type bool but an expression was expected of type int.
```

という応答が返ってきた．この応答の意味するところを，エラーメッセージ中の `This` が何を指すかを明らかにしつつ，説明せよ．

### Exercise 1.2

`int`型の値`n`を受け取り，`1+...+n`を返す関数`sum`を書け．ただし，`n`が`0`以下である場合は例外を投げること．例外の宣言もプログラムに含めよ．

### Exercise 1.3

1. 各ノードに`int`型の値を保持する二分木を表すユーザ定義型`bt`を，ヴァリアント型を用いて定義せよ．
2. `bt`型の値`t`を受け取り，`t`中に現れるすべての値の和を求める関数`sumtree`を書け．`sumtree`の型は`bt -> int`となる．
3. `int -> int`型の関数`f`と`bt`型の値`t`とを受け取り，`t`中に現れるすべての値に`f`を適用して得られる木を求める関数`mapTree`を書け．`mapTree`の型は`(int -> int) -> bt -> bt`となる．

## OCaml のインストールと設定

本書の演習問題に取り組むためには，OCamlの処理系と，元になるソースコードが必要となる．講義資料中の[OCaml の設定に関する部分](https://kuis-isle3sw.github.io/IoPLMaterials/#ocaml-%E3%81%AE%E8%A8%AD%E5%AE%9A%E6%96%B9%E6%B3%95)を参照のこと．
