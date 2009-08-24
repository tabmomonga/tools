#!/usr/bin/ruby19 -Ku
# -*- ruby-mode -*-

$:.unshift(File.dirname($0) + '/v2')

require 'optparse'
require 'environment'
require 'getoptlong'
require 'pathname'
load '../tools/v2/updatespecdb'

#specdb が OBSOLETES は処理してるので考える必要なし
#$ はいかんでしょ。

if Pathname.new(File.expand_path($PKGDIR)).realpath != Pathname.new(File.expand_path(Dir.getwd)).realpath
  puts "Run in pkgs/ dir."
  exit 1
end

opt = {}
ARGV.options {|o|
  o.on('-n', 'display Nonfree missing files, too') {|v| opt[:n] = true}
  o.on('-O', 'display Ohphan missing files, too') {|v| opt[:O] = true}
  o.on('-L', 'display Alter missing files, too') {|v| opt[:L] = true}
  o.on('-f', 'delete files without quitely') {|v| opt[:f] = true}
  o.parse!
}

#specdb から arch とれるように。
RPM.readrc("./rpmrc")
#ARCH=RPM[%{_target_cpu}]
ARCH=$ARCH

$DB = SpecDB.new
$Sources = {}
$Packages = {}

$DB.specs.each_value do |spec|
  nosource = false
  todir=$TOPDIR
  Dir.glob("#{spec.name}/TO.*").sort.each do |to|
    todir += "-#{File.basename(to)[3..-1]}"
    break
  end
  spec.sources.each do |source|
    if source.no?
      nosource = true
      ($Sources[todir]||={})[source.filename] = true
    end
  end
  STDERR.puts "warning: no package in #{spec.name}" unless spec.packages[0]
  next unless spec.packages[0]
  next if test(?e, "#{spec.name}/#{$NOTFILE}")
  if !nosource
#packages[0] はウソ。違う場合もある。
#specdb が弱い。
    ($Packages[todir]||={})["#{spec.name}-#{spec.packages[0].version}.src.rpm"] = true
  else
    ($Packages[todir]||={})["#{spec.name}-#{spec.packages[0].version}.nosrc.rpm"] = true
  end
  spec.packages.each do |pkg|
    if $STORE and pkg.arch then
      ($Packages[todir]||={})["#{pkg.name}-#{pkg.version}.#{pkg.arch}.rpm"] = true
    else
      arch = ARCH
      if spec.archs[0]
        arch = spec.archs[0]
      end
      ($Packages[todir]||={})["#{pkg.name}-#{pkg.version}.#{arch}.rpm"] = true
    end
  end
end

$Massatu = []
Dir.glob("#{$TOPDIR}*").each do |top|
  case top
  when "#{$TOPDIR}-Nonfree"
    next unless opt[:n]
  when "#{$TOPDIR}-Orphan"
    next unless opt[:O]
  when "#{$TOPDIR}-Alter"
    next unless opt[:L]
  end
  glob_str = if $STORE then
               "#{top}/#{$STORE}/*.rpm\0#{top}/SRPMS/*.rpm"
             else
               "#{top}/#{ARCH}/*.rpm\0#{top}/noarch/*.rpm\0#{top}/SRPMS/*.rpm"
             end
  Dir.glob(glob_str).each do |rpm|
    if !$Packages[top] || !$Packages[top][File.basename(rpm)]
      $Massatu << rpm
    else
      $Packages[top].delete(File.basename(rpm))
    end
  end
  Dir.glob("#{top}/SOURCES/*").each do |src|
    if !$Sources[top] || !$Sources[top][File.basename(src)]
      $Massatu << src
    end
  end
  ($Packages[top]||[]).sort.each do |k,v|
    if $STORE then
      if /src/ =~ k.split(/\./)[-2] then
        puts "#{top}/SRPMS/#{k} is missing"
      else
        puts "#{top}/#{$STORE}/#{k} is missing"
      end
    else
      dir = k.split(/\./)[-2]
      dir = 'SRPMS' if /src/ =~ dir
      puts "#{top}/#{dir}/#{k} is missing"
    end
  end
end

if $Massatu.length == 0
  exit
end

$Massatu.sort.each do |file|
  print "rm #{file}\n"
end

if !opt[:f]
  printf( "けすよ。 (y/N)> " )
  sAnswer = STDIN.gets().chomp().downcase()
  if( sAnswer != 'y' )
    printf( "じゃ、けさない。\n" )
    exit
  end
end

$Massatu.each do |file|
  File.unlink(file)
end
