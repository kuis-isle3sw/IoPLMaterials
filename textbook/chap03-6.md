{% include head.html %}

# MiniML4: 再帰的関数定義の導入

多くのプログラミング言語では，変数を宣言するときに，その定義にその変数自身を参照するという，_再帰的定義 (recursive definition)_ が許されている．MiniML4 では，このような再帰的定義の機能を導入する．ただし，単純化のため再帰的定義の対象を関数に限定する．

まず，再帰的定義のための構文 `let rec` 式・宣言を，MiniML3 の文法を拡張する形で以下のように導入する．
```
P ::= ...
   |  let rec <識別子> = fun <識別子> -> e ;;
e ::= ...
   | let rec <識別子> = fun <識別子> -> e in e
```
この構文の基本的なセマンティクスは `let` 式・宣言と似ていて，環境を宣言にしたがって拡張したもとで本体式を評価するものである．ただし，環境を拡張する際に，再帰的な定義を処理する工夫が必要になる．例で説明しよう．
{% highlight ocaml %}
let rec fact = fun n -> if n = 0 then 1 else n * (fact (n + (-1))) in
fact 5
{% endhighlight %}
おなじみの階乗関数である．この式がどう評価されるかを説明しよう．
- まず関数`fact`を関数閉包に束縛する．この関数閉包は，`n`を受け取って`if n = 0 then 1 else n * (fact (n + (-1)))`の評価結果を返す関数である．この関数閉包内には，[以前説明したとおり](chap03-5.md#closure)，関数閉包を作る時点での環境が保存されており，`fact`が束縛される先の関数閉包内の環境は，これが作成されたときの環境，すなわちデフォルトの大域環境`initial_env`である．
- この関数閉包を`fact 5`で使用している．関数適用を行う際には，関数閉包内に保存されている環境を取り出し，その環境を仮引数に対する束縛で拡張した上で関数本体の評価を行う．したがって，この例では，`initial_env`を`n=5`で拡張した環境で`if n = 0 then 1 else n * (fact (n + (-1)))`の部分を評価することになる．数ステップ後，インタプリタは`fact (n + (-1))`をこの環境で評価することになるのだが，環境内には`fact`に対する束縛が含まれていないので，エラーとなる．

何が問題だったのだろうか？`let rec fact = fun n -> if n = 0 then 1 else n * (fact (n + (-1)))`で再帰関数を定義する際に，`fact`に対する束縛が関数閉包内に保存される環境に入っていなかったことである．再帰関数におい
ては， _今これから作ろうとしている関数である `fact` を関数本体 `if n = 0 then 1 else n * (fact (n + (-1)))`内で使う可能性がある_ ので，`fact`に対する束縛も閉包内の環境に含まれていてほしい．このような circular な構造をいかにして実現するかが今回の再帰関数を扱うための拡張のキモである．

これを実現するための方法はいくつかあるが，今回はいわゆる _バックパッチ (backpatching)_ と呼ばれる手法を用いる．バックパッチは，最初，ダミーの環境を用意して，ともかく関数閉包を作成し，環境を拡張してしまう．そののちダミーの環境を，たった今作った関数閉包で拡張した環境に _更新_ する，という手法である．

_以下では OCaml における破壊的代入をサポートする「参照」の機能がわかっていないときつい．もし，`let x = ref 3 in x := 4; !x` というプログラムが何をするかわからない場合は，[「プログラミング言語」のOCaml爆速入門夜露死苦（特に「ref 型」の節）](http://www.fos.kuis.kyoto-u.ac.jp/~igarashi/class/pl/03-ocaml.html)を復習しよう．_

以下にバックパッチを用いて再帰関数定義をサポートするために MiniML3 に加えるべき変更を示す．

### `syntax.ml`

BNF の拡張に従って `exp`型と `program`型に新しいコンストラクタを追加する．

{% highlight ocaml%}
type exp = 
   ...
  | LetRecExp of id * id * exp * exp

type program = 
   ...
  | RecDecl of id * id * exp
{% endhighlight %}

### `eval.ml`

{% highlight ocaml %}
type exval =
   ...
    (* Changed! 関数閉包内の環境を参照型で保持するように変更 *)
  | ProcV of id * exp * dnval Environment.t ref 

let rec eval_exp env = function
 ...
 | LetRecExp (id, para, exp1, exp2) ->
    (* ダミーの環境への参照を作る *)
    let dummyenv = ref Environment.empty in
    (* 関数閉包を作り，idをこの関数閉包に写像するように現在の環境envを拡張 *)
    let newenv = Environment.extend id (ProcV (para, exp1, dummyenv)) env in
    (* ダミーの環境への参照に，拡張された環境を破壊的代入してバックパッチ *)
        dummyenv := newenv;
        eval_exp newenv exp2
{% endhighlight %}

再帰関数を定義する際に，一旦ダミーの環境を作成し，関数閉包を作成した後に，その環境を更新する必要があるが，これを OCaml の参照を用いて実現している．`eval.ml`の`exval`型の定義において，`ProcV`が保持するデータが環境`dnval Environment.t`ではなく，環境への参照`dnval Environment.t ref`になっていることに注意されたい．（したがって，ここに明示されていない関数適用のケースにおいては，格納されている環境を使用するために，参照から環境を取り出す操作が必要になる．）`eval_exp` の `LetRecExp` を処理する部分は，まずダミーの型環境への参照`dummyenv`を作った上で，この`dummyenv`を含む関数閉包を作成し，現在の環境`env`を`id`からこの関数閉包への写像で拡張した環境`newenv`を作り，参照`dummyenv`の指す先を`newenv`に変更している．

### Exercise ___ [必修]
図に示した `syntax.ml` にしたがって，`parser.mly` と `lexer.mll` を完成させ，MiniML4 インタプリタを作成し，テストせよ．(`let rec`式だけでなく`let rec`宣言も実装すること．)

### Exercise ___ [**]
`and`を使って変数を同時にふたつ以上宣言できるように `let rec`式・宣言を拡張し，相互再帰的関数をテストせよ．