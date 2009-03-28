# lib/logdb.rb
#
# by Hiromasa YOSHIMOTO <y@momonga-linux.org>

require 'lib/database.rb'

class LogDB < DBBase

  TABLE_MAJOR_VERSION = 0 # increase when the layout breaks compatibility
  TABLE_MINOR_VERSION = 0 # increase when we have to rebuild the DB
  TABLE_LAYOUT=<<ENDOFSQL
drop table if exists status_tbl;
create table status_tbl (
       specname text not null,
       status integer not null,
       revision integer not null,
       type integer not null,
       flag integer default 0,
       lastupdate integer not null
);
drop table if exists misc_tbl;
create table misc_tbl (
       major_version integer,
       minor_version integer,
       lastupdate integer,
       lastupload integer
);
ENDOFSQL

  def open(database, opts = nil) 
    open_database(database, 
                  TABLE_LAYOUT,
                  TABLE_MAJOR_VERSION, 
                  TABLE_MINOR_VERSION,  opts)
  end

  def check(opts = nil)
    opts = @options if nil==opts
  end

  def delete(specname, opts = nil)
    opts = @options if nil==opts

    STDERR.puts "deleting entry for #{specname}" if (opts[:verbose]>1) 
    @db.transaction { |db|
    }
  end
  
  def update(specname, opts = nil)
  end

  private  
  def delete_cached(db, id)
    db.execute("delete from capability_tbl where owner == #{id}")
    db.execute("delete from dependency_tbl where owner == #{id}")
  end

end  # end of class PkgDB
