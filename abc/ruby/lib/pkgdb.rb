# lib/pkgdb.rb
#
# by Hiromasa YOSHIMOTO <y@momonga-linux.org>

require 'lib/database.rb'

class PkgDB < DBBase

  TABLE_MAJOR_VERSION=4 # increase when the layout breaks compatibility
  TABLE_MINOR_VERSION=0 # increase when rebuild DB is required
  TABLE_LAYOUT=<<ENDOFSQL

-- pkgfile's capabilities (=provides) info
drop table if exists capability_tbl;
create table capability_tbl (
       owner integer not null,

       capability text not null,
       comparison text default null,
       version text default null
);

-- pkgfile's dependencies (=requires) info
drop table if exists dependency_tbl;
create table dependency_tbl (
       owner integer not null,

       capability text not null,
       comparison text default null,
       version text default null
);

drop table if exists obsolete_tbl;
create table obsolete_tbl (
       owner integer not null,

       capability text not null,
       comparison text default null,
       version text default null
);

drop table if exists conflict_tbl;
create table conflict_tbl (
       owner integer not null,

       capability text not null,
       comparison text default null,
       version text default null
);

drop table if exists pkg_tbl;
create table pkg_tbl (
       id integer primary key autoincrement,
       pkgfile text,
       pkgname text unique,
       buildtime integer,
       lastupdate integer
);

drop table if exists file_tbl;
create table file_tbl (
       owner integer not null,
       path text
);

drop table if exists misc_tbl;
create table misc_tbl (
       major_version    integer,
       minor_version    integer,
       lastupdate       integer,  -- unixtime when pkg_tbl checked
       last_file_update intege    -- unixtime when file_tbl checked
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
    sql = "select pkgfile,max(id) as id from pkg_tbl group by pkgfile having count(*) > 1"
    @db.execute(sql) do |pkgfile,id|
      STDERR.puts "warrning: #{pkgfile} has broken entries, fixing them..."
      sql = "delete from pkg_tbl where pkgfile == '#{pkgfile}' and id != #{id}"
      @db.execute(sql)
    end
  end

  def delete(pkgfile, opts = nil)
    list = []
    list.push(filename)
    delete_list(list, opts)
  end

  def delete_list(list, opts = nil)
    opts = @options if nil==opts

    @db.transaction { |db|
      list.each {|pkgfile|
        delete_one(db, pkgfile, opts)
      }
    }
  end
  
  def update(filename, opts = nil)
    list=[]
    list.push(filename)
    return update_list(list, opts)
  end

  def update_list(list, opts = nil)
    opts = @options if nil==opts

    r = false
    @db.transaction { |db|
      list.each {|pkgfile|
        r |= update_one(db, pkgfile, opts)
      }
    }
    return r
  end

  private 
  def delete_one(db, pkgfile, opts)  
    STDERR.puts "deleting entry for #{pkgfile}" if (opts[:verbose]>1) 
    id = db.get_first_value("select id from pkg_tbl where pkgfile == '#{pkgfile}'").to_i
    if nil != id then
      delete_cached(db, id)
      db.execute("delete from pkg_tbl where id == #{id}")
    end
  end

  #
  #
  # returns true when DB is updated, otherwise returns false
  private
  def update_one(db, pkgfile, opts) 
    filename = "#{opts[:pkgdir_base]}/#{pkgfile}"
    STDERR.puts "checking #{filename}\n" if (opts[:verbose]>1)
    timestamp = File.mtime(filename).to_i
    pkgname = File.basename(pkgfile).split("-")[0..-3].join("-")

    if !opts[:force_update] then
      sql = "select count(id) from pkg_tbl where pkgname == '#{pkgname}' and lastupdate>=#{timestamp}"
      if  db.get_first_value(sql).to_i == 1  then
        STDERR.puts "skipping #{pkgfile}" if (opts[:verbose]>1) 
        return false
      end
    end
        
    STDERR.puts "updating entry for #{pkgname}" if (opts[:verbose]>-1) 

    # create pkg_tbl entry
    db.execute("insert or ignore into pkg_tbl (pkgname, pkgfile) values(?,?)",
               [pkgname, pkgfile])
    id = db.get_first_value("select id from pkg_tbl where pkgname == ?",
                            [pkgname]).to_i
    
    # delete old datas
    delete_cached(db, id)
    
    # insert capability(=provides)
    pkg = RPM::Package.open(filename)
    pkg.provides.each {|prov|
      name, op, ver = prov.conv
      db.execute("insert into capability_tbl (owner, capability, comparison, version) values (#{id}, #{name}, #{op}, #{ver})")
    }
    
    # insert dependency(=requires)
    pkg.requires.each {|req|
      name, op, ver = req.conv
      db.execute("insert into dependency_tbl (owner, capability, comparison, version) values (#{id}, #{name}, #{op}, #{ver})")
    }
    
    pkg.conflicts.each {|conflict|
      name, op, ver = conflict.conv
      db.execute("insert into conflict_tbl (owner, capability, comparison, version) values (#{id}, #{name}, #{op}, #{ver})")
    }
    
    pkg.obsoletes.each {|obso|
      name, op, ver = obso.conv
      db.execute("insert into obsolete_tbl (owner, capability, comparison, version) values (#{id}, #{name}, #{op}, #{ver})")
    }
    
    if opts[:update_file_tbl] then
      pkg.files.each {|file|
        path = file.path
        db.execute("insert into file_tbl (owner, path) values (?, ?)", 
                   [id, path])
      }
    end

    db.execute("UPDATE pkg_tbl SET lastupdate = ?, buildtime = ? WHERE id == ?",
               [timestamp, pkg[RPM::TAG_BUILDTIME], id])
    pkg = nil

    return true
  rescue => e
    STDERR.puts "   exception: #{e} " if (opts[:verbose]>-1)
    STDERR.puts "#{pkgfile} is bad rpm package, skip" if (opts[:verbose]>-1)
    return false
  end

  private  
  def delete_cached(db, id)
    db.execute("delete from capability_tbl where owner == #{id}")
    db.execute("delete from dependency_tbl where owner == #{id}")
    db.execute("delete from conflict_tbl where owner == #{id}")
    db.execute("delete from obsolete_tbl where owner == #{id}")
    db.execute("delete from file_tbl where owner == #{id}")
  end

end  # end of class PkgDB
