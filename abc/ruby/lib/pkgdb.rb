# lib/pkgdb.rb
#
# by Hiromasa YOSHIMOTO <y@momonga-linux.org>

require 'lib/database.rb'

class PkgDB < DBBase

  TABLE_MAJOR_VERSION=2 # increase when the layout breaks compatibility
  TABLE_MINOR_VERSION=2 # increase when rebuild DB is required
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
       pkgfile text unique,
       pkgname text,
       buildtime integer,
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
    open_database(database, 
                  TABLE_LAYOUT,
                  TABLE_MAJOR_VERSION, 
                  TABLE_MINOR_VERSION,  opts)
  end

  def check(opts = nil)
    opts = @options if nil==opts
    sql = "select pkgfile,max(id) as id from pkg_tbl group by pkgfile having count(*) > 1"
    @db.execute(sql) do |pkgfile,id|
      STDERR.puts "warrning: pkg_tbl has broken entries, fixing them..."
      sql = "delete from pkg_tbl where pkgfile == '#{pkgfile}' and id != #{id}"
      @db.execute(sql)
    end
  end

  def delete(pkgfile, opts = nil)
    opts = @options if nil==opts

    STDERR.puts "deleting entry for #{pkgfile}" if (opts[:verbose]>1) 
    @db.transaction { |db|
      id = db.get_first_value("select id from pkg_tbl where pkgfile == '#{pkgfile}'")
      if nil != id then
        delete_cached(db, id)
        db.execute("delete from pkg_tbl where id == #{id}")
      end
    }
  end
  
  def update(filename, opts = nil)
    list=[]
    list.push(filename)
    update_list(filename, opts)
  end

  def update_list(list, opts = nil)
    opts = @options if nil==opts

    @db.transaction { |db|
      list.each {|pkgfile|
	STDERR.puts "checking #{pkgfile}\n" if (opts[:verbose]>1)
        timestamp = File.mtime(pkgfile).to_i
        
        if !opts[:force_update] then
          sql = "select count(id) from pkg_tbl where pkgfile == '#{pkgfile}' and lastupdate>=#{timestamp}"
          if  @db.get_first_value(sql) == "1"  then
            STDERR.puts "skipping #{pkgfile}" if (opts[:verbose]>1) 
            next
          end
        end
        
        STDERR.puts "updating entry for #{pkgfile}" if (opts[:verbose]>-1) 
        
        # create spec entry
        db.execute("insert or ignore into pkg_tbl (pkgfile) values('#{pkgfile}')")
        id = db.get_first_value("select id from pkg_tbl where pkgfile == '#{pkgfile}'")
        
        # delete old datas
        delete_cached(db, id)

        # insert capability(=provides)
        pkg = RPM::Package.open(pkgfile)
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
      

        db.execute("UPDATE pkg_tbl SET lastupdate = #{timestamp}, buildtime = #{pkg[RPM::TAG_BUILDTIME]}, pkgname = '#{pkg[RPM::TAG_NAME]}' WHERE id==#{id}")
        pkg = nil
      }
    }
  end

  private  
  def delete_cached(db, id)
    db.execute("delete from capability_tbl where owner == #{id}")
    db.execute("delete from dependency_tbl where owner == #{id}")
  end

end  # end of class PkgDB
