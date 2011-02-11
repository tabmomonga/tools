#!/usr/bin/ruby

begin
  require 'rpm'
rescue LoadError
  abort "A package 'ruby-rpm' is not installed, abort"
end

# RPM::Spec will crash when RPM.readrc() is not called.
RPM.readrc('/usr/lib/rpm/momonga/rpmrc:./rpmrc:./dot.rpmrc')

filename=ARGV[0]
spec = RPM::Spec.open(filename)
if spec.nil? then
  STDERR.puts "failed to parse, ignoring #{filename}."
  abort
end

puts spec.packages[0].version.v
