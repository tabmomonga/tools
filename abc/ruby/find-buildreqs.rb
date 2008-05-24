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
opt.on('-r N', '--recursion=N', 'max depth') {|v| OPTS[:recursion] = Integer(v) }
opt.on('-f', '--force_update') {|v| OPTS[:force_update] = v }
opt.on('-q', '--quite', 'suppress verbose msg.') {|v| OPTS[:verbose]=-1 }
opt.on('-v', '--verbose', 'verbose msg.') {|v| OPTS[:verbose]+=1 }
opt.parse!(ARGV)

db = SQLite3::Database.new("pkgs.db")


deps = Set.new
curr = ARGV
curr.map!{|v| v.chomp("/") }

loop=0

while loop < OPTS[:recursion] 
  print "\n" if (loop>0)

  STDERR.puts "loop #{loop}" if (OPTS[:verbose]>1)

  loop += 1

  found = Set.new
  candidates = Set.new

  curr.each do |name|   
    sql = "select name from specfile_tbl where name glob '#{name}' "
    db.execute(sql) do |cand|
      candidates.add(cand)
    end
    sql = "select package from package_tbl where package glob '#{name}' "
    db.execute(sql) do |cand|
      candidates.add(cand)
    end
    sql = "select provide from provide_tbl where provide glob '#{name}' "
    db.execute(sql) do |cand|
      candidates.add(cand)
    end
  end

  candidates.each do |name|
    sql = "select name from specfile_tbl, buildreq_tbl where owner==id and require == '#{name}' "
    db.execute(sql) do |pkg|
      if !deps.include?(pkg) then
        found.add(pkg)
      end
    end
  end
  
  if found.empty? then
    break
  end


  found.each do |name|
    print "#{name}\n"
  end

  deps.merge(found)
  curr = found
end # end of while loop

db.close()
