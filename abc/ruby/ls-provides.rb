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

reqs = Set.new
curr = ARGV 
curr.map!{|v| v.chomp("/") }

found = Set.new
candidates = Set.new

curr.each do |name|    
  sql = "select id from specfile_tbl where name glob '#{name}' "
  db.execute(sql) do |id|
    candidates.add(id)
  end	
  sql = "select owner from package_tbl where package glob '#{name}' "
  db.execute(sql) do |owner|
    candidates.add(owner)
  end
end

candidates.each do |id|
  sql = "select package from package_tbl where owner==#{id}"
  db.execute(sql) do |pkg|
    if !reqs.include?(pkg) then
      found.add(pkg)
    end
  end
  sql = "select provide from provide_tbl where owner==#{id}"
  db.execute(sql) do |pkg|
    if !reqs.include?(pkg) then
      found.add(pkg)
    end
  end
end

found.each do |name|
  print "#{name}\n"
end


db.close()
