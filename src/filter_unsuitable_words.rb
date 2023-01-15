#! /usr/bin/env ruby
# coding: utf-8

# Author: UTUMI Hirosi (utuhiro78 at yahoo dot co dot jp)
# License: APACHE LICENSE, VERSION 2.0

require 'nkf'

targetfiles = ARGV

if ARGV == []
	puts "Usage: ruby script.rb [FILE]"
	exit
end

filename = ARGV[0]
dicname = filename

# Mozc形式の辞書を読み込む
# なかいまさひろ	1917	1917	6477	中居正広
file = File.new(filename, "r")
	lines = file.read.split("\n")
file.close

# 単語フィルタを読み込む
file = File.new("unsuitable_words.txt", "r")
	filter = file.read.split("\n")
file.close

filter.length.times do |i|
	# エントリが正規表現になっているときは正規表現を作る
	# /\Aバカ/
	if filter[i].index("/") == 0
		filter[i] = /#{filter[i][1..-2]}/
	end
end

dicfile = File.new(dicname, "w")

lines.length.times do |i|
	s = lines[i].split("	")

	filter.length.times do |c|
		if s[4].index(filter[c]) != nil
			s[4] = nil
			break
		end
	end

	if s[4] == nil
		next
	end

	dicfile.puts s.join("	")
end

dicfile.close
