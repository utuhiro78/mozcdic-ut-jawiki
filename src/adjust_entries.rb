#! /usr/bin/env ruby
# coding: utf-8

# Author: UTUMI Hirosi (utuhiro78 at yahoo dot co dot jp)
# License: Apache License, Version 2.0

require 'nkf'

targetfiles = ARGV

if ARGV == []
	puts "Usage: ruby script.rb [FILE]"
	exit
end

filename = ARGV[0]
dicname = filename

file = File.new(filename, "r")
	lines = file.read.split("\n")
file.close

l2 = []
p = 0

lines.length.times do |i|
	s = lines[i].split("	")
	yomi = s[0]
	hyouki = s[4]

	# 表記の全角英数を半角に変換
	hyouki = NKF.nkf("-m0Z1 -W -w", hyouki)

	# 表記の「~」を「〜」に置き換える
	# jawiki-latest-all-titles の表記に合わせる。
	hyouki = hyouki.gsub("~", "〜")

	# 表記の最初が空白の場合は取る
	if hyouki[0] == " "
		hyouki = hyouki[1..-1]
	end

	# 表記の全角カンマを半角に変換
	hyouki = hyouki.gsub("，", ", ")

	# 表記の最後が空白の場合は取る（「，」が「, 」になっている）
	if hyouki[-1] == " "
		hyouki = hyouki[0..-2]
	end

	# 読みにならない文字を削除したhyouki2を作る
	hyouki2 = hyouki.tr(' !?=:・。★☆', '')

	# hyouki2がひらがなとカタカナだけの場合は、読みをhyouki2から作る
	# さいたまスーパーアリーナ
	if hyouki2 == hyouki2.scan(/[ぁ-ゔァ-ヴー]/).join
		yomi = NKF.nkf("--hiragana -w -W", hyouki2)
		yomi = yomi.tr("ゐゑ", "いえ")
	end

	# 読みが2文字以下の場合はスキップ
	if yomi[2] == nil ||
	# hyouki2が1文字の場合はスキップ
	hyouki2[1] == nil ||
	# hyoukiが26文字以上の場合はスキップ
	hyouki[25] != nil ||
	# 読みの文字数がhyouki2の4倍を超える場合はスキップ
	# けやきざかふぉーてぃーしっくす（15文字） 欅坂46（4文字）
	yomi.length > hyouki2.length * 4 ||
	# hyouki2の文字数が読みの文字数より多い場合はスキップ
	# 英数字表記が削除されるのを防ぐため、hyouki2の文字数は (bytesize / 3) とする。
	yomi.length < hyouki2.bytesize / 3 ||
	# 読みがひらがな以外を含む場合はスキップ
	yomi != yomi.scan(/[ぁ-ゔー]/).join ||
	# hyoukiがコードポイントを含む場合はスキップ
	# デコードする場合は次のように行う
	# hyouki = hyouki.gsub(/\\u([\da-fA-F]{4})/){[$1.hex].pack("U")}
	hyouki.index("\\u") != nil ||
	# hyouki2の数字が101以上の場合はスキップ（「100円ショップ」は残す）
	# 国道120号, 3月26日
	hyouki2.scan(/\d/).join.to_i > 100
		next
	end

	l2[p] = yomi + "	" + s[1..3].join("	") + "	" + hyouki
	p = p + 1
end

lines = l2
l2 = []

dicfile = File.new(dicname, "w")
	dicfile.puts lines
dicfile.close
