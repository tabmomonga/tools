#!/usr/bin/ruby
#
# by Hiromasa YOSHIMOTO <y@momonga-linux.org>

Version = "0.0.1"

$:.unshift(File.dirname($0))
require 'specdb'
require 'optparse'

OPTS = {}
OPTS[:verbose]=0
opt = OptionParser.new
opt.on('-f', '--force_update') {|v| OPTS[:force_update] = v }
opt.on('-q', '--quite', 'suppress verbose msg.') {|v| OPTS[:verbose]=-1 }
opt.on('-v', '--verbose', 'verbose msg.') {|v| OPTS[:verbose]+=1 }
opt.parse!(ARGV)


d = SpecDB.new
d.open("pkgs.db")

Dir.glob('./*').select do |dir|
  name = File.basename(dir)	
  if !File.exist?("#{name}/#{name}.spec") or
      File.exist?("#{name}/OBSOLETE") or
      File.exist?("#{name}/.SKIP") or
      File.exist?("#{name}/SKIP") then
    d.delete(name)
  else
    d.update(name, OPTS)
  end
end

d.close


