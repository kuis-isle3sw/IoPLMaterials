# Prerequisite

* コンパイラをコンパイルするには `ocamlbuild` が必要です．`opam install ocamlbuild` で入る
* 生成された asm ファイルを実行するには MIPS シミュレータがおそらく必要です．`spim` をおすすめしています．[https://sourceforge.net/projects/spimsimulator/files/] から自分の環境に合ったシミュレータをダウンロードしてください．

# `example` ディレクトリ中の `fib.ml` をコンパイルして実行するためのコマンド

```
$ cd src
$ make clean; make
$ ./main -o tmp.asm -v ../example/fib.ml
$ spim -file tmp.asm
```

# その他

* 使用方法は`./main --help`を参照．
* `rlwrap` がインストールされていれば，`src` 内で `rlwrap ./main -o tmp.asm -v` とするとインタプリタを使うようにコンパイラと対話できます．
