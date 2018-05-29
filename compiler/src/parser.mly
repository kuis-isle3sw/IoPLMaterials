%{
open Syntax
%}

%token LPAREN RPAREN SEMISEMI
%token PLUS MULT LT EQ
%token IF THEN ELSE TRUE FALSE LET REC IN AND

%token <int> INTV
%token <Syntax.id> ID

%start toplevel
%type <Syntax.pgm> toplevel
%%

toplevel :
    e=Expr SEMISEMI { ([], e) }
  | ds=Decls IN e=Expr SEMISEMI { (ds, e) }

Decls :
    d=Decl { [d] }
  | d=Decl AND ds=Decls { d::ds }

Decl :
    LET REC i=ID p=ID EQ e=Expr
      { if i = p then
          err "Name conflict"
        else if i = "main" then
          err "user-defined main function is not allowed."
        else
          LetRecDecl (i, p, e) }

Expr :
    e=IfExpr     { e }
  | e=LetExpr    { e }
  | e=LTExpr     { e }

LTExpr :
    e1=PExpr LT e2=PExpr { BinOp (Lt, e1, e2) }
  | e=PExpr { e }

PExpr :
    e1=PExpr PLUS e2=MExpr { BinOp (Plus, e1, e2) }
  | e=MExpr { e }

MExpr :
    e1=MExpr MULT e2=AppExpr { BinOp (Mult, e1, e2) }
  | e=AppExpr { e }

AppExpr :
    e1=AppExpr e2=AExpr { AppExp (e1, e2) }
  | e=AExpr { e }

AExpr :
    i=INTV { ILit i }
  | TRUE { BLit true }
  | FALSE { BLit false }
  | i=ID { Var i }
  | LPAREN e=Expr RPAREN { e }

IfExpr :
    IF e1=Expr THEN e2=Expr ELSE e3=Expr { IfExp (e1, e2, e3) }

LetExpr :
    LET i=ID EQ e1=Expr IN e2=Expr { LetExp (i, e1, e2) }
