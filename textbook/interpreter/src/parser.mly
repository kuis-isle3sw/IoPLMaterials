%{
open Syntax
%}

%token LPAREN RPAREN SEMISEMI
%token PLUS MULT LT LAND LOR
%token IF THEN ELSE TRUE FALSE
%token LET IN EQ AND
%token RARROW FUN
%token EOF

%token <int> INTV
%token <Syntax.id> ID

%start toplevel
%type <Syntax.program> toplevel
%%

toplevel :
    e=Expr SEMISEMI { Exp e }
  | ds=Decls SEMISEMI { Decls ds }

Decls :
  | { [] }
  | LET bs=LetBindings ds=Decls { bs :: ds }

Expr :
    e=IfExpr { e }
  | e=LetExpr { e }
  | e=LORExpr { e }
  | e=FunExpr { e }

LORExpr :
    l=LANDExpr LOR r=LANDExpr { BinOp (Or, l, r) }
  | e=LANDExpr { e }

LANDExpr :
    l=LTExpr LAND r=LTExpr { BinOp (And, l, r) }
  | e=LTExpr { e }

LTExpr :
    l=PExpr LT r=PExpr { BinOp (Lt, l, r) }
  | e=PExpr { e }

PExpr :
    l=PExpr PLUS r=MExpr { BinOp (Plus, l, r) }
  | e=MExpr { e }

MExpr :
    l=MExpr MULT r=AppExpr { BinOp (Mult, l, r) }
  | e=AppExpr { e }

AppExpr :
  | e1=AppExpr e2=AExpr { AppExp (e1, e2) }
  | e=AExpr { e }

AExpr :
    i=INTV { ILit i }
  | TRUE   { BLit true }
  | FALSE  { BLit false }
  | name=ValueName   { Var name }
  | LPAREN e=Expr RPAREN { e }

// NOTE:
// Since I don't know how to convert the token back to the original string,
// I'm writing it directly, even though it doesn't seem very good.
BinOp :
  | PLUS { "+" }
  | MULT { "*" }
  | LT { "<" }
  | LAND { "&&" }
  | LOR { "||" }

IfExpr :
    IF c=Expr THEN t=Expr ELSE e=Expr { IfExp (c, t, e) }

FunExpr :
  | FUN x=ID RARROW e=Expr { FunExp (x, e) }

LetExpr :
    LET bs=LetBindings IN e=Expr { LetExp (bs, e) }

LetBindings :
  | x=ValueName EQ e=Expr { [(x, e)] }
  | x=ValueName EQ e=Expr AND l=LetBindings { (x, e) :: l }

ValueName :
  | i=ID { i }
  | LPAREN binOp=BinOp RPAREN { binOp }
