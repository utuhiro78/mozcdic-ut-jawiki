#!/usr/bin/env python
# coding: utf-8

# Author: UTUMI Hirosi (utuhiro78 at yahoo dot co dot jp)
# License: Apache License, Version 2.0

import re
import sys

args = sys.argv[1:]

if not args:
	print("Usage: python script.py [FILE]")
	exit()

file_name = args[0]

# Mozc 形式の辞書を読み込む
# なかいまさひろ	1917	1917	6477	中居正広
with open(file_name, "r", encoding="utf-8") as file:
	lines = file.read().splitlines()

# 単語フィルタを読み込む
with open("unsuitable_words.txt", "r", encoding="utf-8") as file:
	unsuitable_words = file.read().splitlines()

for i, word in enumerate(unsuitable_words):
	# エントリが正規表現になっているときは正規表現を作る
	# /\Aバカ/
	if word.startswith("/"):
		unsuitable_words[i] = re.compile(word[1:-1])

with open(file_name, "w", encoding="utf-8") as dict_file:
	for i in range(len(lines)):
		entry = lines[i].split("\t")

		for word in unsuitable_words:
			if isinstance(word, str) and word in entry[4]:
				entry[4] = None
				break
			elif isinstance(word, re.Pattern) and word.search(entry[4]):
				entry[4] = None
				break

		if entry[4] is not None:
			dict_file.write("\t".join(entry) + "\n")
