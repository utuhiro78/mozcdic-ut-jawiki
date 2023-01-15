#!/bin/bash

# Author: UTUMI Hirosi (utuhiro78 at yahoo dot co dot jp)
# License: APACHE LICENSE, VERSION 2.0

cp ../mozcdic-ut-jawiki.txt.tar.bz2 .
tar xf mozcdic-ut-jawiki.txt.tar.bz2

ruby generate_jawiki_ut.rb
ruby adjust_entries.rb mozcdic-ut-jawiki.txt
ruby filter_unsuitable_words.rb mozcdic-ut-jawiki.txt

ruby generate_cost.rb
ruby apply_cost.rb mozcdic-ut-jawiki.txt

tar cjf mozcdic-ut-jawiki.txt.tar.bz2 mozcdic-ut-jawiki.txt
mv mozcdic-ut-jawiki.txt* ../

rm -rf mozcdic-ut-jawiki-release/
rsync -a ../* mozcdic-ut-jawiki-release --exclude=jawiki-* --exclude=mecab-* --exclude=mozcdic-ut-*.txt
