#!/usr/bin/ruby -Ku
# -*- coding: utf-8 -*-

# get sha256sum via network, directly
# you can get local file's sha256sum, too

# Usage: rsha256sum.rb URI1(file1) URI2(file2) ...

require 'open-uri'
require 'digest/sha2'

if ARGV.size == 0
  puts "Usage: rsha256sum.rb URI1(file1) URI2(file2) ..."
end

while uri = ARGV.shift
	open(uri) { |f|
		sha256sum = Digest::SHA256.hexdigest(f.read)
		puts "#{sha256sum}  #{uri}"
	}
end
