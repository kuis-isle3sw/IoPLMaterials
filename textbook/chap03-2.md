# 各モジュールの機能

実装するインタプリタは6つのモジュール<sup>[1](#fn1)</sup>から構成される．本節ではそれぞれのモジュールについて簡単に説明する．

<a name="#fn1">1</a>: OCamlを含め多くのプログラミング言語には， _モジュールシステム (module system)_ と呼ばれる，プログラムを部分的な機能（_モジュール (module)_）ごとに分割するための機構が備わっている．この機構は，プログラムが大規模化している現代的なプログラミングにおいて不可欠な機構であるが，その解説は本書の範囲を超える．[OCaml入門](mltext.pdf)の該当する章を参照されたい．さしあたって理解しておくべきことは，
- OCaml プログラムを幾つかのファイルに分割して開発すると，ファイル名に対応したモジュールが生成されること（例えば，`foo.ml`というファイルからは`Foo`というモジュールが生成される）
- モジュール内で定義されている変数や関数をそのモジュールの外から参照するにはモジュール名を前に付けなければならないこと（例えばモジュール`Foo`の中で定義された`x`という変数を`Foo`以外のモジュールから参照するには`Foo.x`と書く）
の二点である．

## `Syntax`モジュール：抽象構文のためのデータ型の定義

`Syntax`モジュールはファイル[syntax.ml](../interpreter/src/syntax.ml)に定義されており，抽象構文木を表すデータ型を定義している．具体的には，このモジュールでは上の BNF に対応する抽象構文木を表す以下の型が定義されている．型定義が含まれている．
TODO: ソースコードを埋め込めると良いのだが．

以下では`Syntax`モジュールで定義されている型は変数を説明する．実際に[syntax.ml](../interpreter/src/syntax.ml)と[前出のBNF](./chap03-1.md#bnf)を見ながら読んでみてほしい．
- `id` は変数の識別子を示すための型で，その実体はここでは変数の名前を表す文字列としている．(より現実的なインタプリタやコンパイラでは，変数の型や変数が現れたファイル名と行数などの情報も加わることが多い．)
- `binOp`，`exp`，`program` 型に関しては[前出の BNF](./chap03-1.md#bnf)でのシンタックスの定義を（括弧式を除いて）そのまま写した形の宣言になっている．例えば，式`3+x'`は`exp`型の値`BinOP(Plus, ILit 3, Var "x'")` で表現される．
- `typ` 型は型推論器を実装するときに用いる「型を表す型」である．今のところは無視して良い．

式の抽象構文木を表す値（すなわち，`exp`型の値）は，プログラムを表す文字列から，_字句解析_ と _構文解析_ と呼ばれる処理によって生成される．これらの処理については後述するが，
- [`Lexer`](../interpreter/src/lexer.mll)モジュールには字句解析のための型や関数が定義されており，
- [`Parser`](../interpreter/src/parser.mly)モジュールには構文解析のための型や関数が定義されており，
- [`Parser`](../interpreter/src/parser.mly)モジュールは [Menhir](http://gallium.inria.fr/~fpottier/menhir/) というツールを用いて[parser.mly](../interpreter/src/parser.mly)というファイルから，[`Lexer`](../interpreter/src/lexer.mll)モジュールは [ocamllex](https://caml.inria.fr/pub/docs/manual-ocaml/lexyacc.html) というツールを用いて[lexer.mll](../interpreter/src/lexer.mll)というファイルからそれぞれ自動生成される．

## [`Environment`](../interpreter/src/environment.ml)モジュールと[`Eval`](../interpreter/src/eval.ml)モジュール：環境と解釈部

### 式の表す値

以下の説明は，[environment.ml](../interpreter/src/environment.ml)と[environment.mli](../interpreter/src/environment.mli)と[eval.ml](../interpreter/src/eval.ml)を見ながら読むとよい．

`Eval`モジュールはインタプリタの動作のメイン部分であり，字句解析と構文解析によって生成された構文木を解釈する．（したがって，この部分をインタプリタの _解釈部_ と呼ぶ．）解釈部に動作によって，言語処理系は定義される言語のセマンティクスを定めている．

プログラミング言語のセマンティクスを定めるに当たって重要なことの一つは，どんな類いの _値 (value)_ を（定義される言語の）プログラムが操作できるかを定義することである．例えば，C言語であれば整数値，浮動小数値，ポインタなどが値として扱えるし，OCaml であれば整数値，浮動小数値，レコード，ヴァリアントなどが値として扱える．

言語によっては，このとき _式の値 (expressed value)_ の集合と _変数が指示する値 (denoted value)_ を区別する必要がある．前者は式を評価した結果得られる値であり，後者は変数が指しうる値である．この2つの区別は，普段あまり意識することはないかもしれないし，実際に今回のインタプリタの範囲では，このふたつは一致する（式の値の集合 = 変数が指示する値の集合）．しかし，この2つが異なる言語も珍しくない．例えば，C 言語では，変数は，値そのものにけられた名前ではなく，値が格納された箱につけられた名前と考えられる．そのため，denoted value は expressed value への _参照_ と考えるのが自然になる．

<!-- \footnote{この二種類の値の区別はコンパイラの教科書で見られる\intro{左辺値}{L-value}，\intro{右辺値}{R-value}と関連する．} -->

MiniML1 の場合，式の値 expressed value の集合は
{..., -2, -1, 0, 1, 2, 3, \ldots} $\oplus$ 真偽値の集合
であり，denoted value の集合は expressed value の集合に等しい．ここで，$\oplus$ は直和を示している．

[eval.ml](../interpreter/src/eval.ml)には値を表す OCaml の型である`exval`と`dnval`が定義されている．インタプリタ内では，MiniML の値をこれらの形の（OCamlの）値として表すことになる．型宣言は，初めは以下の通りになっている．
```
(* Expressed values *)
type exval = 
    IntV of int
  | BoolV of bool
and dnval = exval
```
`exval`がexpressed valueの型，`dnval`がdenoted valueの型である．

### 環境

解釈部を構成する上では，式を評価する際に，各変数の値が何であるかを管理することが重要である．そのためにもっとも簡単な解釈部の構成法のひとつは，抽象構文木と _環境 (environment)_ と呼ばれるデータ構造を受け取り，抽象構文木が表す式の評価結果を計算する _環境渡しインタプリタ (environment passing interpreter)_ という方法である．

言語処理系の文脈における _環境 (environment)_ とは，変数から denoted value への関数（もしくはこの関数を表現するデータ構造）のことである．環境は変数の denoted value への _束縛 (binding)_ <sup>[1](#binding)</sup>を表現する．束縛とは各変数を何らかのデータ（ここでは denoted value）に結びつけることである．プログラムにおいて，各変数が何に束縛されているか（= 各変数の値が何であるか）を，環境で表現するのである．例えば，$\{x \mapsto 1, y \mapsto 3\}$という写像は環境である．この環境は変数$x$を$1$に，$y$を$3$に写像しており，変数`x`の値が`1`であり，変数`y`の値が`3`であることを表している．

<a href="#binding">1</a>: 一般に変数$x$が何らかの情報$v$に結び付けられていることを _$x$が$v$に束縛されている ($x$ is bound to $v$)_ と言う．値$v$が変数$x$に束縛されている _とはいわない_ ので注意すること．

OCaml で MiniML の言語処理系を実装する上では，環境をどのような型の値として表現するかが重要である．環境を実装する上では，変数と denoted value の束縛を表現できれば充分なのだが，あとで用いる型推論においても，変数に割当てられた型を表現するために同様の構造を用いるので，汎用性を考えて，環境の型を多相型`'a t`とする．ここで`'a`は変数に関連付けられる情報（ここでは denoted value）の型である．こうすることで，同じデータ構造を変数のdenoted valueへの束縛としても，変数の別の情報への束縛としても使用することができるようになる．

環境を操作する値や関数の型，これらの環境から送出されか可能性のある例外は，[environment.mli](../interpreter/src/environment.mli)に以下のように定められている．
```
type 'a t
exception Not_bound
val empty : 'a t
val extend : Syntax.id -> 'a -> 'a t -> 'a t
val lookup : Syntax.id -> 'a t -> 'a
val map : ('a -> 'b) -> 'a t -> 'b t
val fold_right : ('a -> 'b -> 'b) -> 'a t -> 'b -> 'b
```
- 最初の値 `empty` は，何の変数も束縛されていない，空の環境である．
- 次の`extend` は，環境に新しい束縛をひとつ付け加えるための関数で，`extend id dnval env`で，環境 `env` に対して，変数 `id` を denoted value `dnval` に束縛したような新しい環境を表す．
- 関数 `lookup` は，環境から変数が束縛された値を取り出すもので，`lookup id env` で，環境`env` の中を，新しく加わった束縛から順に変数 `id` を探し，束縛されている値を返す．変数が環境中に無い場合は，例外 `Not_bound` が発生する．
- また，関数 `map` は，`map f env` で，各変数が束縛された値に `f`を適用したような新しい環境を返す．
- `fold_right` は環境中の値を新しいものから順に左から並べたようなリストに対して`fold_right` を行なう．これらは，後に型推論の実装などで使われる．

この関数群を実装したものが[environment.ml](../interpreter/src/environment.ml)である．環境のデータ表現は，変数と，その変数が束縛されているデータのペアのリストである．例えば上に出てきた環境$\{x \mapsto 1, y \mapsto 3\}$はリスト`[(x,1); (y,3)]`で表現される．ただし `environment.mli` では型 `'a t` が定義のない抽象的な型として宣言されているので，環境を使う側からは環境の実体がこのように実装されていることを使うことはできず，環境の操作は`Environment`モジュール中の関数を介して行う必要がある．（例えば，環境`env`に対して`match env with [] -> ... | hd::tl -> ...`のようにリストのパターンマッチを適用することはできない．）

<!-- 
\begin{figure}
  \centering
\begin{boxedminipage}{\textwidth}
\begin{progeg}
\input{../src/1/environment.ml}
\end{progeg}
\end{boxedminipage}
  \caption{MiniML1 インタプリタ: 環境の実装 (`environment.ml`)}
  \label{fig:environment}
\end{figure} -->

#### `.ml`ファイルと`.mli`ファイルの関係について（あるいは，「実装の隠蔽」について）

[environment.mli](../interpreter/src/environment.mli)と[environment.ml](../interpreter/src/environment.ml)の関係を理解しておくのはとても重要なので，ここで少し説明しておこう．どちらも`Environment`モジュールを定義するために用いられるファイルなのだが，`environment.ml`は `Environment`モジュールがどう動作するかを決定する _実装 (implementation)_ を定義し，`environment.mli`はこのモジュールがどのように使われてよいかを決定する _インターフェイス (interface)_ を宣言する．<sup>[2](#interface)</sup> 中身を見てみると，`environment.ml`には`Environment`モジュールがどう動作するかが記述されており，`environment.mli`は，このモジュールの使われ方が型によって表現されている．

<a name="#interface">2</a>: 一般にインターフェイスとは，2つ以上のシステムが相互に作用する場所のことを言う．`Environment`モジュールの内部動作と外部仕様との相互作用を`environment.mli`が決めているわけである．

これを頭に入れて，`environment.ml`と`environment.mli`を見返してみよう．`environment.ml`は型`'a t`を連想リスト`(Syntax.id * 'a) list`型として定義し，`'a t`型の値を操作する関数を定義している．これに対して，`environment.mli`は (1) なんらかの多相型`'a t`が _存在する_ ことのみを宣言しており，この型の実体が何であるかには言及しておらず，(2) 各関数の型を`'a t`を用いて宣言している．（`.mli`ファイル中の各関数の型宣言は`'a t`の実体が`(Syntax.id * 'a) list`であることには言及していないことに注意．）

`Environment`モジュール中の定義を使用するモジュール（例えばあとで説明する`Eval`モジュールなど）は，_`environment.mli`ファイルに書かれている定義のみを，書かれている型としてのみ_ 使うことができる．例えば`Environment`モジュールの`empty`という変数を`Environment`モジュールの外から使う際には`Environment.empty`という名前で参照することになる．`Environment.empty`は`'a t`型なので _リストとして使うことはできない．_ すなわち，`environment.ml`内で`'a t`がリストとして実装されていて`empty`が`[]`と実装されているにも関わらず，`1 :: Environment.empty`という式は型エラーになる．

なぜこのように実装とインターフェイスを分離する言語機構が提供されているのだろうか．一般によく言われる説明は _プログラムを変更に強くするため_ である．例えば，開発のある時点で`Environment`モジュールの効率を上げるために，`'a t`型をリストではなく二分探索木で実装し直したくなったとしよう．今の実装であれば，`'a t`型が実際はどの型なのかがモジュールの外からは隠蔽されているので，`environment.ml`を修正するだけでこの変更を実装することができる．このような隠蔽のメカニズムがなかったとしたら，`Environment`モジュールを使用する関数において，`'a t`型がリストであることに依存した記述を行うことが可能となる．そのようなプログラムを書いてしまうと，二分木の実装への変更を行うためには _全プログラム中の`Environment`モジュールを利用しているすべての箇所の修正が必要になる．_ この例から分かるように，実装とインターフェイスを分離して，モジュール外には必要最低限の情報のみを公開することで，変更に強いプログラムを作ることができる．

TODO: ここまでかいた

以下は後述する `main.ml` に記述されている，プログラム実行開始時の環境(大域環境)の定義である．
%
#{&}
let initial_env = 
  Environment.extend "i" (IntV 1)
    (Environment.extend "v" (IntV 5) 
       (Environment.extend "x" (IntV 10) Environment.empty))
#{`}
%
\ML{i}，\ML{v}，\ML{x} が，それぞれ \ML{1}，\ML{5}，\ML{10} に束縛されている
ことを表している．この大域環境は主に変数参照のテスト用で，(空でなければ)何
でもよい．

\paragraph{解釈部の主要部分}

以上の準備をすると，残りは，二項演算子によるプリミティブ演算を実行する
部分と式を評価する部分である．前者を `apply_prim`, 後者を `eval_exp`
という関数として図\ref{fig:eval_exp}のように定義する．`eval_exp` では，
整数・真偽値リテラル(`ILit`, `BLit` )はそのまま値に，変数は
`Environment.lookup` を使って値を取りだし，プリミティブ適用式は，引数
となる式(オペランド)をそれぞれ評価し`apply_prim` を呼んでいる．
`apply_prim` は与えられた二項演算子の種類にしたがって，対応する
OCaml の演算をしている．\ML{if}式の場合には，まず条件式のみを評価し
て，その値によって\ML{then}節/\ML{else}節の式を評価している．関数
`err` は，エラー時に例外を発生させるための関数である(`eval.ml` 参照の
こと)．

`eval_decl` は MiniML1の範囲では単に式の値を返すだけのものでよいの
だが，後に，`let`宣言などを処理する時のことを考えて，新たに宣言された
変数名(ここではダミーの`"-"`)と宣言によって拡張された環境を返す設計に
なっている．

\begin{figure}
  \centering
\begin{boxedminipage}{\textwidth}
#{&}
let rec apply_prim op arg1 arg2 = match op, arg1, arg2 with
    Plus, IntV i1, IntV i2 -> IntV (i1 + i2)
  | Plus, _, _ -> err ("Both arguments must be integer: +")
  | Mult, IntV i1, IntV i2 -> IntV (i1 * i2)
  | Mult, _, _ -> err ("Both arguments must be integer: *")
  | Lt, IntV i1, IntV i2 -> BoolV (i1 < i2)
  | Lt, _, _ -> err ("Both arguments must be integer: <")

let rec eval_exp env = function
    Var x -> 
      (try Environment.lookup x env with 
        Environment.Not_bound -> err ("Variable not bound: " ^ x))
  | ILit i -> IntV i
  | BLit b -> BoolV b
  | BinOp (op, exp1, exp2) -> 
      let arg1 = eval_exp env exp1 in
      let arg2 = eval_exp env exp2 in
      apply_prim op arg1 arg2
  | IfExp (exp1, exp2, exp3) ->
      let test = eval_exp env exp1 in
        (match test with
            BoolV true -> eval_exp env exp2
          | BoolV false -> eval_exp env exp3
          | _ -> err ("Test expression must be boolean: if"))

let eval_decl env = function
    Exp e -> let v = eval_exp env e in ("-", env, v)
#{`}
\end{boxedminipage}
  \caption{MiniML1 インタプリタ: 評価部の実装(`eval.ml`)の抜粋}
  \label{fig:eval_exp}
\end{figure}

\subsection{\texttt{cui.ml}}

メインプログラム `main.ml` は`cui.ml`中で定義されてい
る`read_eval_print`という関数を呼び出している．関
数`read_eval_print`は，
\begin{enumerate}
\item 入力文字列の読み込み・構文解析
\item 解釈
\item 結果の出力
\end{enumerate}
処理を繰返している．まず，`let decl = ` の右辺で字句解析部・構文解析部
の結合を行っている．`lexer.mll` で宣言された規則の名前 `main` が関数
`Lexer.main` に，`parser.mly` (の `%start`)で宣言された非終端記号の名
前 `toplevel` が関数 `Parser.toplevel` に対応している．これらの関数は
それぞれ ocamllex と Menhir によって自動生成された関数である．
`Parser.toplevel` は第一引数として構文解析器から呼び出す字句解析器を，
第二引数として読み込みバッファを表す `Lexing.lexbuf` 型の値を取る．標
準ライブラリの`Lexing`モジュールの説明を読むと分かるが，
`Lexing.lexbuf`の作り方にはいくつか方法がある．ここでは標準入力から読
み込むため `Lexing.from_channel` を使って作られている．`pp_val` は
`eval.ml` で定義されている，値をディスプレイに出力するための関数である．

\begin{digression}{標準ライブラリ}
  本書を書いている時点では，OCamlの標準ライブラリは\ocamlURL{}で
  ``Documentation'' $\rightarrow$ ``OCaml Manual'' $\rightarrow$ ``The
  standard library'' の順にリンクをたどると出て来る．このページには標
  準ライブラリで提供されている関数がモジュールごとに説明されている．

  なお，OCamlの標準ライブラリは必要最低限の関数のみが提供されている
  ため，OCamlでソフトウェアを作る際にはその他のライブラリの力を借り
  ることが多い．様々なライブラリをパッケージマネージャの opam を用いて
  インストールすることができる．
\end{digression}

% \begin{figure}
%   \centering
% \begin{boxedminipage}{\textwidth}
% \begin{progeg}
% \input{../src/1/main.ml}
% \end{progeg}
% \end{boxedminipage}
%   \caption{MiniML1 インタプリタ: `main.ml`}
%   \label{fig:main.ml}
% \end{figure}

\subsection{`Parser`モジュール，`Lexer`モジュール：字句解析と構文解析}

この節では`Parser`モジュールと`Lexer`モジュールの機能
と`parser.mly`と`lexer.mll`の構成について説明する．字句解析と構文解析に
ついて後回しにしたい場合は，とりあえず読み飛ばしても構わない．

`Parser`と`Lexer`はそれぞれ構文解析と字句解析を行うモジュールである．
`Parser`モジュールは Menhir というツールを用いて\texttt{parser.mly}とい
うファイルから，`Lexer`モジュールは ocamllex というツールを用いて
\texttt{lexer.mll}というファイルからそれぞれ自動生成される．

Menhir は\intro{LR(1)構文解析}{LR(1) parsing}という手法を用いて，BNFっぽ
く書かれた文法定義（ここでは\texttt{parser.mly}）から，構文解析を行う
OCaml のプログラム（ここでは\texttt{parser.ml}と\texttt{parser.mli}）を
自動生成する．また，ocamllex は\intro{正則表現}{regular expression}を使っ
て書かれたトークンの定義（ここでは\texttt{lexer.mll}）から，字句解析を行
う OCaml のプログラム（ここでは\texttt{lexer.ml}）を自動生成する．生成さ
れたプログラムがどのように字句解析や構文解析を行うかはこの講義の後半で触
れる．そのような仕組みの部分を抜きにして，ここでは`.mly`ファイルや`.mll`
ファイルの書き方を説明する．

% Menhir は，yacc と同様に，LR(1) の文法を定義したファイルから構文解析プロ
% グラムを生成するツールである．ここでは，LR(1) 文法や構文解析アルゴリズム
% などに関しての説明などは割愛し(コンパイラの教科書などを参照のこと)，文法
% 定義ファイルの説明を `parser.mly` を具体例として行う．

\subsubsection*{文法定義ファイルの書き方}

拡張子`.mly`文法定義ファイルは一般に，以下のように4つの部分から構成される．
%
#{&}
%\{
  \metasym{ヘッダ}
%\}
  \metasym{宣言}
%%
  \metasym{文法規則}
%%
  \metasym{トレイラ}
#{`}
%
\metasym{ヘッダ}, \metasym{トレイラ} は OCaml のプログラムを書く部分
で，Menhir が生成する `parser.ml` の，それぞれ先頭・末尾にそのまま埋め込
まれる．\metasym{宣言}はトークン(終端記号)や，開始記号，優先度などの宣言
を行う．`parser.mly` では演習を通して，開始記号とトークンの宣言のみを使
用する．\metasym{文法規則}には文法記述と還元時のアクションを記述する．コ
メントは OCaml と同様 `(* ... *)` である．\footnote{ヘッダ部分とトレ
イラ部分以外では`/* ... */`と`//...`が使えるらしい．}

それでは `parser.mly` を見てみよう(図\ref{fig:parser.mly})．\footnote{以
降の話は結構ややこしいかもしれないので，全部理解しようとせずに，
`parser.mly`と`lexer.mll`を適当にいじって遊ぶ，くらいの気楽なスタンスの
ほうがよいかもしれない．}
%
\begin{figure}
  \centering
  \begin{boxedminipage}{0.95\textwidth}
#{&}
%{
open Syntax
%}

%token LPAREN RPAREN SEMISEMI
%token PLUS MULT LT
%token IF THEN ELSE TRUE FALSE

%token <int> INTV
%token <Syntax.id> ID

%start toplevel
%type <Syntax.program> toplevel
%%

toplevel :
    e=Expr SEMISEMI \{ Exp e \}

Expr :
    e=IfExpr \{ e \}
  | e=LTExpr \{ e \}

LTExpr : 
    l=PExpr LT r=PExpr \{ BinOp (Lt, l, r) \}
  | e=PExpr \{ e \}

PExpr :
    l=PExpr PLUS r=MExpr \{ BinOp (Plus, l, r) \}
  | e=MExpr \{ e \}

MExpr : 
    l=MExpr MULT r=AExpr \{ BinOp (Mult, l, r) \}
  | e=AExpr \{ e \}

AExpr :
    i=INTV \{ ILit i \}
  | TRUE   \{ BLit true \}
  | FALSE  \{ BLit false \}
  | i=ID   \{ Var i \}
  | LPAREN e=Expr RPAREN \{ e \}

IfExpr :
    IF c=Expr THEN t=Expr ELSE e=Expr \{ IfExp (c, t, e) \}
#{`}
%$
  \end{boxedminipage}
  \caption{MiniML1 インタプリタ: `parser.mly`}
  \label{fig:parser.mly}
\end{figure}
この文法定義ファイルではトレイラは空になっていて，その前の`%%`は省略され
ている．

\begin{itemize}
\item ヘッダにある `open Syntax` 宣言はモジュール`Syntax`内で定義されて
      いるコンストラクタや型の名前を，`Syntax.`というプレフィクス無しで
      使うという OCaml の構文である．（これがないと，例えばコンストラク
      タ`Var`を参照するときに`Syntax.Var`と書かなくてはならない．
      \footnote{OCaml以外にもこの手の機構が用意されていることが多い．例
      えばJavaではパッケージの`import`，Pythonでは`import`文がこれに相当
      する．なお，`open`はモジュール内の名前に容易にアクセスすることを可
      能にするが，外のモジュールで定義されている名前との衝突も起きやすく
      するという諸刃の剣である．この辺の話は時間があれば講義で少し触れ
      る．}）
\item `%token `\metasym{トークン名}` ...`は，\intro{属性}{attribute}を持
      たないトークンの宣言である．属性とは，トークンに関連付けられた（以
      下で説明する）還元時アクションの中で参照することができる値のことで
      ある．属性を持つトークンを見ればなるほどと納得が行くかもしれない．
      `parser.mly`中では括弧 ``$\ML{(}$''，``$\ML{)}$'' と，入力の終了を
      示す ``$\ML{;;}$'' に対応するトークン`LPAREN`, `RPAREN`，
      `SEMISEMI`と，プリミティブ ($\ML{+}$, $\ML{*}$, $\ML{<}$)に対応す
      るトークン `PLUS`, `MULT`, `LT`, 予約語\ML{if}, \ML{then},
      \ML{else}, \ML{true}, \ML{false} に対応するトークンが宣言されてい
      る．(図\ref{fig:syntax.ml}に現れる構文木のコンストラクタ `Plus` な
      どとの区別に注意すること．トークン名は全て英大文字としている．) こ
      の宣言で宣言されたトークン名はMenhirの出力する `parser.ml` 中で，
      `token` 型の(引数なし)コンストラクタになる．字句解析プログラムは文
      字列を読み込んで，この型の値(の列)を出力することになる．

\item `%token <`\metasym{型}`> `\metasym{トークン名}` ...`は，属性つきの
      トークン宣言である．数値のためのトークン `INTV`（属性はその数値情
      報なので `int` 型）と変数のための `ID`（属性は変数名を表す
      `Syntax.id` 型\footnote{ヘッダ部の\texttt{open}宣言はトークン宣言
      部分では有効ではないので，\texttt{Syntax.} をつけることが必要であ
      る．}）を宣言している．\finish{Menhirでも`Syntax.`は必要？}この宣
      言で宣言されたトークン名は `parser.ml` 中で，\metasym{型}を引数と
      する `token` 型のコンストラクタになる．

\item `%start `\metasym{開始記号名}` ...` で(一つ以上の)開始記号の名前を
      指定する．Menhir が生成する `parser.ml` ファイルでは，同名の関数が
      構文解析関数として宣言される．ここでは `toplevel` という名前を宣言
      しているので，後述する `main.ml` では `Parser.toplevel` という関数
      を使用して構文解析をしている．開始記号の名前は，次の `%type`宣言で
      も宣言されていなくてはならない．

\item `%type <`\metasym{型}`> `\metasym{名前}` ...`名前の属性を指定する
      宣言である，`toplevel` はひとつのプログラムの抽象構文木を表すので
      属性は`Syntax.program` 型となっている．

\item 文法規則は，
%
#{&}
\metasym{非終端記号名} : 
   (\metasym{変数名\(\sb{11}\)}=)\metasym{記号名\(\sb{11}\)} ... (\metasym{変数名\(\sb{1n\sb{1}}\)}=)\metasym{記号名\(\sb{1n\sb{1}}\)} 
   \{ \metasym{還元時アクション\(\sb{1}\)} \}
 | (\metasym{変数名\(\sb{21}\)}=)\metasym{記号名\(\sb{21}\)} ... (\metasym{変数名\(\sb{2n\sb{2}}\)}=)\metasym{記号名\(\sb{2n\sb{2}}\)} 
   \{ \metasym{還元時アクション\(\sb{1}\)} \}
 ...
#{`}
%
のように記述する．\metasym{記号名}の場所にはそれぞれ非終端記号か終端記号
      を書くことができる．「\metasym{変数名}=」の部分は省略してもよい．
      \metasym{還元時アクション}の場所には OCaml の式を記
述する．

構文解析器は，開始記号から始めて，与えられたトークン列を生成するために適
      用すべき規則を適切に発見し，それぞれの規則の還元時アクションを評価
      して，評価結果を規則の左辺の非終端記号の属性とすることで，開始記号
      の属性を計算する．と言われてもよく分からないと思うので，
      図~\ref{fig:parser.mly}の文法定義を例にとって説明する．この文法定義
      から生成される構文解析器に`TRUE SEMISEMI`というトークン列が与えら
      れたとしよう．\footnote{このトークン列は`true;;`という文字列を
      \texttt{lexer.mll}から生成される字句解析器に与えることで生成され
      る．}このトークン列は開始記号`toplevel`から始めて以下のように規則
      を適用すると得られることが分かる．\footnote{ちなみに，なぜこれが
      「分かる」のかが構文解析アルゴリズムの大きなテーマである．構文解析
      アルゴリズムについては講義中に扱うので，それまでは何らかの方法でこ
      れが分かるのだと流してほしい．}
%
#{&}
\underline{toplevel}
--（規則 toplevel: Expr SEMISEMI を用いて）-->
\underline{Expr} SEMISEMI
--（規則 Expr: LTExpr を用いて）-->
\underline{LTExpr} SEMISEMI
--（規則 LTExpr: PExpr を用いて）-->
\underline{PExpr} SEMISEMI
--（規則 PExpr: MExpr を用いて）-->
\underline{MExpr} SEMISEMI
--（規則 MExpr: AExpr を用いて）-->
\underline{AExpr} SEMISEMI
--（規則 AExpr: TRUE を用いて）-->
TRUE SEMISEMI
#{`}
%
各ステップで規則が適用された非終端記号に下線を付した．各ステップで用いら
      れた規則を確認してほしい．

構文解析器は，この導出列を遡りながら，還元時アクションを評価し，各規則の
      左辺にある非終端記号の属性を計算する．例えば，
#{&}
\underline{AExpr} SEMISEMI
--（規則 AExpr: TRUE を用いて）-->
TRUE SEMISEMI
#{`}
の規則が適用されている場所では，左辺の非終端記号`AExpr`の属性が還元時ア
      クション`BLit true`の評価結果（すなわち，`BLit true`という値）とな
      る．ここで計算された属性は，その一つ手前の導出
#{&}
\underline{MExpr} SEMISEMI
--（規則 MExpr: AExpr を用いて）-->
\underline{AExpr} SEMISEMI
#{`}
で`MExpr`の属性を計算するのに使われる．ここで図~\ref{fig:parser.mly}の対
      応する規則の右辺は`e=AExpr`となっているが，これは先程計算した
      `AExpr`の属性を`e`という名前で還元時アクションの中で参照できること
      を表している．ここでは還元時アクションは`e`なので，`MExpr`の属性は
      `e`，すなわち`AExpr`の属性である`BLit true`となる．これを繰り返す
      と，開始記号`toplevel`の属性が`Exp (BLit true)`と計算され，これが
      トークン列`TRUE SEMISEMI`に対する構文解析器の出力となる．
\end{itemize}

図\ref{fig:parser.mly}の文法規則が，\ref{sec:MiniML1syntax}節で述べた結
合の強さ，左結合などを実現していることを確かめてもらいたい．

\subsubsection*{トークン定義ファイルの書き方}

さて，この構文解析器への入力となるトークン列を生成するのが字句解析器で
ある．より正確には，字句解析器は文字の列を受け取って，その文字列をトー
クン列に変換する関数である．この関数をアルゴリズムの実装には，文字をア
クションとする有限状態オートマトンを用いることが多い．\footnote{有限状
  態オートマトンについては，京大の情報学科では「言語・オートマトン」と
  いう講義で習うはずである．}ただし，必要な有限状態オートマトンとその実
行を一から実装するのは大変なので，どの文字列をどのトークンに対応付ける
べきかを記述したファイルから，有限状態オートマトンを用いて字句解析を行
うプログラムを自動生成する lex や flex と呼ばれるツールを使うことが多い．
本講義では実装言語として OCaml を用いる関係上，OCaml から使うのに便利
な ocamllex と呼ばれるツールを用いることにする．

ocamllex は正則表現を使ってどのような文字列からどのようなトークンを生成
すべきかを指定する．（正則表現は lex や flex においても同様に用いられ
る．）この指定は拡張子 `.mll` を持つファイルに以下のように記述する．
%
#{&}
\{ \metasym{ヘッダ} \}

let \metasym{名前} = \metasym{正則表現}
...

rule \metasym{エントリポイント名} =
  parse \metasym{正則表現} \{ \metasym{アクション} \}
    |   \metasym{正則表現} \{ \metasym{アクション} \}
    |   ...
and \metasym{エントリポイント名} =
  parse ...
and ...
\{ \metasym{トレイラ} \}
#{`}
%
ヘッダ・トレイラ部には，OCaml のプログラムを書くことがで
き，ocamllex が生成する `lexer.ml` ファイルの先頭・末尾に埋め 込まれる．
次の `let` を使った定義部は，よく使う正則表現に名前をつけるための部分
で，`lexer.mll` では何も定義されていない．続く部分がエントリポイント，
つまり字句解析の規則の定義で，同名の関数が ocamllex によって生成される．
規則としては正則表現とそれにマッチした際のアクションを(OCaml式で)記
述する．アクションは，基本的には(`parser.mly` で宣言された)トーク
ン(`Parser.token` 型)を返すような式を記述する．また，字句解析に使用する
文字列バッファが `lexbuf` という名前で使えるが，通常は以下の使用法でし
か使われない．
\begin{itemize}
\item `Lexing.lexeme lexbuf` で，正則表現にマッチした文字列を取り出す．
\item `Lexing.lexeme_char lexbuf n` で，マッチした文字列の `n` 番目の
文字を取り出す．
\item `Lexing.lexeme_start lexbuf` で，マッチした文字列の先頭が入力文
  字列全体でどこに位置するかを返す．末尾の位置は %
  `Lexing.lexeme_end lexbuf` で知ることができる． 
\item \metasym{エントリポイント}` lexbuf` で，\metasym{エントリポイン
    ト}規則を呼び出す． 
\end{itemize}


それでは，具体例 `lexer.mll` を使って説明を行う．
%%
\begin{figure}
  \centering
\begin{boxedminipage}{0.95\textwidth}
#{&}
\{
let reservedWords = [
  (* Keywords in the alphabetical order *)
  ("else", Parser.ELSE);
  ("false", Parser.FALSE);
  ("if", Parser.IF);
  ("then", Parser.THEN);
  ("true", Parser.TRUE);
] 
\}

rule main = parse
  (* ignore spacing and newline characters *)
  [' ' '\\009' '\\012' '\\n']+     \{ main lexbuf \}

| "-"? ['0'-'9']+
    \{ Parser.INTV (int_of_string (Lexing.lexeme lexbuf)) \}

| "(" \{ Parser.LPAREN \}
| ")" \{ Parser.RPAREN \}
| ";;" \{ Parser.SEMISEMI \}
| "+" \{ Parser.PLUS \}
| "*" \{ Parser.MULT \}
| "<" \{ Parser.LT \}

| ['a'-'z'] ['a'-'z' '0'-'9' '_' '\'']*
    \{ let id = Lexing.lexeme lexbuf in
      try 
        List.assoc id reservedWords
      with
      _ -> Parser.ID id
     \}
| eof \{ exit 0 \}
#{`}
\end{boxedminipage}
\caption{MiniML1 インタプリタ: `lexer.mll`}
  \label{fig:lexer.mll}
\end{figure}
%%
ヘッダ部では，予約語の文字列と，それに対応するトークンの連想リストであ
る，`reservedWords` を定義している．後でみるように，`List.assoc`関数を
使って，文字列からトークンを取り出すことができる．

エントリポイント定義部分では，`main` という(唯一の)エントリポイントが
定義されている．最初の正則表現は空白やタブなど文字の列にマッチする．こ
れらは \miniMLname では区切り文字として無視するため，トークンは生成せず，
後続の文字列から次のトークンを求めるために `main lexbuf` を呼び出して
いる．次は，数字の並びにマッチし，`int_of_string` を使ってマッチした文
字列を`int` 型に直して，トークン `INTV` (属性は `int` 型)を返す．続い
ているのは，記号に関する定義である．次は識別子のための正則表現で，英小文字で
始まる名前か，演算記号にマッチする．アクション部では，マッチした文字列
が予約語に含まれていれば，予約語のトークンを，そうでなければ(例外
`Not_found` が発生した場合は) `ID` トークンを返す．最後の `eof` はファ
イルの末尾にマッチする特殊なパターンである．ファイルの最後に到達したら
`exit` するようにしている．

なお，この部分は，今後もあまり変更が必要がないので，正則表現を記述する
ための表現についてはあまり触れていない．興味のあるものは lex を解説し
た本やOCamlマニュアルを参照すること． 

\begin{mandatoryexercise}
MiniML1 インタプリタのプログラムをコンパイル・実行し，
インタプリタの動作を確かめよ．大域環境として $\ML{i}$, $\ML{v}$, 
$\ML{x}$ の値のみが
定義されているが，$\ML{ii}$ が 2，$\ML{iii}$ が 3，$\ML{iv}$ が 4 
となるようにプログラムを変更して，動作を確かめよ．例えば，
\begin{quote}\sf
iv + iii * ii
\end{quote}
などを試してみよ．
\end{mandatoryexercise}

\begin{optexercise}{2}
このインタプリタは文法にあわない入力を与えたり，束縛されていない変数を
参照しようとすると，プログラムの実行が終了してしまう．このような入力を
与えた場合，適宜メッセージを出力して，インタプリタプロンプトに戻るよう
に改造せよ．
\end{optexercise}

\begin{optexercise}{1}
論理値演算のための二項演算子 $\ML{\&\&}$, $\ML{||}$ を追加せよ．
\end{optexercise}

\begin{optexercise}{2}
  \texttt{lexer.mll}を改造し，`(*`と`*)`で囲まれたコメントを読み飛ばす
  ようにせよ．なお，OCamlのコメントは入れ子にできることに注意せよ．
  ocamllex のドキュメントを読む必要があるかもしれない．（ヒント：
    `comment`という再帰的なルールを\texttt{lexer.mll}に新しく定義する
    とよい．）
  \end{optexercise}
