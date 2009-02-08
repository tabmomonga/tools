# lib/database.rb
#
# by Hiromasa YOSHIMOTO <y@momonga-linux.org>

require 'sqlite3'

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
