# lib/pkgdb.rb
#
# by Hiromasa YOSHIMOTO <y@momonga-linux.org>

require 'lib/database.rb'
require 'rpm'

module RPM
  class Dependency
    def to_struct
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
      PkgDB::DependencyData.new(name, relation ? version : nil, relation)
    end
  end
end # module RPM


class PkgDB < DBBase

  TABLE_MAJOR_VERSION=1 # increase when the layout break compatibility
  TABLE_MINOR_VERSION=1 # increase when the regeneration of DB is needed
  TABLE_LAYOUT=<<ENDOFSQL

-- pkgfile's capabilities (=provides) info
drop table if exists capability_tbl;
create table capability_tbl (
       owner integer not null,
       capability text not null,
       version text default null
);

-- pkgfile's dependencies (=requires) info
drop table if exists dependency_tbl;
create table dependency_tbl (
       owner integer not null,
       capability text not null,
       operator text default null,
       version text default null
);

drop table if exists obsolete_tbl;
create table obsolete_tbl (
       owner integer not null,
       capability text not null,
       operator text default null,
       version text default null
);

drop table if exists conflict_tbl;
create table conflict_tbl (
       owner integer not null,
       capability text not null,
       operator text not null,
       version text default null
);

drop table if exists pkg_tbl;
create table pkg_tbl (
       id integer primary key autoincrement,
       pkgfile text unique,
       lastupdate integer
);

drop table if exists misc_tbl;
create table misc_tbl (
       major_version integer,
       minor_version integer,
       lastupdate integer
);
ENDOFSQL

  DependencyData = Struct.new(:name, :version, :rel)
  class DependencyData
    def ver
      if !rel then
        nil
      else
        str = ""
        str += "#{version.e}:" if version.e
        str += "#{version.v}"
        str += "-#{version.r}" if version.r
        str
      end
    end
  end

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
          d = prov.to_struct
          v = d.rel ? "'#{d.ver}'" : "NULL"
          db.execute("insert into capability_tbl (owner, capability, version) values (#{id}, '#{prov.name}', #{v})")
        }

        # insert dependency(=requires)
        pkg.requires.each {|req|
          r = req.to_struct
          op = r.rel ? "'#{r.rel}'" : "NULL"
          v  = r.rel ? "'#{r.ver}'" : "NULL"
          db.execute("insert into dependency_tbl (owner, capability, operator, version) values (#{id}, '#{req.name}', #{op}, #{v})")
        }

        pkg.conflicts.each {|conflict|
          r = conflict.to_struct
          op = r.rel ? "'#{r.rel}'" : "NULL"
          v  = r.rel ? "'#{r.ver}'" : "NULL"
          db.execute("insert into conflict_tbl (owner, capability, operator, version) values (#{id}, '#{conflict.name}', #{op}, #{v})")
        }

        pkg.obsoletes.each {|obso|
          r = obso.to_struct
          op = r.rel ? "'#{r.rel}'" : "NULL"
          v  = r.rel ? "'#{r.ver}'" : "NULL"
          db.execute("insert into obsolete_tbl (owner, capability, operator, version) values (#{id}, '#{obso.name}', #{op}, #{v})")
        }
      
        # update spec's timestamp
        db.execute("update pkg_tbl set lastupdate = #{timestamp} where id==#{id}")
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
