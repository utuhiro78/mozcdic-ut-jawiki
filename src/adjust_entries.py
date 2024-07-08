#!/usr/bin/env python
# coding: utf-8

# Author: UTUMI Hirosi (utuhiro78 at yahoo dot co dot jp)
# License: Apache License, Version 2.0

import jaconv
import re
import sys
from unicodedata import normalize

targetfiles = sys.argv[1:]

if not targetfiles:
	print("Usage: python script.py [FILE]")
	sys.exit()

filename = targetfiles[0]

with open(filename, "r", encoding="utf-8") as file:
	lines = file.read().splitlines()

l2 = []

for i in range(len(lines)):
	s = lines[i].split("\t")
	yomi = s[0]
	hyouki = s[4]

	# 表記の全角英数を半角に変換
	hyouki = normalize("NFKC", hyouki)

	# 表記の「~」を「〜」に置き換える
	hyouki = hyouki.replace("~", "〜")

	# 表記の最初が空白の場合は取る
	if hyouki.startswith(" "):
		hyouki = hyouki[1:]

	# 表記の全角カンマを半角に変換
	hyouki = hyouki.replace("，", ", ")

	# 表記の最後が空白の場合は取る（「，」が「, 」になっている）
	if hyouki.endswith(" "):
		hyouki = hyouki[:-1]

	# 読みにならない文字「 !?」などを削除したhyouki2を作る
	hyouki2 = hyouki.translate(str.maketrans('', '', ' .!?-+*=:/・。×★☆'))

	# hyouki2がひらがなとカタカナだけの場合は、読みをhyouki2から作る
	if hyouki2 == ''.join(re.findall('[ぁ-ゔァ-ヴー]', hyouki2)):
		yomi = jaconv.kata2hira(hyouki2)
		yomi = yomi.translate(str.maketrans('ゐゑ', 'いえ'))

	# 読みが2文字以下の場合はスキップ
	# hyouki2が1文字の場合はスキップ
	# hyoukiが26文字以上の場合はスキップ
	# 読みの文字数がhyouki2の4倍を超える場合はスキップ
	# （さくらざかふぉーてぃーしっくす[15文字] 櫻坂46[4文字]」までは残す。）
	# hyouki2の文字数*3が読みのバイト数より小さい場合はスキップ
	# （「あいてぃー[5文字] ITエンジニア[17bytes]」をスキップ。）
	# （「すのーまん[5文字] SNOWMAN[7bytes]」は残す。）
	# 読みがひらがな以外を含む場合はスキップ
	# hyoukiがコードポイントを含む場合はスキップ
	if len(yomi) < 3 or \
	len(hyouki2) < 2 or \
	len(hyouki) > 25 or \
	len(yomi) > len(hyouki2) * 4 or \
	len(yomi) * 3 < len(hyouki2.encode()) or \
	yomi != ''.join(re.findall('[ぁ-ゔー]', yomi)) or \
	'\\u' in hyouki:
		continue

	# hyouki2の数字をつなげると101以上になる場合はスキップ
	# （「国道120号」「3月26日」はスキップ。「100円ショップ」は残す。）
	n = re.sub(r"\D", "", hyouki2)

	if n != "" and int(n) > 100:
		continue

	l2.append(yomi + "\t" + "\t".join(s[1:4]) + "\t" + hyouki)

lines = l2
l2 = []

with open(filename, "w", encoding="utf-8") as dicfile:
	dicfile.write("\n".join(lines))
