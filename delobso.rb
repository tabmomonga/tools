#! /usr/bin/env ruby

$:.unshift(File.dirname($0))
require 'environment'
load 'updatespecdb'

#specdb が OBSOLETES は処理してるので考える必要なし
#$ はいかんでしょ。

if File.expand_path($PKGDIR) != File.expand_path(Dir.getwd)
  puts "Run in pkgs/ dir."
  exit 1
end

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
  p spec unless spec.packages[0]
  next unless spec.packages[0]
  if !nosource
#packages[0] はウソ。違う場合もある。
#specdb が弱い。
    ($Packages[todir]||={})["#{spec.name}-#{spec.packages[0].version}.src.rpm"] = true
  else
    ($Packages[todir]||={})["#{spec.name}-#{spec.packages[0].version}.nosrc.rpm"] = true
  end
  spec.packages.each do |pkg|
    arch = ARCH
    if spec.archs[0]
      arch = spec.archs[0]
    end
    ($Packages[todir]||={})["#{pkg.name}-#{pkg.version}.#{arch}.rpm"] = true
  end
end

$Massatu = []
Dir.glob("#{$TOPDIR}*").each do |top|
  Dir.glob("#{top}/#{ARCH}/*.rpm\0#{top}/noarch/*.rpm\0#{top}/SRPMS/*.rpm").each do |rpm|
    next if rpm.split('/')[-2] == 'SOURCES'
    if !$Packages[top] || !$Packages[top][File.basename(rpm)]
      $Massatu << rpm
    end
  end
  Dir.glob("#{top}/SOURCES/*").each do |src|
    if !$Sources[top] || !$Sources[top][File.basename(src)]
      $Massatu << src
    end
  end
end

if $Massatu.length == 0
  exit
end

if ARGV[0] != "-f"
  $Massatu.sort.each do |file|
    print "rm #{file}\n"
  end

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
