#!/usr/bin/ruby19 -Ku
# -*- ruby-mode -*-

require 'rpm'

$:.unshift(File.dirname($0) + '/v2')

require 'environment'
require 'getoptlong'

if ARGV[0] == '-a'
  glob_pattern = "#{$TOPDIR}*"
else
  glob_pattern = $TOPDIR
end

files = Hash.new{|i,k| i[k]=[]}

ARCH=$ARCH
Dir.glob(glob_pattern).each do |top|
  glob_str = if $STORE then
               "#{top}/#{$STORE}/*.rpm"
             else
               "#{top}/#{ARCH}/*.rpm\0#{top}/noarch/*.rpm"
             end
  Dir.glob(glob_str).each do |rpm|
    begin
      pkg = RPM::Package.open(rpm)
      pkg.files.each do |file|
        files[file.to_s] << pkg.name
      end
    rescue RuntimeError
      $stderr.puts "error in reading #{rpm}."
      $stderr.puts "#$! (#{$!.class})"
      $stderr.puts $@.join( "\n" )
    end
  end
end

files.to_a.sort.each do |file, pkgs|
  next if pkgs.size == 1
  puts file
  puts '  ' + pkgs.sort.join(', ')
end
