{% include head.html %}

# MiniML3: 関数の導入

ここまでのところ，この言語には，いくつかのプリミティブ関数（二項演算子）しか提供されておらず，MiniML プログラマが（プリミティブを組み合わせて）新しい関数を定義することはできなかった．MiniML3 では，`fun`式による関数抽象と，関数適用を実装する．

## 関数式と適用式の構文

まずは，MiniML3 の式の文法を示す．
```
  e ::= ...
     | fun <識別子> -> <式>
     | e e
```
適用式は左結合（つまり，`e1 e2 e3` と書くと `(e1 e2) e3`と解釈）で，他の全ての演算子よりも結合が強い（つまり `e1 e2 + e3` とか書いたら `(e1 e2) + e3`と解釈）とする．

MiniML3 を実装するために，まず字句解析器と構文解析器を拡張しよう．MiniML2 に以下の変更を加えればよい．

### `syntax.ml`

BNF の拡張に合わせて `exp` 型に新しいコンストラクタを追加する．

{% highlight ocaml %}
type exp = 
   ...
  | FunExp of id * exp (* New! *)
  | AppExp of exp * exp (* New! *)
{% endhighlight %}

### `parser.mly`

新しいトークンである `->` と `fun` に対応するトークン（`RARROW`と`FUN`）を宣言して，関数定義式と関数適用式を構文解析するための規則を追加する．（関数定義式を parse するための規則は自分で追加すること．）

{% highlight ocaml %}
%token RARROW FUN (* New! *)

Expr :
   ...
   | e=FunExpr { e }

(* fun x -> e を構文解析するための規則は自分で考えて追加すること． *)

MExpr :
    e1=MExpr MULT \graybox{e2=AppExpr} { BinOp (Mult, e1, e2) }
  | e=AppExpr { e } (* New! *)

(* New! *)
AppExpr :
    e1=AppExpr e2=AExpr { AppExp (e1, e2) }
  | e=AExpr { e }
{% endhighlight %}

上記の規則で，関数適用式の優先順位と結合が定められたとおりになっていること（他の演算子よりも強く，左結合であること）を確認されたい．

### `lexer.mll`

リスト `reservedWords` に予約語を追加し，`->`をトークン `FUN` として切り出すように規則を追加する．

{% highlight ocaml %}
let reservedWords = [
   ...
  ("fun", Parser.FUN);
   ...
]
...
| "=" { Parser.EQ \
| "->" { Parser.RARROW } (* New! *)
{% endhighlight %}

## 評価器の拡張: 関数値の表現の仕方

さて，関数値をどのようなデータで表現すればよいか，すなわち`fun x -> e`という関数式を評価した結果をどう表現すればよいかを考えよう．この式を評価して得られる関数値は，何らかの値に適用されると，仮引数`x`を受け取った値に束縛し，関数本体の式`e`を評価する．したがって，関数値は少なくともパラメータの名前と，本体の式の情報を含んでいなければならない．であれば，以下のように`exval`を拡張して関数値のためのコンストラクタ`ProcV`を定義することが考えられる．
{% highlight ocaml %}
(* 注：これはうまくいかない *)
type exval =
  ...
  | ProcV of id * exp (* 仮引数と関数本体の情報だけで良いだろうか? *)
and dnval = exval
{% endhighlight ocaml %}

しかし，実際はこれだけではうまくいかない．以下の MiniML3 のプログラム
例を見てみよう．
{% highlight ocaml %}
let f =
  let x = 2 in (* (A) *)
  let addx = fun y -> x + y in
  addx
in
f 4
{% endhighlight %}

_この先を読む前に，まず (1) このプログラムは何に評価されるべきかを考え，(2) 実際には何に評価されるかを OCaml インタプリタで確認すること．自分の考えと OCaml インタプリタの意見がずれている場合は，[「プログラミング言語」のこの部分（特に「カリー化による複数引数関数の表現」のところ](http://www.fos.kuis.kyoto-u.ac.jp/~igarashi/class/pl/10-hofuns.html)をもう一度復習すること．_

この例で定義している関数`addx`は受け取った値に`x`の値を加えて返す関数である．前述のように関数値を表現するとこの`addx`は`ProcV("y", BinOp(Plus, Var "x", Var"y"))`に束縛されるはずである．このプログラムがどのように走るかを見てみよう．
- このプログラムは `f`を`addx`の評価結果に束縛する．`addx` の評価結果は `ProcV("y", BinOp(Plus, Var "x", Var "y"))` であるから，`f` を `ProcV("y", BinOp(Plus, Var "x", Var "y"))` に束縛して環境を拡張する．
- 拡張された環境で関数適用式`f 4`を評価しようとする．`f` は `ProcV("y", BinOp(Plus, Var "x", Var "y"))` に束縛されているので，上述した関数適用の直観的なセマンティクスによれば，変数`y`を`4`に束縛して`BinOp(Plus, Var "x",Var "y")`を評価しようとする．
- ところが，この時点では環境中に`x`がない！これは `(* (A) *)` における `x`の束縛が，この時点ではスコープを外れているためである．そのため，このままでは`BinOp(Plus, Var "x",Var "y")`を正しく評価することができない．

何が問題だったのだろうか？問題は，`addx`が束縛される関数式`fun y -> x + y`に _自由変数 `x`_ が含まれていることである．この`x`は，OCaml と同様に _`addx`が定義された時点の_ `x`の値（すなわち，`(A)` の行で導入される束縛が有効）なのだが，関数値に仮引数と関数本体の式のみを含める現在の関数値では，このような関数式の自由変数が扱えない．このような自由変数を扱うためには，関数値に仮引数，関数本体の式に加えて，関数値が作られたときに自由変数が何に束縛されているか，すなわち現在の例では`x`が `2` に束縛されているという情報を記録しておかなければならない．

というわけで，一般的に関数が適用される時には，
- パラメータ名
- 関数本体の式，に加え
- 本体中のパラメータで束縛されていない変数（自由変数）の束縛情報（名前と値）
が必要になる．この3つを組にしたデータを一般に _関数閉包・クロージャ (function closure)_ と呼び，これを関数を表す値として用いる．

ここで作成するインタプリタでは，本体中の自由変数の束縛情報として，`fun`式が評価された時点での環境全体を使用する．これは，本体中に現れない変数に関する余計な束縛情報を含んでいるが，もっとも単純な関数閉包の実現方法である．

以上を踏まえて，`eval.ml` に加えるべき変更を以下に示す．

{% highlight ocaml %}
type exval =
    IntV of int
  | BoolV of bool
  | ProcV of id * exp * dnval Environment.t (* New! クロージャが作成された時点の環境をデータ構造に含めている．*)
and dnval = exval

let rec eval_exp env = function
  ...
  (* 関数定義式: 現在の環境 env をクロージャ内に保存 *)
  | FunExp (id, exp) -> ProcV (id, exp, env)
  (* 関数適用式 *)
  | AppExp (exp1, exp2) ->
      (* 関数 exp1 を現在の環境で評価 *)
      let funval = eval_exp env exp1 in
      (* 実引数 exp2 を現在の環境で評価 *)
      let arg = eval_exp env exp2 in
      (* 関数 exp1 の評価結果をパターンマッチで取り出す *)
      (match funval with
          ProcV (id, body, env') -> (* 評価結果が実際にクロージャであれば *)
              (* クロージャ内の環境を取り出して仮引数に対する束縛で拡張 *)
              let newenv = Environment.extend id arg env' in
                eval_exp newenv body
        | _ -> 
          (* 評価結果がクロージャでなければ，実行時型エラー *)
          err ("Non-function value is applied"))
{% endhighlight %}

+ 式の値には，環境を含むデータである関数閉包が含まれるため，`exval`と`dnval` の定義が（相互）再帰的になる．関数値は `ProcV` コンストラクタで表され，上で述べたように，パラメータ名，本体の式，環境の三つ組を保持する．
+ `eval_exp` で `FunExp` を処理する時には，その時点での環境，つまり`env` を使って関数閉包を作っている．
+ 適用式の処理は，適用される関数の評価，実引数の評価を行った後，本当に適用されている式が関数かどうかのチェックをして，本体の評価を行っている．本体の評価を行う際の環境`newenv` は，関数閉包に格納されている環境を，パラメータ・実引数で拡張して得ている．

### Exercise ___ [必修]
MiniML3 インタプリタを作成し，高階関数が正しく動作するかなどを含めて
テストせよ．

### Exercise ___ [**]
OCaml での「`(中置演算子)`」記法をサポートし，プリミティブ演算を通常の関数と同様に扱えるようにせよ．例えば
{% highlight ocaml %}
let threetimes = fun f -> fun x -> f (f x x) (f x x) in
  threetimes (+) 5
{% endhighlight %}
は，`20`を出力する．

### Exercise ___ [*]
OCaml の
{% highlight ocaml %}
fun x1 ... xn -> ...
let f x1 ... xn = ...
{% endhighlight %}
といった簡略記法をサポートせよ．

### Exercise ___ [*] <a name="#selfapplication"></a>
以下は，加算を繰り返して 4 による掛け算を実現している MiniML3 プログラムである．これを改造して，階乗を計算するプログラムを書け．
{% highlight ocaml %}
let makemult = fun maker -> fun x ->
                 if x < 1 then 0 else 4 + maker maker (x + -1) in
let times4 = fun x -> makemult makemult x in 
  times4 3
{% endhighlight %}

### Exercise ___ [*] <a name="#dfun"></a>
静的束縛とは対照的な概念として _動的束縛 (dynamic binding)_ があ  る．動的束縛の下では，関数本体は，関数式を評価した時点ではなく，関数呼び出しがあった時点での環境をパラメータ・実引数で拡張した環境下で評価される．インタプリタを改造し，`fun` の代わりに `dfun` を使った関数は動的束縛を行うようにせよ．例えば，
{% highlight ocaml %}
let a = 3 in
let p = dfun x -> x + a in
let a = 5 in
  a * p 2
{% endhighlight %}
というプログラムでは，関数 `p` 本体中の `a` は `3` ではなく `5` に束縛され，結果は，`35`になる．(`fun` を使った場合は `25` になる．)

### Exercise ___ [*]
動的束縛の下では，MiniML4 で導入するような再帰定義を実現するための特別な仕組みや，[このexercise](#selfapplication)のようなトリックを使うことなく，再帰関数を定義できる．以下のプログラムで， 二箇所の `fun` を `dfun` ([このExerciseを参照](#dfun))に置き換えて(4通りのプログラムを)実行し，その結果について説明せよ．
{% highlight ocaml %}
let fact = fun n -> n + 1 in
let fact = fun n -> if n < 1 then 1 else n * fact (n + -1) in
  fact 5
{% endhighlight %}

TODO: 評価戦略の話？

