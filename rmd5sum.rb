#!/usr/bin/env ruby

# get md5sum via network, directly
# you can get local file's md5sum, too

# Usage: rmd5sum.rb URI1(file1) URI2(file2) ...

require 'open-uri'
require 'digest/md5'

if ARGV.size == 0
  puts "Usage: rmd5sum.rb URI1(file1) URI2(file2) ..."
end

while uri = ARGV.shift
	open(uri) { |f|
		md5sum = Digest::MD5.hexdigest(f.read)
		puts "#{md5sum}  #{uri}"
	}
end
