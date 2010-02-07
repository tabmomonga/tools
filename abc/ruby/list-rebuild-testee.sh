#!/bin/sh

unset LANG

../tools/abc/ruby/mo-specdb-update

svn log -l 50 | awk '$1=="==" && $3=="==" { print  $2;}' \
	| while read pkg; do
		../tools/abc/ruby/mo-specdb-provides $pkg \
			| while read cap; do
				../tools/abc/ruby/mo-specdb-whatbuildreqs $cap	
			done	
	done

