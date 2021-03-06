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
      # !!FIXME!!
      # now we can not handle non-ascii charcter.
      # note; for example, ipa-ex-gothic-fonts has a
      # UTF string in its provides field.
      n = name.encode(Encoding::ASCII, :replace => '?')

      if relation.nil?
        return n, 'NULL', 'NULL'
      else
        v  = version.e.nil? ? '' : "#{version.e}:" 
        v += version.v
        v += "-#{version.r}" if version.r
        return n, relation, v.encode(Encoding::ASCII, :replace => '?')
      end
    end
  end
end # module RPM

module SQLite3
  class Statement
    def get_first_value( *bind_vars )
      execute!( *bind_vars ) { |row| return row[0] }
      nil
    end
  end
end

# Compares package version strings
#
def compare_version(ver1, op, ver2)
  return true if op == 'NULL'
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

    sqlite3_option = {}
    if @options[:readonly] then
      sqlite3_option[:readonly] = true;
    end
 
    @db = SQLite3::Database.new(database, sqlite3_option)

    needed = true
    begin
      r = @db.get_first_row("select major_version,minor_version from misc_tbl")
      STDERR.puts "database version: #{r[0]}.#{r[1]}" if (@options[:verbose]>1)
      if nil != r && 
          major == Integer(r[0]) &&
          minor <= Integer(r[1]) then
        needed = false
      end
    rescue SQLite3::BusyException
      abort "database [#{database}] is locked, abort." 
    rescue SQLite3::SQLException
      #needed = true
    end 
    
    @db.execute('PRAGMA temp_store = 2')
    @db.execute('PRAGMA journal_mode = MEMORY')
    @db.execute('PRAGMA synchronous =  0')
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
      db.execute('insert into misc_tbl(major_version, minor_version, lastupdate) values(?,?,0)',
                 [major, minor])
    }
  end

end  # end of class DBBase

