{% include head.html %}

# MiniML2 のための型推論

## 型の構文

まず，MiniML2 の式に対しての型推論を考える．MiniML2 では，トップレベル入力として，式だけでなく`let`宣言を導入したが，ここではひとまず式についての型推論のみを考え，`let`宣言については最後に扱うことにする．[ここでまず MiniML2 の文法を見てほしい](chap03-2#bnf)．
<!-- %
\begin{eqnarray*}
  e & ::= & x \mid n \mid \ML{true} \mid
  \ML{false} \mid e_1 \ \textit{op}\  e_2 \mid 
  \ML{if}\ e_1\ \ML{ then }\ e_2\ \ML{ else }\ e_3 
  \mid  \ML{let}\ x\ \ML{=}\ e_1\ \ML{in}\ e_2 \\
  \textit{op} & ::= & \ML{+} \mid \ML{*} \mid \ML{<} 
\end{eqnarray*}
%
% \AI{e と op のフォント揃えません？} -->
<!-- ここでは \metasym{式} の代わりに $e$ という記号(メタ変数)，\metasym
{識別子} の代わりに $x$ という記号(メタ変数)を用いている．また，型
(メタ変数 $\tau$)として，（\miniML{2}は関数を含まず，値は整数値とブー
  ル値のみなので）整数を表す$\mathbf{int}$, 真偽値を表す$\mathbf{bool}$を考える．
\footnote{\mathbf{int}ro{メタ変数}{metavariable}とは，プログラム中で使われる普
  通の変数と異なり，「式」「値」「型」などのプログラム中で現れる「もの」
  を総称的に指すために使われる変数である．例えば，上記のBNFでは「式」
  を表すメタ変数として$e$が，「自然数」を表すメタ変数として$n$が用いら
  れている．また，少しややこしいが，「変数」を表すメタ変数として$x$が
  用いられている．なお，「式 (expression) を表すメタ変数として$e$を用
    いる」ことを表す英語の表現はいくつかあり，''Expressions are ranged
  over by metavariable $e$'' とか，''$e$ is the metavariable that
  represents an expression'' とか言ったりする．} -->
この言語に対する型を考えるわけなのだが，何を型として扱えばよいだろうか．MiniML2 は関数を含まず，値は整数値とブール値のみなので，整数型と真偽値型があれば良さそうである．したがって，型の構文は，メタ変数を$\tau$として，以下のように定義しよう．

$$
\tau ::= \mathbf{int} \mid \mathbf{bool}.
$$

$\mathbf{int}$は整数型, $\mathbf{bool}$は真偽値型である．

## 型判断と型付け規則

我々がこれから作ろうとする型推論アルゴリズムは，式`e`を受け取って，その`e`の型を（くどいようだが）_`e`を評価することなく_ 推論する．ここでさらっと「`e`の型」と書いたが，この言葉の味するところはそんなに明らかではない．素直に考えれば「`e`を評価して得られる値`v`の型」ということになるのだが「じゃあ`v`の型って何？」「`v`の型を定義できたとして，型推論アルゴリズムが正しくその型を推論できていることはどう保証するの？」「`e`が停止しないかもしれないプログラムだったら評価して得られる値はどう定義するの？」などの問題点にクリアに答えられるようにアルゴリズムを作りたい．

そのために，型推論アルゴリズムを作る際には，普通 _型とは何か_，_プログラム`e`が型$\tau$を持つのはどのようなときか_ 等をまず厳密にに定義し，その型を発見するためのアルゴリズムとして型推論アルゴリズムを定義することが多い．このような，型に関する定義やアルゴリズムを含
む体系を _型システム (type system)_ と呼ぶ<sup>[こまけぇこたぁいいんだよ！についての注](#picky)</sup>．

<a name="picky">こまけぇこたぁいいんだよ！について</a>: 大体動けばいいんだよ，こまけぇこたぁいいんだよ！という考えもあるだろうが，だいたい動くと思って作ったものが動かないことはよくある．また，このように数学の俎上に乗るように体系を作っておくことで，「型がつくプログラムが実行時エラーを起こすことはない」（_型システムの健全性 (soundness of a type system)_）とか「型推論アルゴリズムの結果は正しい」（_型推論アルゴリズムの健全性 (soundness of a type inference algorithm)_）等の，型システム自体の性質に関する議論を数学を用いて厳密に行うことができる．また，型システムを設計するパターンをこのように大体決めておくことで，健全性の証明もある程度パターン化することができ，新しい言語に対する新しい型システムがきれいに容易に分かりやすく設計できるようになる．

「式$e$が型$\tau$を持つ」のような，式と型の間の関係のことを _型判断 (type judgment)_ と呼ぶ<sup>[「判断」という言葉について](#frege)</sup>．普通式と型の間の関係は$e : \tau$と書くので，ここでもこれに習おう．何が正しい型判断で，何が間違った型判断なのかをあとで定義するのだが，例えば「式`1+1`は$\mathbf{int}$を持つ」ように型システムを作りたいので，$1+1 : \mathbf{int}$は正しい型判断に
なるように，式`if 1 then 2+3 else 4`は型がつかないプログラムなので，$\mathbf{if}\ 1\ \mathbf{then}\ 2+3\ \mathbf{else}\ 4 : \tau$はいかなる$\tau$についても正しくない型判断となるようにしたい．

<a name="frege">「判断」という言葉について</a>: フレーゲかカントに由来するらしい．裏は取っていない．（誰か裏が取れたら教えて下さい．）

しかし，MiniML2 に意図通りに型判断を定義するのに$e$と$\tau$だけでは実は情報が足りない．一般に式には自由変数が現れるからである．例えば「式$x+2$は$\mathbf{int}$を持つ」は正しい判断にしたいだろうか．「それは$x$の型による」としか言いようがない．（$x$が$\mathbf{int}$型であれば正しい判断にしたいし，$x$が$\mathbf{bool}$型であれば正しい型判断と認めたくはないだろう．）このため，自由変数を含む式に対しては，それが持つ型を何か仮定しないと型判断は下せないことになる．

### 型環境

この状況は，[MiniML2 インタプリタを実装したとき](chap03-2#environment)に，自由変数の値への束縛を環境というデータ構造で管理したのと相似である．いわば，我々は今 _自由変数の型への束縛_ を管理するデータ構造を必要としているのである．この，変数の型への束縛を管理するデータ構造を _型環境 (type environment)_ と呼ぶ．(型環境を表すメタ変数として$\Gamma$を用いる．）これを使えば，変数に対する型判断は，例えば

> $\Gamma(x) = \mathbf{int}$ の時 $x: \mathbf{int}$ である  

のように設計すればよさそうである．このことを考慮に入れて，型判断は，$\Gamma \vdash e : \tau$ と記述し，

> 型環境 $\Gamma$ の下で式 $e$ は型 $\tau$ を持つ

と読む．また，空の型環境を$\emptyset$で表す．
型判断に用いた${\vdash}$ は数理論理学などで使われる記号で，「〜という仮定の下で判断〜が導出・証明される」くらいの意味である．インタプリタが(変数を含む)式の値を計算するために環境を使ったように，型推論器が式の型を計算するために型環境を使っていると考えればよい．

$\Gamma(x_1)=\tau_1,\dots,\Gamma(x_n)=\tau_n$を満たし，それ以外の変数については型が定義されていないような型環境を$x_1 : \tau_1,\dots,x_n : \tau_n$と書く．

### 型がつく，型付け可能，型付け不能

式$\Gamma \vdash e : \tau$が成り立つような$\Gamma$と$\tau$が存在するときに，$e$に _型がつく (well-typed)_，あるいは$e$は _型付け可能 (typable)_ という．逆にそのような$\Gamma$と$\tau$が存在しないときに，$e$は _型がつかない (ill-typed)_，あるいは$e$は _型付け不能 (untypable)_ という．

### 型付け規則

型判断を導入したからには「正しい型判断」を定義しなければならない．これには _型付け規則 (typing rule)_ を使うのが定石である．これは，記号論理学の証明規則に似た「正しい型判断」の導出規則で

```
<型判断>1 ... <型判断>n
----------------------<規則名>
       <型判断>
```

という形をしている．横線の上の`<型判断>1 ... <型判断>n`を規則の _前提 (premise)_，下にある `<型判断>` を規則の _結論 (conclusion)_ と呼ぶ．例えば，以下は加算式の型付け規則である．

>
$\Gamma \vdash e_1 : \mathbf{int}$ $\quad$ $\Gamma \vdash e_2 : \mathbf{int}$ <br />
--------------------------------------------- \<T-Plus\> <br />
$\Gamma \vdash e_1 + e_2 : \mathbf{int}$

この，型付け規則の直感的な意味（読み方）は，
_前提の型判断が全て導出できたならば，結論の型判断を導出してよい_
ということである．<sup>[導出規則についての注](#derivation)</sup>

<a name="derivation">導出規則についての注</a>（この脚注は意味がわからなければ飛ばして良い．）厳密には規則 `T-Plus` はメタ変数$e_1,e_2,\Gamma$を具体的な式や型環境に置き換えて得られる（無限個の）導出規則の集合を表したものである．例えば，$\emptyset \p 1 : \mathbf{int}$ という型判断が既に導出されていたとしよう．`T-Plus`の $\Gamma$ を $\emptyset$ に，$e_1$, $e_2$ をともに，$1$に具体化することによって，規則の _インスタンス (instance)_

>
$\emptyset \vdash 1 : \mathbf{int}$ $\quad$ $\emptyset \vdash 1 : \mathbf{int}$ <br />
--------------------------------------------------- \< Instantiated T-Plus\> <br />
$\emptyset \vdash 1 + 1 : \mathbf{int}$

が得られる．この具体化された規則を使うと，型判断$\emptyset \vdash 1 + 1 : \mathbf{int}$が導出できる．

TODO: ここまで書いた．型付け規則辛い．

以下に，\miniML{2}の型付け規則を示す．
%
\infrule[T-Var]{
  (\Gamma(x) = \tau)
}{
  \Gp x : \tau
}
\infrule[T-Int]{
}{
  \Gp n : \mathbf{int}
}
\infrule[T-Bool]{
  (b = @true@ \mbox{ または } b = @false@)
}{
  \Gp b : \mathbf{bool}
}
\infrule[T-Plus]{
  \Gp e_1 : \mathbf{int} \andalso
  \Gp e_2 : \mathbf{int}
}{
  \Gp e_1 \ML{ + } e_2 : \mathbf{int}
}
\infrule[T-Mult]{
  \Gp e_1 : \mathbf{int} \andalso
  \Gp e_2 : \mathbf{int}
}{
  \Gp e_1 \ML{ * } e_2 : \mathbf{int}
}
\infrule[T-Lt]{
  \Gp e_1 : \mathbf{int} \andalso
  \Gp e_2 : \mathbf{int}
}{
  \Gp e_1 \ML{ < } e_2 : \mathbf{bool}
}
\infrule[T-If]{
  \Gp e_1 : \mathbf{bool} \andalso
  \Gp e_2 : \tau \andalso
  \Gp e_3 : \tau
}{
  \Gp \ML{if}\ e_1\ \ML{then}\ e_2\ \ML{else}\ e_3 : \tau
}
\infrule[T-Let]{
  \Gp e_1 : \tau_1 \andalso
  \Gamma, x:\tau_1 \p e_2 : \tau_2
}{
  \Gp \ML{let}\ x\ \ML{=}\ e_1\ \ML{in}\ e_2 : \tau_2
}
%

規則\rn{T-Let}に現れる $\Gamma, x:\tau$ は $\Gamma$ に $x$ は
$\tau$ であるという情報を加えた拡張された型環境で，より厳密な定義と
しては，
\begin{gather*}
\dom(\Gamma, x:\tau) = \dom(\Gamma) \cup \set{x} \\
 (\Gamma, x:\tau)(y) = \left\{
   \begin{array}{cp{10em}}
     \tau & (if $x=y$) \\
     \Gamma(y) & (otherwise)
   \end{array}\right.
\end{gather*}
と書くことができる．（$\dom(\Gamma)$は$\Gamma$の定義域を表す．）規
則の前提として括弧内に書かれているのは\mathbf{int}ro{付帯条件}{side condition}
と呼ばれるもので，規則を使う際に成立していなければならない条件を示して
いる．

各々の型付け規則がなぜそのように定義されているか，少しずつ説明を加える．
\footnote{一応書いておくと，ここで説明するのはあくまで理解の助けにする
  ための，型付け規則の背後にある直観であって，型付け規則自体ではない．}
\begin{description}
  \item[\rn{T-Var}:] $\Gamma(x) = \tau$であれば，$\Gamma$のもとで式$x$
    が型$\tau$を持つという判断を導出してよい．$\Gamma$が式の中の自由変
    数の型を決めているという上述の説明から理解できるはずである．
  \item[\rn{T-Int},\rn{T-Bool}:] 整数定数$n$は，いかなる型環境の下でも
    型$\mathbf{int}$を持つ．また，式@true@と式@false@は，いかなる型環境の下で
    も型$\mathbf{bool}$を持つ．これらは直観的に理解できると思う．
  \item[\rn{T-Plus},\rn{T-Mult}:] 型環境$\Gamma$の下で式$e_1$と式$e_2$
    が型$\mathbf{int}$を持つことが導出できたならば，$\Gamma$の下で式
    $e_1\ML{+}e_2$が$\mathbf{int}$を持つことを導出してよい．式$e_1\ML{*}e_2$も
    同様である．これらは式$e_1\ML{+}e_2$と$e_1\ML{*}e_2$が，それぞれ整
    数の上の演算であることから設けられた規則である．
  \item[\rn{T-Lt}:] 型環境$\Gamma$の下で式$e_1$と式$e_2$が型$\mathbf{int}$を持
    つことが導出できたならば，$\Gamma$の下で式$e_1\ML{<}e_2$が$\mathbf{bool}$
    を持つことを導出してよい．これらは式$e_1\ML{<}e_2$が整数の比較演算
    で，返り値がブール値であることから設けられた規則である．
  \item[\rn{T-If}:] 型環境$\Gamma$の下で式$e_1$が$\mathbf{bool}$を持ち，式
    $e_2$と式$e_3$が\emph{同一の}型$\tau$を持つならば，
    $\ML{if}\ e_1\ \ML{then}\ e_2\ \ML{else}\ e_3$がその型$\tau$を持つ
    ことを導出してよい．式$e_1$は$\ML{if}$式の条件部分なので，型
    $\mathbf{bool}$を持つべきであることは良いであろう．式$e_2$と式$e_3$が同一
    の型$\tau$を持つべきとされていること，$\ML{if}$式全体としてその型
    $\tau$を持つとされていることについては少し注意が必要である．これは，
    条件式$e_1$が\ML{true}と\ML{false}のどちらに評価されても実行時型エ
    ラーが起こらないようにするために設けられている条件である．これによ
    り，\emph{実際は絶対に実行時型エラーが起こらないのに型付け可能では
      ないプログラムが生じる．}たとえば，\ML{(if true then 1 else
      false) + 3}というプログラムを考えてみよう．このプログラムは，
    \ML{if}式が必ず\ML{1}に評価されるため，実行時型エラーは起こらない．
    しかし，この\ML{if}式の\ML{then}節の式\ML{1}には型$\mathbf{int}$がつき，
    \ML{else}節の式\ML{false}には型$\mathbf{bool}$がつくので，\ML{if}式は型付
    け不能である．\footnote{ある式$e$が型付け不能であることを言うには，
      \emph{いかなる$\Gamma$と$\tau$をもってきても}，$\Gamma \vdash e
      \COL \tau$を導けないことを言わなければならないので，この説明は厳
      密には不十分である．}
  \item[\rn{T-Let}:]
    型環境$\Gamma$の下で式$e_1$が型$\tau_1$を持ち，
    式$e_2$が$\Gamma$を$x \COL \tau_1$というエントリで拡張して得られる
    型環境$\Gamma,x\COL\tau_1$の下で型$\tau_2$を持つならば，
    式$\ML{let}\ x = e_1\ \ML{in}\
    e_2$は全体として$\tau_2$を持つという判断を導いてよい．この規則
    は$\ML{let}$式がどのように評価されるかと合わせて考えると分かりやす
    い．式$\ML{let}\ x = e_1\ \ML{in}\ e_2$を評価する際には，ま
    ず$e_1$を現在の環境で評価し，得られた結果に$x$を束縛した上で$e_2$を
    評価して，その結果を全体の評価結果とする．そのため，型付け規則にお
    いても，$e_1$の型付けには（「現在の環境」に対応する）型環
    境$\Gamma$を使い，$e_2$の型付けには$e_1$の型$\tau_1$を$x$の型とした
    型環境$\Gamma,x\COL\tau_1$を用いるのである．
\end{description}

ここで型判断$\Gamma \p e \COL \tau$が\emph{導出できる}{derivable}とは，
根が型判断$\Gamma \p e \COL \tau$で，上記のすべての辺が型付け規則に沿っ
ている木が存在することである．（すべての葉は前提が無い型付け規則が適用
  された形になっている．）この木を型判断$\Gamma \p e \COL \tau$を導出
する\mathbf{int}ro{導出木}{derivation tree}という．例えば，以下は型判断$x \COL
\mathbf{int} \p \ML{let\ y = 3\ in\ x + y} \COL \mathbf{int}$の導出木である．
\[
\infer[\rn{T-Let}]{
  {x \COL \mathbf{int} \p \ML{let}\ y = 3\ \ML{in} x + y \COL \mathbf{int}}
}{
  \infer[\rn{T-Int}]{x \COL \mathbf{int} \p 3 \COL \mathbf{int}}{}
  &
  \infer[\rn{T-Plus}]
        {x \COL \mathbf{int}, y \COL \mathbf{int} \p x + y \COL \mathbf{int}}
        {
          \infer[\rn{T-Var}]{x \COL \mathbf{int}, y \COL \p x \COL \mathbf{int}}{}
          &
          \infer[\rn{T-Var}]{x \COL \mathbf{int}, y \COL \p y \COL \mathbf{int}}{}
        }
}
\]
この導出木が存在することが，型判断$x \COL \mathbf{int} \p \ML{let\ y =
  3\ in\ x + y} \COL \mathbf{int}$が正しいということの定義である．

\subsection{型推論アルゴリズム}

以上を踏まえると，型推論アルゴリズムの仕様は，以下のように考えることができる．
\begin{description}
  \item[入力:] 型環境 $\Gamma$ と式 $e$．
  \item[出力:] $\Gp e : \tau$ という型判断が導出できるような型
    $\tau$．もしそのような型がなければエラーを報告する．
\end{description}

さて，このような仕様を満たすアルゴリズムを，どのように設計したらよいだ
ろうか．これは，$\Gp e : \tau$を根とする導出木を構築すればよい．では，
このような導出木をどのように作ればよいだろうか．

この答えは型付け規則から得られる．上に挙げた型付け規則は\mathbf{int}ro{構文主
  導な規則}{syntax-directed rules}になっているというよい性質を持ってい
る．これは，$\Gamma$と$e$が与えられたときに，$\Gamma \p e \COL \tau$が
成り立つような$\tau$が存在するならば，これを導くような規則が$e$の形か
ら一意に定まるという性質である．例えば，$\Gamma$と$e$が与えられ，$e$が
$e_1 + e_2$という形をしていたとしよう．このとき，型推論アルゴリズムは
$\Gamma \p e \COL \tau$を根とする導出木を構築しようとする．型付け規則
をよく見ると，このような導出木は（存在するならば）最後の導出規則が
\rn{T-Plus}でしかありえない．すなわち，
\[
\infer[\rn{T-Plus}]
      {\Gamma \p e \COL \tau}
      {\vdots}
\]
という形の導出木だけを探索すればよいことになる．このように適用可能な最
後の導出規則が$e$の形から一意に定まる型付け規則を構文主導であるという．

構文主導な型付け規則を持つ型システムでは，各規則を下から上に読むことに
よって型推論アルゴリズムを得ることができることが多い．例えば，
\rn{T-Int} は入力式が整数リテラルならば，型環境に関わらず，\mathbf{int} を出力
する，と読むことができる．また，\rn{T-Plus}は
\begin{quote}
  入力式$e$が$e_1+e_2$の形をしていたならば，$\Gamma$と$e_1$を再帰的に
  型推論アルゴリズムに入力して型を求めて（これを$\tau_1$とする）
  $\Gamma$と$e_2$とを再帰的に型推論アルゴリズムに入力して型を求めて
  （これを$\tau_2$とする）$\tau_1$も$\tau_2$も両方とも \mathbf{int} であった場
  合には \mathbf{int} 型を出力する
\end{quote}
と読むことができる．\footnote{明示的に導出木を構築していないので，なぜ
  これで「導出木を構築している」ことになるのかよくわからないかもしれな
  い．この型推論アルゴリズムは再帰呼出しをしているが，この再帰呼出しの
  構造が導出木に対応している．}
\begin{mandatoryexercise}
図\ref{fig:MLb1}, 図\ref{fig:MLb2}に示すコードを参考にして，型推論アル
ゴリズムを完成させよ．
% （ソースファイルとして @typing.ml@ を追加するので，@make depend@ の実行を一度行うこと．）
\end{mandatoryexercise}

\begin{figure}
  \begin{flushleft}
%% @Makefile@: \\
%%   \begin{boxedminipage}{\textwidth}
%% #{&}
%% OBJS=syntax.cmo parser.cmo lexer.cmo \\
%%    environment.cmo \graybox{typing.cmo} eval.cmo main.cmo
%% #{@}
%%   \end{boxedminipage} \\
@syntax.ml@: \\
  \begin{boxedminipage}{\textwidth}
#{&}
\graybox{type ty =}
    \graybox{TyInt}
  \graybox{| TyBool}

\graybox{let pp_ty = function}
      \graybox{TyInt -> print_string "int"}
    \graybox{| TyBool -> print_string "bool"}
#{@}
  \end{boxedminipage} \\
@main.ml@: \\
  \begin{boxedminipage}{\textwidth}
#{&}
\graybox{open Typing}

let rec read_eval_print env \graybox{tyenv} =
   print_string "# ";
   flush stdout;
   let decl = Parser.toplevel Lexer.main (Lexing.from_channel stdin) in
   \graybox{let ty = ty_decl tyenv decl in}
   let (id, newenv, v) = eval_decl env decl in
     \graybox{Printf.printf "val %s : " id;}
     \graybox{pp_ty ty;}
     \graybox{print_string " = ";}
     pp_val v;
     print_newline();
     read_eval_print newenv \graybox{tyenv}

\graybox{let initial_tyenv =}
   \graybox{Environment.extend "i" TyInt}
     \graybox{(Environment.extend "v" TyInt}
       \graybox{(Environment.extend "x" TyInt Environment.empty))}

let _ = read_eval_print initial_env \graybox{initial_tyenv}
#{@}
\end{boxedminipage}
  \end{flushleft}
  \caption{\miniML{2} 型推論の実装 (1)}
  \label{fig:MLb1}
\end{figure}

\begin{figure}
  \begin{flushleft}
@typing.ml@: \\
  \begin{boxedminipage}{\textwidth}
#{&}
open Syntax

exception Error of string

let err s = raise (Error s)

(* Type Environment *)
type tyenv = ty Environment.t

let ty_prim op ty1 ty2 = match op with
    Plus -> (match ty1, ty2 with 
                 TyInt, TyInt -> TyInt
               | _ -> err ("Argument must be of integer: +"))
    ...
  | Cons -> err "Not Implemented!"

let rec ty_exp tyenv = function
    Var x -> 
      (try Environment.lookup x tyenv with
          Environment.Not_bound -> err ("variable not bound: " ^ x))
  | ILit _ -> TyInt
  | BLit _ -> TyBool
  | BinOp (op, exp1, exp2) ->
      let tyarg1 = ty_exp tyenv exp1 in
      let tyarg2 = ty_exp tyenv exp2 in
        ty_prim op tyarg1 tyarg2
  | IfExp (exp1, exp2, exp3) ->
      ...
  | LetExp (id, exp1, exp2) ->
      ...
  | _ -> err ("Not Implemented!")

let ty_decl tyenv = function
    Exp e -> ty_exp tyenv e
  | _ -> err ("Not Implemented!")
#{@}
\end{boxedminipage}
  \end{flushleft}
  \caption{\miniML{2} 型推論の実装 (2)}
  \label{fig:MLb2}
\end{figure}
