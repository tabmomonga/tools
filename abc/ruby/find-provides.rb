#!/usr/bin/ruby
# by Hiromasa YOSHIMOTO <y@momonga-linux.org>

Version = "0.0.1"

$:.unshift(File.dirname($0))
require 'optparse'
require 'sqlite3'
require 'set'

OPTS = {}
OPTS[:verbose]=0
OPTS[:recursion]=1
opt = OptionParser.new
opt.on('-f', '--force_update') {|v| OPTS[:force_update] = v }
opt.on('-q', '--quite', 'suppress verbose msg.') {|v| OPTS[:verbose]=-1 }
opt.on('-v', '--verbose', 'verbose msg.') {|v| OPTS[:verbose]+=1 }
opt.parse!(ARGV)

db = SQLite3::Database.new("pkgs.db")

curr = ARGV
curr.map!{|v| v.chomp("/") }

curr.each do |name|
  sql  = "select name from specfile_tbl, package_tbl where package glob '#{name}' and id == owner "
  db.execute(sql) do |spec|
    print "#{spec}\n"
  end
  
  sql  = "select name from specfile_tbl, provide_tbl where provide glob '#{name}' and id == owner "
  db.execute(sql) do |spec|
    print "#{spec}\n"
  end
end

db.close()
