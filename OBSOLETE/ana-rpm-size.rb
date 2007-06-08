#!/usr/bin/env ruby
# To get how much disk a rpm package is consuming
# Usage: rpm -qai | ruby ana-rpm-size.rb > result
packages = []
while line = gets
  if line =~ /^Name\s+:\s*([-\w]+)/
    name = $1
  elsif line =~ /^Size\s+:\s*(\w+)/
    size = $1.to_i
    packages << [name,size]
  end
end
packages.sort!{|a, b| b[1] <=> a[1]}

packages.each do |p|
  printf "%20s %10dK\n", p[0], p[1]/1000
end
 
