#!/usr/bin/env python
# coding: utf-8

# Author: UTUMI Hirosi (utuhiro78 at yahoo dot co dot jp)
# License: Apache License, Version 2.0

import bz2
import fcntl
import html
import jaconv
import re
import subprocess
import urllib.request
import unicodedata
import subprocess
from multiprocessing import Pool, cpu_count

# ==============================================================================
# Wikipediaの記事の例
# ==============================================================================

# Wikipediaの記事は「表記（読み）」を冒頭に書いているものが多い。
# これを使って表記と読みを取得する。

#  xml:space="preserve">
# <title>あいの里公園駅</title>
# '''あいの里公園駅'''（あいのさとこうえんえき）は、

# ==============================================================================
# generate_jawiki_ut
# ==============================================================================

def generate_jawiki_ut(article):
	global dicfile
	global id_mozc

	# ==============================================================================
	# タイトルから表記を作る
	# ==============================================================================

	# タイトルを取得
	title = article.split("</title>")[0]
	title = title.split("<title>")[1]

	# 記事を取得
	article = article.split(' xml:space="preserve">')

	if len(article) < 2:
		return

	article = article[1]

	# 全角英数を半角に変換
	hyouki = unicodedata.normalize('NFKC', title)

	# 表記を「 (」で切る
	# 田中瞳 (アナウンサー)
	hyouki = hyouki.split(' (')[0]

	# 表記が26文字以上の場合はスキップ。候補ウィンドウが大きくなりすぎる
	# 内部用のページをスキップ
	# 表記にスペースがある場合はスキップ
	# （記事のスペースを削除してから「表記(読み」を検索するので、残してもマッチしない）
	if len(hyouki) > 25 or \
	"(曖昧さ回避)" in hyouki or \
	"Wikipedia:" in hyouki or \
	"ファイル:" in hyouki or \
	"Portal:" in hyouki or \
	"Help:" in hyouki or \
	"Template:" in hyouki or \
	"Category:" in hyouki or \
	"プロジェクト:" in hyouki or \
	" " in hyouki:
		return

	# 読みにならない文字「!?」などを削除したhyouki2を作る
	hyouki2 = hyouki.translate(str.maketrans('', '', '.!?-+*=:/・。×★☆'))

	# hyouki2が1文字の場合はスキップ
	if len(hyouki2) < 2:
		return

	# hyouki2がひらがなとカタカナだけの場合は、読みをhyouki2から作る
	# さいたまスーパーアリーナ
	if hyouki2 == ''.join(re.findall('[ぁ-ゔァ-ヴー]', hyouki2)):
		yomi = jaconv.kata2hira(hyouki2)
		yomi = yomi.translate(str.maketrans('ゐゑ', 'いえ'))

		entry = [yomi, id_mozc, id_mozc, "8000", hyouki]

		with open(dicname, "a", encoding="utf-8") as dicfile:
			fcntl.flock(dicfile, fcntl.LOCK_EX)
			dicfile.write("\t".join(entry))
			dicfile.write("\n")
			fcntl.flock(dicfile, fcntl.LOCK_UN)
		return

	# ==============================================================================
	# 記事の量を減らす
	# ==============================================================================

	# テンプレート末尾と記事本文の間に改行を入れる
	lines = article.replace("}}'''", "}}\n'''")
	lines = lines.splitlines()

	entry = []
	p = 0

	for i in range(len(lines)):
		# テンプレートを削除
		# 収録語は「'''盛夏'''（せいか）」が最小なので、12文字以下の行はスキップ
		if len(lines[i]) < 13 or \
		lines[i][0] == "{" or \
		lines[i][0] == "}" or \
		lines[i][0] == "|" or \
		lines[i][0] == "*":
			continue

		entry.append(lines[i])
		p = p + 1

		# 記事の量を減らす
		if p > 99:
			break

	lines = entry
	entry = ""

	# ==============================================================================
	# 記事から読みを作る
	# ==============================================================================

	for i in range(len(lines)):
		entry = lines[i]

		# 全角英数を半角に変換
		entry = unicodedata.normalize('NFKC', entry)

		# HTML特殊文字を変換
		entry = html.unescape(entry)

		# 「{{」から「}}」までを削除
		# '''皆藤 愛子'''{{efn2|一部のプロフィールが「皆'''籐'''（たけかんむり）」と
		# なっているが、「皆'''藤'''（くさかんむり）」が正しい。}}（かいとう あいこ、
		# [[1984年]][[1月25日]] - ）は、
		if "{{" in entry:
			entry = re.sub(r'{{.*?}}', '', entry)

		# 「<ref」から「</ref>」までを削除
		# '''井上 陽水'''（いのうえ ようすい<ref name="FMPJ">{{Cite web|和書|title=
		# アーティスト・アーカイヴ 井上陽水 {{small|イノウエヨウスイ}}|url=
		# https://www.kiokunokiroku.jp/artistarchives|work=記憶の記録 LIBRARY|
		# publisher=[[日本音楽制作者連盟]]|accessdate=2023-06-21}}</ref>、[[1948年]]
		entry = re.sub(r'<ref.*?<\/ref>', '', entry)

		# 「<ref name="example" />」を削除
		entry = re.sub(r'<ref\ name.*?\/>', '', entry)

		# スペースと「'"「」『』」を削除
		# '''皆藤 愛子'''(かいとう あいこ、[[1984年]]
		entry = entry.translate(str.maketrans('', '', ' "\'「」『』'))

		# 「表記(読み」から読みを取得
		if hyouki + "(" in entry:
			yomi = entry.split(hyouki + "(")[1]
		else:
			continue

		# 読みを「)」で切る
		yomi = yomi.split(")")[0]

		# 読みを「[[」で切る
		# ないとうときひろ[[1963年]]
		yomi = yomi.split("[[")[0]

		# 読みを「、」で切る
		# かいとうあいこ、[[1984年]]
		yomi = yomi.split("、")[0]

		# 読みを「/」で切る
		# ひみこ/ひめこ
		yomi = yomi.split("/")[0]

		# 読みが2文字以下の場合はスキップ
		if len(yomi) < 3:
			continue

		# 読みが「ー」で始まる場合はスキップ
		if yomi[0] == "ー" or \
				yomi == ''.join(re.findall('[ァ-ヴー]', yomi)):
			continue

		# 読みのカタカナをひらがなに変換
		yomi = jaconv.kata2hira(yomi)
		yomi = yomi.translate(str.maketrans('ゐゑ', 'いえ'))

		# 読みがひらがな以外を含む場合はスキップ
		if yomi != ''.join(re.findall('[ぁ-ゔー]', yomi)):
			continue

		entry = [yomi, id_mozc, id_mozc, "8000", hyouki]

		with open(dicname, "a", encoding="utf-8") as dicfile:
			fcntl.flock(dicfile, fcntl.LOCK_EX)
			dicfile.write("\t".join(entry))
			dicfile.write("\n")
			fcntl.flock(dicfile, fcntl.LOCK_UN)
		return

# ==============================================================================
# main
# ==============================================================================

dicname = "mozcdic-ut-jawiki.txt"

# Mozc の一般名詞のID
url = "https://raw.githubusercontent.com/google/mozc/master/src/data/dictionary_oss/id.def"
with urllib.request.urlopen(url) as response:
	id_mozc = response.read().decode()
	id_mozc = id_mozc.split(" 名詞,一般,")[0].split("\n")[-1]

#subprocess.run(["wget", "-N", "https://dumps.wikimedia.org/jawiki/latest/jawiki-latest-pages-articles-multistream.xml.bz2"])

with open(dicname, "w", encoding="utf-8") as dicfile:
	dicfile.write("")

jawiki_fragment = ""
cache_size = 200 * 1024 * 1024
core_num = cpu_count()

with bz2.open("jawiki-latest-pages-articles-multistream.xml.bz2", "rt", encoding="utf-8") as reader:
	while True:
		jawiki = reader.read(cache_size)

		if jawiki == "":
			break

		jawiki = jawiki.split("  </page>")
		jawiki[0] = jawiki_fragment + jawiki[0]

		# 記事の断片を別名で保存
		jawiki_fragment = jawiki[-1]

		# 記事の断片を削除
		jawiki = jawiki[0:-1]

		with Pool(processes=core_num) as pool:
			pool.map(generate_jawiki_ut, jawiki)
		pool.join()

with open(dicname, "r", encoding="utf-8") as file:
	lines = file.read().splitlines()

# 重複する行を削除
lines = sorted(list(set(lines)))

with open(dicname, "w", encoding="utf-8") as file:
	file.write("\n".join(lines))
