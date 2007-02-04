# specdb.rb
#
# by Hiromasa YOSHIMOTO

require 'sqlite3'
require 'rpm'

class SpecDB 
  TABLE_MAJOR_VERSION=1 # increase when the layout break compatibility
  TABLE_MINOR_VERSION=0 # increase when the regeneration of DB is needed
  TABLE_LAYOUT=<<ENDOFSQL
-- to build spec "owner" needs "require"-"version"-"release"
drop table if exists buildreq_tbl;
create table buildreq_tbl (
       owner integer not null,

       require text,
       version text default null,
       release text default null,
       epoch   text default null
);

-- spec "owner" generates  "package"-"version"-"release".?.rpm
drop table if exists package_tbl;
create table package_tbl (
       owner integer not null,

       package text primary key,
       version text default null,
       release text default null,
       epoch   text default null
);

-- "package" require "requires"-"version"-"requires"
drop table if exists require_tbl;
create table require_tbl (
       owner integer not null,
       package text,

       require text,
       version text default null,
       release text default null,
       epoch   text default null
);

-- "package" provides "provide"
drop table if exists provide_tbl;
create table provide_tbl (
       owner integer not null,
       package text,

       provide text
);

drop table if exists specfile_tbl;
create table specfile_tbl (
       id integer primary key autoincrement,
       name text unique not null,
       lastupdate integer
);

drop table if exists misc_tbl;
create table misc_tbl (
       major_version integer,
       minor_version integer,
       lastupdate integer
);
ENDOFSQL

  def open(database, opts = nil)
    @options = opts if opts

    @db = SQLite3::Database.new(database)

    needed = true
    begin
      r = @db.get_first_row("select major_version,minor_version from misc_tbl")
      STDERR.puts "database version: #{r[0]}.#{r[1]}" if (@options[:verbose]>1)
      if nil != r && 
          TABLE_MAJOR_VERSION == Integer(r[0]) &&
          TABLE_MINOR_VERSION <= Integer(r[1]) then
        needed = false
      end
    rescue SQLite3::SQLException
      #needed = true
    end 
    
    initialize_database if needed || @options[:force_update]
  end

  def close
    @db.close
  end

  def db
    return @db
  end

  def delete(name, opts = nil)
    opts = @options if nil==opts

    STDERR.puts "deleting  #{name}" if (opts[:verbose]>-1) 
    @db.transaction { |db|
      id = db.get_first_value("select id from specfile_tbl where name == '#{name}'")
      if nil!=id then
        delete_cache(db, id)
        db.execute("delete from specfile_tbl where id == #{id}")
      end
    }
  end
  
  def update(name, opts = nil)
    opts = @options if nil==opts

    filename="#{name}/#{name}.spec"
    timestamp = File.mtime(filename).to_i

    if !opts[:force_update] then
      sql = "select count(id) from specfile_tbl where name == '#{name}' and lastupdate>=#{timestamp}"
      if  @db.get_first_value(sql) == "1"  then
        STDERR.puts "skip #{name}" if (opts[:verbose]>0) 
        return 
      end
    end
    
    # RPM::Spec will crash when RPM.readrc() is not called.
    RPM.readrc('rpmrc')
    spec = RPM::Spec.open(filename)
    if spec.nil? then
      STDERR.puts "failed to parse #{filename}."
      exit 1
    end
    
    @db.transaction { |db|
      STDERR.puts "updating  #{name}" if (opts[:verbose]>-1) 

      # create spec entry
      db.execute("insert or ignore into specfile_tbl (name) values('#{name}')")
      id = db.get_first_value("select id from specfile_tbl where name == '#{name}'")
      
      # delete old datas
      delete_cache(db, id)
      
      # create new datas
      spec.buildrequires.each {|req|
        sql = "insert into buildreq_tbl (owner,require,version,release,epoch) values(#{id}, '#{req.name}', '#{req.version.v}', '#{req.version.r}', '#{req.version.e}')"
        db.execute(sql)
      }      

      spec.packages.each {|pkg|
        sql = "insert into package_tbl (owner,package,version,release,epoch) values(#{id}, '#{pkg.name}', '#{pkg.version.v}', '#{pkg.version.r}', '#{pkg.version.e}')"
        db.execute(sql)
        
        pkg.requires.each {|req|
          sql = "insert into require_tbl (owner,package,require,version,release,epoch) values(#{id}, '#{pkg.name}', '#{req.name}', '#{req.version.v}', '#{req.version.r}', '#{req.version.e}')"
          db.execute(sql)
        }
        
        pkg.provides.each {|prv|
          sql = "insert into provide_tbl (owner,package,provide) values(#{id}, '#{pkg.name}', '#{prv.name}')"
          db.execute(sql)
        }        
      }
      
      # update spec's timestamp
      db.execute("update specfile_tbl set lastupdate = #{timestamp} where name == '#{name}'")
    } # end of transaction

    # 
    # spec = nil
  end

  def initialize  
    @options = {}
    @options[:verbose] = 0
  end 
  
  private  
  def delete_cache(db, id)
    db.execute("delete from buildreq_tbl where owner == #{id}")
    db.execute("delete from package_tbl where owner == #{id}")
    db.execute("delete from require_tbl where owner == #{id}")
    db.execute("delete from provide_tbl where owner == #{id}")
  end

  private
  def initialize_database
    STDERR.puts "initializing database " if @options[:verbose] > -1
    @db.transaction { |db|
      db.execute_batch(TABLE_LAYOUT)
      db.execute("insert into misc_tbl values(#{TABLE_MAJOR_VERSION},#{TABLE_MINOR_VERSION},0)")
    }
  end

end  # end of class SpecDB
