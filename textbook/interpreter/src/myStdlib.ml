open Syntax

let program =
  Decls
    [
      [ ("+", FunExp ("x", FunExp ("y", BinOp (Plus, Var "x", Var "y")))) ];
      [ ("*", FunExp ("x", FunExp ("y", BinOp (Mult, Var "x", Var "y")))) ];
      [ ("<", FunExp ("x", FunExp ("y", BinOp (Lt, Var "x", Var "y")))) ];
      [ ("&&", FunExp ("x", FunExp ("y", BinOp (And, Var "x", Var "y")))) ];
      [ ("||", FunExp ("x", FunExp ("y", BinOp (Or, Var "x", Var "y")))) ];
    ]
