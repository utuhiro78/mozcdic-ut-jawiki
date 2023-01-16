#! /usr/bin/env ruby
# coding: utf-8

# Author: UTUMI Hirosi (utuhiro78 at yahoo dot co dot jp)
# License: Apache License, Version 2.0

require 'parallel'
require 'bzip2/ffi'
require 'nkf'

# ==============================================================================
# Wikipediaの記事の例
# ==============================================================================

# Wikipediaの記事は「タイトル（読み）」を冒頭に書いているものが多い。
# これを使って表記と読みを取得する。

#    <title>生物学</title>
#    <ns>0</ns>
#    <id>57</id>
#    <revision>
#      <id>81180990</id>
#      <parentid>79962619</parentid>
#      <timestamp>2021-01-04T11:40:47Z</timestamp>
#      <contributor>
#        <username>MathXplore</username>
#        <id>1247297</id>
#      </contributor>
#      <minor />
#      <comment>/* 関連項目 */</comment>
#      <model>wikitext</model>
#      <format>text/x-wiki</format>
#      <text bytes="39506" xml:space="preserve">{{複数の問題
#| 出典の明記 = 2018年11月12日 (月) 08:46 (UTC)
#| 参照方法 = 2018年11月12日 (月) 08:46 (UTC)
#}}
#'''生物学'''（せいぶつがく、{{Lang-en-short|biology}}、

# ==============================================================================
# generate_jawiki_ut
# ==============================================================================

def generate_jawiki_ut

	# ==============================================================================
	# タイトルから表記を作る
	# ==============================================================================

	# タイトルを取得
	title = $article.split("</title>")[0]
	title = title.split("<title>")[1]

	# 記事を取得
	$article = $article.split(' xml:space="preserve">')[1]

	if $article == nil
		return
	end

	# タイトルの全角英数を半角に変換してUTF-8で出力
	# -m0 MIME の解読を一切しない
	# -Z1 全角空白を ASCII の空白に変換
	# -W 入力に UTF-8 を仮定する
	# -w UTF-8 を出力する(BOMなし)
	hyouki = NKF.nkf("-m0Z1 -W -w", title)

	# 表記を「 (」で切る
	# 田中瞳 (アナウンサー)
	hyouki = hyouki.split(' (')[0]

	# 表記が26文字以上の場合はスキップ。候補ウィンドウが大きくなりすぎる
	if hyouki[25] != nil ||
	# 内部用のページをスキップ
	hyouki.index("(曖昧さ回避)") != nil ||
	hyouki.index("Wikipedia:") != nil ||
	hyouki.index("ファイル:") != nil ||
	hyouki.index("Portal:") != nil ||
	hyouki.index("Help:") != nil ||
	hyouki.index("Template:") != nil ||
	hyouki.index("Category:") != nil ||
	hyouki.index("プロジェクト:") != nil ||
	# 表記にスペースがある場合はスキップ
	# 記事のスペースを削除してから「表記(読み」を検索するので、残してもマッチしない。
	hyouki.index(" ") != nil ||
	# 「、」がある場合はスキップ
	# 記事の「、」で読みを切るので、残してもマッチしない。
	hyouki.index("、") != nil
		return
	end

	# 読みにならない文字「 」「!?」などを削除したhyouki2を作る
	hyouki2 = hyouki.tr('\ \.\!\?\-\+\*\=\:\/・。×★☆', '')

	# hyouki2が1文字の場合はスキップ
	if hyouki2[1] == nil
		return
	end

	# hyouki2がひらがなとカタカナだけの場合は、読みをhyouki2から作る
	# さいたまスーパーアリーナ
	if hyouki2 == hyouki2.scan(/[ぁ-ゔァ-ヴー]/).join
		yomi = NKF.nkf("--hiragana -w -W", hyouki2)
		yomi = yomi.tr("ゐゑ", "いえ")

		# ファイルをロックして書き込む
		$dicfile.flock(File::LOCK_EX)
		$dicfile.puts yomi + "	" + $id_mozc + "	" + $id_mozc + "	6000	" + hyouki
		$dicfile.flock(File::LOCK_UN)
		return
	end

	# ==============================================================================
	# 記事の量を減らす
	# ==============================================================================

	lines = $article.gsub("}}'''", "}}\n'''").split("\n")

	# テンプレートを削除
	lines.length.times do |i|
		if lines[i][0] == "|" ||
		lines[i][0] == "*" ||
		lines[i][0] == "{" ||
		lines[i][0] == "}"
			lines[i] = nil
		end
	end

	# 記事を最大200行にする
	# 全部チェックすると時間がかかる。
	lines = lines.compact[0..199]

	# ==============================================================================
	# 記事から読みを作る
	# ==============================================================================

	lines.length.times do |i|
		s = lines[i]

		# 全角英数を半角に変換してUTF-8で出力
		s = NKF.nkf("-m0Z1 -W -w", s)

		# 「<ref 」から「</ref>」までを削除
		# '''皆藤 愛子'''<ref>一部のプロフィールが</ref>(かいとう あいこ、[[1984年]]
		# '''大倉 忠義'''（おおくら ただよし<ref name="oricon"></ref>、[[1985年]]
		if s.index("&lt;ref") != nil
			s = s.sub(/&lt;ref.*?&lt;\/ref&gt;/, "")
		end

		# スペースと「'"「」『』」を削除
		# '''皆藤 愛子'''(かいとう あいこ、[[1984年]]
		s = s.tr(" '\"「」『』", "")

		# 「表記(読み」を検索
		yomi = s.split(hyouki + "(")[1]

		if yomi == nil
			next
		end

		# 読みを「)」で切る
		# 結果が nil になって止まることがあるので、to_s で回避。
		yomi = yomi.split(")")[0].to_s

		# 読みを「[[」で切る
		# ないとうときひろ[[1963年]]
		yomi = yomi.split("[[")[0].to_s

		# 読みを「、」で切る
		# かいとうあいこ、[[1984年]]
		yomi = yomi.split("、")[0].to_s

		# 読みが2文字以下の場合はスキップ
		if yomi[2] == nil
			next
		end

		# 読みが「ー」で始まる場合はスキップ
		if yomi[0] == "ー" ||
		# 読みが全てカタカナの場合はスキップ
		# ミュージシャン一覧(グループ)
		yomi == yomi.scan(/[ァ-ヴー]/).join
			next
		end

		# 読みのカタカナをひらがなに変換
		yomi = NKF.nkf("--hiragana -w -W", yomi)
		yomi = yomi.tr("ゐゑ", "いえ")

		# 読みがひらがな以外を含む場合はスキップ
		if yomi != yomi.scan(/[ぁ-ゔー]/).join
			next
		end

		# 表記のHTML特殊文字を変換
		hyouki = hyouki.gsub('&amp;', '&')
		hyouki = hyouki.gsub('&quot;', '"')

		# ファイルをロックして書き込む
		$dicfile.flock(File::LOCK_EX)
		$dicfile.puts yomi + "	" + $id_mozc + "	" + $id_mozc + "	6000	" + hyouki
		$dicfile.flock(File::LOCK_UN)
		return
	end
end

# ==============================================================================
# main
# ==============================================================================

dicname = "mozcdic-ut-jawiki.txt"

# Mozc の一般名詞のID
$id_mozc = "1847"

`wget https://dumps.wikimedia.org/jawiki/latest/ -O jawiki-index.html`

file = File.new("jawiki-index.html", "r")
	jawiki_index = file.read
file.close

jawiki_date = jawiki_index.split('jawiki-latest-pages-articles.xml.bz2</a>               ')[1]
jawiki_index = ""
jawiki_date = jawiki_date.split(" ")[0]

`wget -N https://dumps.wikimedia.org/jawiki/latest/jawiki-latest-pages-articles.xml.bz2`

# Parallel のプロセス数を「物理コア数 - 1」にする
core_num = `grep cpu.cores /proc/cpuinfo`.chomp.split(": ")[-1].to_i - 1

$dicfile = File.new(dicname, "w")
jawiki_fragment = ""

reader = Bzip2::FFI::Reader.open('jawiki-latest-pages-articles.xml.bz2')

puts "Reading..."

while jawiki = reader.read(500000000)
	jawiki = jawiki.split("  </page>")
	jawiki[0] = jawiki_fragment + jawiki[0]

	# 記事の断片をキープ
	jawiki_fragment = jawiki[-1]

	puts "Writing..."

	Parallel.map(jawiki, in_processes: core_num) do |s|
		$article = s
		generate_jawiki_ut
	end

	puts "Reading..."
end

reader.close

$dicfile.close

file = File.new(dicname, "r")
		lines = file.read.split("\n")
file.close

# 重複する行を削除
lines = lines.uniq.sort

file = File.new(dicname, "w")
		file.puts lines
file.close
