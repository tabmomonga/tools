#!/usr/bin/ruby -Ku
# -*- coding: utf-8 -*-

obso_dirs = []
obso_files = []

Dir.entries('.').each { |d|
  if FileTest.directory?(d) \
    && d != '.' \
    && d != '..' \
    && d != '.svn' \
    && !FileTest.exist?(d + '/.svn') \
    && !FileTest.exist?(d + '/' + d + '.spec') \
  then
    obso_dirs << d
    obso_files << d
    Dir.entries(d).each { |f|
      obso_files << d + '/' + f if f != '.' && f != '..'
    }
  end
}

exit 0 if obso_dirs.empty?

obso_files.sort.each { |f|
  print "#{f}\n"
}

print "けすよ。(y/N)> "
if STDIN.gets().chomp().downcase() != 'y' then
  print "じゃ、けさない。\n"
  exit 0
end

obso_dirs.each { |d|
  system "rm -rf #{d}"
}
