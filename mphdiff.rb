#!/usr/bin/env ruby

unless ARGV.size == 2
  puts "Usage: #{$0} old.mph new.mph"
  puts "Compare two mph files."
  puts "Output format is the following:"
  puts "  -D ... : 'Depends' only exist in old.mph"
  puts "  +D ... : 'Depends' only exist in new.mph"
  puts "  -P ... : 'Provides' only exist in old.mph"
  puts "  +P ... : 'Provides' only exist in new.mph"
  exit
end

file1, file2 = ARGV

name = depends = provides = nil

def get_depends_and_provides(file)
  ret = {}
  name = depends = provides = nil
  File.read(file).each do |line|
    line.chomp!
    if /Package: (.+)/ =~ line
      name = $1
    elsif /Depends: (.+)/ =~ line
      depends = $1.split
      depends.delete("ld-linux.so.2")
      depends.delete("libgcc_s.so.1(GCC_3.0)")
      depends.delete_if{|i| /\Alibdl.so.\d+/ =~ i}
      depends.delete_if{|i| /\Alibc.so.\d+/ =~ i}
      depends.delete_if{|i| /\Alibm.so.\d+/ =~ i}
      depends.delete_if{|i| /\Alibpthread.so.\d+/ =~ i}
    elsif /Provides: (.+)/ =~ line
      provides = $1.split
      ret[name] = [depends, provides]
    end
  end
  ret
end

mph1 = get_depends_and_provides(file1)
mph2 = get_depends_and_provides(file2)

mph1.sort.each do |k,v|
  next if mph2[k].empty?
  del_dep = (v[0] || []) - (mph2[k][0]||[])
  add_dep = (mph2[k][0]||[]) - (v[0] || [])
  del_pro = (v[1] || []) - (mph2[k][1]||[])
  add_pro = (mph2[k][1]||[]) - (v[1] || [])
  next if del_dep.empty? && add_dep.empty? && del_pro.empty? && add_pro.empty?
  puts "#{k} :"
  puts "-D #{del_dep.inspect}" unless del_dep.empty?
  puts "+D #{add_dep.inspect}" unless add_dep.empty?
  puts "-P #{del_pro.inspect}" unless del_pro.empty?
  puts "+P #{add_pro.inspect}" unless add_pro.empty?
  puts
end
 
