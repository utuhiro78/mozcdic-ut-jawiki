#!/bin/bash

# Author: UTUMI Hirosi (utuhiro78 at yahoo dot co dot jp)
# License: Apache License, Version 2.0

ruby generate_jawiki_ut.rb
ruby adjust_entries.rb mozcdic-ut-jawiki.txt
ruby filter_unsuitable_words.rb mozcdic-ut-jawiki.txt

ruby count_word_hits.rb
ruby apply_word_hits.rb mozcdic-ut-jawiki.txt

tar cjf mozcdic-ut-jawiki.txt.tar.bz2 mozcdic-ut-jawiki.txt
mv mozcdic-ut-jawiki.txt* ../
