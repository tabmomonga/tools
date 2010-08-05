# -*- coding: utf-8 -*-
# lib/database.rb
#
# by Hiromasa YOSHIMOTO <y@momonga-linux.org>

begin
  require 'rpm'
rescue LoadError
  abort "A package 'ruby-rpm' is not installed, abort"
end
begin
  begin; require 'rubygems'; rescue LoadError; end 
  require 'sqlite3'
rescue LoadError
  abort "A package 'rubygem-sqlite3-ruby' is not installed, abort"
end

module RPM
  class Dependency
    def conv
      relation = if le? then
                   '<='
                 elsif lt? then
                   '<'
                 elsif ge? then
                   '>='
                 elsif gt? then
                   '>'
                 elsif eq? then
                   '=='
                 else
                   nil
                 end

      if relation.nil?
        return "'#{name}'", "NULL", "NULL"
      else
        v  = version.e.nil? ? "" : "#{version.e}:" 
        v += "#{version.v}"
        v += "-#{version.r}" if version.r
        return "'#{name}'", "'#{relation}'", "'#{v}'"
      end
    end
  end
end # module RPM

# package の version を比較する
# なお op, ver2 が共に  nil の場合は true を返す
def compare_version(ver1, op, ver2)
  return true if op.nil? and ver2.nil? 
    
  v1 = RPM::Version.new(ver1)
  v2 = RPM::Version.new(ver2)
  eq = (v1 <=> v2)
  case op
  when '>'
    eq > 0
  when '>='
    eq >= 0
  when '<'
    eq < 0
  when '<='
    eq <= 0
  when '=='
    eq == 0
  when '='
    eq == 0
  else
    abort("unknown op,#{op}")
  end
end

class DBBase
  def open_database(database, layout, major, minor, opts = nil)
    @options = opts if opts

    @db = SQLite3::Database.new(database)

    needed = true
    begin
      r = @db.get_first_row("select major_version,minor_version from misc_tbl")
      STDERR.puts "database version: #{r[0]}.#{r[1]}" if (@options[:verbose]>1)
      if nil != r && 
          major == Integer(r[0]) &&
          minor <= Integer(r[1]) then
        needed = false
      end
    rescue SQLite3::SQLException
      #needed = true
    end 
    
    initialize_database(layout, major, minor) if needed || @options[:force_update]
  end

  def close
    @db.close
  end

  def db
    return @db
  end

  def initialize  
    @options = {}
    @options[:verbose] = 0
  end 

  private
  def initialize_database(layout, major, minor)
    STDERR.puts "initializing database " if @options[:verbose] > -1
    @db.transaction { |db|
      db.execute_batch(layout)
      db.execute("insert into misc_tbl(major_version, minor_version, lastupdate) values(#{major},#{minor},0)")
    }
  end

end  # end of class DBBase

