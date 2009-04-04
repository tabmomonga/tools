#!/usr/bin/ruby19 -Ku
# -*- ruby-mode -*-

require 'getoptlong'

$:.unshift(File.dirname($0) + '/v2')

require 'environment'
load '../tools/v2/updatespecdb'

if File.expand_path($PKGDIR) != File.expand_path(Dir.getwd)
  puts "Run in pkgs/ dir."
  exit 1
end

class Dir
  def Dir.in_dir(dir)
    oldpwd = Dir.pwd
    Dir.chdir(dir)
    yield
    Dir.chdir(oldpwd)
  end
end # class Dir

db = SpecDB.new(true)

db.names.each do |name|
  spec = db.specs[name]
  nosources = spec.sources.select{|s| s.no?}
  topdir = $TOPDIR.dup

  Dir.in_dir(name) do
    if File.exist?('TO.Alter') then
      topdir += '-Alter'
    elsif File.exist?('TO.Nonfree') then
      topdir += '-Nonfree'
    end
    srpm = "#{topdir}/SRPMS/#{spec.name}-#{spec.packages[0].version}"
    if nosources.empty?
      srpm += ".src.rpm"
    else
      srpm += ".nosrc.rpm"
    end
    puts srpm
    if File.exist?(srpm)
      system("touch -r #{srpm} #{name}.spec")
      puts name
    end
  end
end

