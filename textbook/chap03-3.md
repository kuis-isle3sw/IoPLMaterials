
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
