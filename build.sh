#!/bin/sh

SITETEXTBOOKPATH=_site/textbook

bundle exec jekyll build &&
    for name in $(find $SITETEXTBOOKPATH -type f -name "chap*.html" -exec basename \{\} \; | sed "s/.html//")
    do
	echo Generating $name.pdf
	pandoc $SITETEXTBOOKPATH/$name.html -o $SITETEXTBOOKPATH//$name.pdf --pdf-engine=lualatex -V documentclass=ltjsarticle -V luatexjapresetoptions=hiragino-pron
    done
# | ""
