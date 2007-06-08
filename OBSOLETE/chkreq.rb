#!/usr/bin/env ruby

if ARGV.length == 0
  print "#{$0} hoge-x.z-zk.arch.rpm\n"
  exit
end

req_list = `rpm -qpR #{ARGV.shift}`.split(/\n/)

i = 0
j = 0
$lib_list = []
$pkg_list = []
$temp_list = []
req_list.each do |line|
  if /(.*)so(.*)/ =~ line
    if /\(/ !~ line
      temp_list = `locate #{line}`.split(/\n/)
      temp_list.each do |lib|
	if File.ftype(lib) == "link"
	  $lib_list[i] = `locate #{File.readlink(lib)}`.chop!
	  if /(.*)\n(.*)/ =~ $lib_list[i]
	    $lib_list[i] = $2
	  end
	else
	  $lib_list[i] = lib
	end
#	print $lib_list[i], "\n"
	i += 1
      end
    end
  elsif /\// =~ line
    $lib_list[i] = line.chop + "\n"
    i += 1
  elsif /[<>=]/ =~ line
    $pkg_list[j] = line.split[0] + "\n"
    j += 1
  else
    $pkg_list[j] = line.chop + "\n"
    j += 1
  end
end
$lib_list.sort!
$lib_list.uniq!
$pkg_list.sort!
$pkg_list.uniq!

$lib_list.each do |lib|
  $pkg_list[j] = `rpm -qf --qf '%{NAME}\n' #{lib}`
#  print $pkg_list[j]
  j += 1
end
$pkg_list.sort!
$pkg_list.uniq!

print $pkg_list
