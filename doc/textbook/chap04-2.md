{% include head.html %}

# MiniML2 のための型推論 (1): 型システムの定義

この節では，MiniML2 の型推論アルゴリズムを設計するために，まず MiniML2 の型システムを定義する．

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

我々がこれから作ろうとする型推論アルゴリズムは，式`e`を受け取って，その`e`の型を（くどいようだが）_`e`を評価することなく_ 推論する．ここでさらっと「`e`の型」と書いたが，この言葉の意味するところはそんなに明らかではない．素直に考えれば「`e`を評価して得られる値`v`の型」ということになるのだが「じゃあ`v`の型って何？」「`v`の型を定義できたとして，型推論アルゴリズムが正しくその型を推論できていることはどう保証するの？」「`e`が停止しないかもしれないプログラムだったら評価して得られる値はどう定義するの？」などの問題点にクリアに答えられるようにアルゴリズムを作りたい．

そのために，型推論アルゴリズムを作る際には，普通 _型とは何か_，_プログラム`e`が型$\tau$を持つのはどのようなときか_ 等をまず厳密に定義し，その型を発見するためのアルゴリズムとして型推論アルゴリズムを定義することが多い．このような，型に関する定義やアルゴリズムを含
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

## 型付け規則

型判断を導入したからには「正しい型判断」を定義しなければならない．これには _型付け規則 (typing rule)_ を使うのが定石である．これは，記号論理学の証明規則に似た「正しい型判断」の導出規則で

```
<型判断>1 ... <型判断>n
----------------------<規則名>
       <型判断>
```

という形をしている．横線の上の`<型判断>1 ... <型判断>n`を規則の _前提 (premise)_，下にある `<型判断>` を規則の _結論 (conclusion)_ と呼ぶ．例えば，以下は加算式の型付け規則である．

<!-- $\Gamma \vdash e_1 : \mathbf{int}$ $\quad$ $\Gamma \vdash e_2 : \mathbf{int}$ <br />
--------------------------------------------- \<T-Plus\> <br />
$\Gamma \vdash e_1 + e_2 : \mathbf{int}$ -->

$$
\begin{array}{c}
\Gamma \vdash e_1 : \mathbf{int} \quad \Gamma \vdash e_2 : \mathbf{int}\\
\rule{6cm}{1pt}\\
\Gamma \vdash e_1 + e_2 : \mathbf{int}
\end{array}
\textrm{T-Plus}
$$

この，型付け規則の直感的な意味（読み方）は，
_前提の型判断が全て導出できたならば，結論の型判断を導出してよい_
ということである．<sup>[導出規則についての注](#derivation)</sup>

<a name="derivation">導出規則についての注</a>（この脚注は意味がわからなければ飛ばして良い．）厳密には規則 `T-Plus` はメタ変数$e_1,e_2,\Gamma$を具体的な式や型環境に置き換えて得られる（無限個の）導出規則の集合を表したものである．例えば，$\emptyset \vdash 1 : \mathbf{int}$ という型判断が既に導出されていたとしよう．`T-Plus`の $\Gamma$ を $\emptyset$ に，$e_1$, $e_2$ をともに，$1$に具体化することによって，規則の _インスタンス (instance)_

$$
\begin{array}{c}
\emptyset \vdash 1 : \mathbf{int} \quad
\emptyset \vdash 1 : \mathbf{int}\\
\rule{8cm}{1pt}\\
\emptyset \vdash 1 + 1 : \mathbf{int}
\end{array}
\textrm{Instantiated T-Plus}\\
$$

<!-- $\emptyset \vdash 1 : \mathbf{int}$ $\quad$ $\emptyset \vdash 1 : \mathbf{int}$ <br />
--------------------------------------------------- \< Instantiated T-Plus\> <br />
$\emptyset \vdash 1 + 1 : \mathbf{int}$ -->

が得られる．この具体化された規則を使うと，型判断$\emptyset \vdash 1 + 1 : \mathbf{int}$が導出できる．

以下に，MiniML2 の型付け規則を，その背後にある直観とともに示す．（付言するが，ここでの説明は，あくまで理解の助けにするための型付け規則の背後にある直観であって，型付け規則自体ではない．）

### 変数に関する規則

$$
\begin{array}{c}
\Gamma(x) = \tau\\
\rule{5cm}{1pt}\\
\Gamma \vdash x : \tau
\end{array}
\textrm{T-Var}
$$

$\Gamma(x) = \tau$であれば，$\Gamma$のもとで式$x$が型$\tau$を持つという判断を導出してよい．$\Gamma$が式の中の自由変数の型を決めているということを表現している．

### 整数リテラルに関する規則

$$
\begin{array}{c}
\rule{5cm}{1pt}\\
\Gamma \vdash n : \mathbf{int}
\end{array}
\textrm{T-Int}
$$

整数リテラル$n$は，いかなる型環境の下でも型$\mathbf{int}$を持つ．そりゃそうですね．

### 真偽値リテラルに関する規則

$$
\begin{array}{c}
b = \mathbf{true} \mbox{ or } b = \mathbf{false}\\
\rule{5cm}{1pt}\\
\Gamma \vdash b : \mathbf{bool}
\end{array}
\textrm{T-Bool}
$$

また，式`true`と式`false`は，いかなる型環境の下でも型$\mathbf{bool}$を持つ．これらは直観的に理解できると思う．

### 加算に関する規則

$$
\begin{array}{c}
\Gamma \vdash e_1 : \mathbf{int} \quad
\Gamma \vdash e_2 : \mathbf{int}\\
\rule{6cm}{1pt}\\
\Gamma \vdash e_1 + e_2 : \mathbf{int}
\end{array}
\textrm{T-Plus}
$$

型環境$\Gamma$の下で式$e_1$と式$e_2$が型$\mathbf{int}$を持つことが導出できたならば，$\Gamma$の下で式$e_1 + e_2$が$\mathbf{int}$を持つことを導出してよい．加算が整数の上の演算であることからこのような規則になっている．

### 乗算に関する規則

$$
\begin{array}{c}
\Gamma \vdash e_1 : \mathbf{int} \quad
\Gamma \vdash e_2 : \mathbf{int}\\
\rule{6cm}{1pt}\\
\Gamma \vdash e_1 * e_2 : \mathbf{int}
\end{array}
\textrm{T-Mult}
$$

式$e_1 * e_2$も同様に整数の上の演算なので，型環境$\Gamma$の下で式$e_1$と式$e_2$が型$\mathbf{int}$を持つことが導出できたならば，$\Gamma$の下で式$e_1 * e_2$が$\mathbf{int}$を持つことを導出してよい．

### 比較演算に関する規則

$$
\begin{array}{c}
\Gamma \vdash e_1 : \mathbf{int} \quad
\Gamma \vdash e_2 : \mathbf{int}\\
\rule{6cm}{1pt}\\
\Gamma \vdash e_1 < e_2 : \mathbf{bool}
\end{array}
\textrm{T-Lt}
$$

型環境$\Gamma$の下で式$e_1$と式$e_2$が型$\mathbf{int}$を持つことが導出できたならば，$\Gamma$の下で式$e_1 < e_2$が$\mathbf{bool}$を持つことを導出してよい．これらは式$e_1 < e_2$が整数の比較演算で，返り値がブール値であることから設けられた規則である．

### `if`式に関する規則

$$
\begin{array}{c}
\Gamma \vdash e : \mathbf{bool \quad}
\Gamma \vdash e_1 : \tau \quad
\Gamma \vdash e_2 : \tau\\
\rule{10cm}{1pt}\\
\Gamma \vdash \mathbf{if}\ e\ \mathbf{then}\ e_1\ \mathbf{else}\ e_2 : \tau
\end{array}
\textrm{T-If}
$$

型環境$\Gamma$の下で式$e$が$\mathbf{bool}$を持ち，式$e_1$と式$e_2$が**同一の**型$\tau$を持つならば，$\mathbf{if}\ e\ \mathbf{then}\ e_1\ \mathbf{else}\ e_2$がその型$\tau$を持つことを導出してよい．式$e$は$\mathbf{if}$式の条件部分なので，型$\mathbf{bool}$を持つべきであることは容易に納得できるであろう．

式$e_2$と式$e_3$が同一の型$\tau$を持つべきとされていること，`if`式全体としてその型$\tau$を持つとされていることについては少し注意が必要である．これは，条件式$e_1$が`true`と`false`のどちらに評価されても実行時型エラーが起こらないようにするために設けられている条件である．これにより，_実際は絶対に実行時型エラーが起こらないのに型付け可能ではないプログラムが生じる．_ たとえば，
{% highlight ocaml %}
(if true then 1 else false) + 3
{% endhighlight %}
というプログラムを考えてみよう．このプログラムは，`if`式が必ず`1`に評価されるため，実行時型エラーは起こらない．しかし，この`if`式の`then`節の式`1`には型$\mathbf{int}$がつき，`else`節の式`false`には型$\mathbf{bool}$がつくので，`if`式は型付け不能である．<sup>[「型付け不能」についての注](#untypable)</sup>

<a name="untypable">「型付け不能」について</a>: ある式$e$が型付け不能であることを言うには，_いかなる$\Gamma$と$\tau$をもってきても_，$\Gamma \vdash e : \tau$を導けないことを言わなければならないので，この説明は厳密には不十分である．

### `let`式に関する規則

$$
\begin{array}{c}
\Gamma \vdash e_1 : \tau_1 \quad
\Gamma, x:\tau_1 \vdash e_2 : \tau_2\\
\rule{10cm}{1pt}\\
\Gamma \vdash \mathbf{let}\ x = e_1\ \mathbf{in}\ e_2 : \tau_2
\end{array}
\textrm{T-Let}
$$

まず，この規則に現れる $\Gamma, x:\tau$ は $\Gamma$ に $x$ は $\tau$ であるという情報を加えた拡張された型環境で，より厳密には，

$$
\begin{array}{c}
 (\Gamma, x:\tau)(y) = \left\{
   \begin{array}{l}
     \tau & (if \ x=y) \\
     \Gamma(y) & \textit{(otherwise)}
   \end{array}\right.
\end{array}
$$

で定義される．ただし，この型環境の定義域 $\mathbf{Dom}(\Gamma, x:\tau)$ は

$$
\mathbf{Dom}(\Gamma, x:\tau) = \mathbf{Dom}(\Gamma) \cup \{x\}
$$

で定義される．

この規則は，型環境$\Gamma$の下で式$e_1$が型$\tau_1$を持ち，式$e_2$が$\Gamma$を$x : \tau_1$というエントリで拡張して得られる型環境$\Gamma,x:\tau_1$の下で型$\tau_2$を持つならば，式$\mathbf{let}\ x = e_1\ \mathbf{in}\ e_2$は全体として$\tau_2$を持つという判断を導いてよい，ということを表している．．この規則は$\mathbf{let}$式がどのように評価されるかと合わせて考えると分かりやすい．式$\mathbf{let}\ x = e_1\ \mathbf{in}\ e_2$を評価する際には，まず$e_1$を現在の環境で評価し，得られた結果に$x$を束縛した上で$e_2$を評価して，その結果を全体の評価結果とする．そのため，型付け規則においても，$e_1$の型付けには（「現在の環境」に対応する）型環境$\Gamma$を使い，$e_2$の型付けには$e_1$の型$\tau_1$を$x$の型とした型環境$\Gamma,x:\tau_1$を用いるのである．

<!-- 規則の前提として括弧内に書かれているのは\mathbf{int}ro{付帯条件}{side condition}と呼ばれるもので，規則を使う際に成立していなければならない条件を示している． -->

## 型判断の導出

型付け規則を導入したところで，具体的にどのような型判断が「正しい」とされるのかを定義しよう．型判断
$\Gamma \vdash e : \tau$ は，これが上記の型付け規則で _導出できる (derivable)_ ときに正しい型判断であると決める．この型判断が導出できる，とは，根が型判断$\Gamma \vdash e : \tau$で，上記のすべての辺が型付け規則に沿っている木が存在することである．（すべての葉は前提が無い型付け規則が適用された形になっている．）この木を型判断$\Gamma \vdash e : \tau$を導出する _導出木 (derivation tree)_ という．

例えば，以下は型判断$x : \mathbf{int} \vdash \mathbf{let}\ y = 3\ \mathbf{in}\ x + y : \mathbf{int}$の導出木である．

TODO: 導出木の画像を貼る

このように導出木が存在するので，型判断$x : \mathbf{int} \vdash \mathbf{let}\ y = 3\ \mathbf{in}\ x + y : \mathbf{int}$ は正しい．

<!-- \[
\infer[\rn{T-Let}]{
  {x : \mathbf{int} \p \ML{let}\ y = 3\ \ML{in} x + y : \mathbf{int}}
}{
  \infer[\rn{T-Int}]{x : \mathbf{int} \p 3 : \mathbf{int}}{}
  &
  \infer[\rn{T-Plus}]
        {x : \mathbf{int}, y : \mathbf{int} \p x + y : \mathbf{int}}
        {
          \infer[\rn{T-Var}]{x : \mathbf{int}, y : \p x : \mathbf{int}}{}
          &
          \infer[\rn{T-Var}]{x : \mathbf{int}, y : \p y : \mathbf{int}}{}
        }
}
\] -->
