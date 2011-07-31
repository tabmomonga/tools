# -*- coding: utf-8 -*-
# lib/pkgdb.rb
#
# by Hiromasa YOSHIMOTO <y@momonga-linux.org>

require 'lib/database.rb'

class PkgDB < DBBase

  TABLE_MAJOR_VERSION=5 # increase when the layout breaks compatibility
  TABLE_MINOR_VERSION=1 # increase when rebuild DB is required
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
       arch text,
       lastupdate integer,
       unique(pkgname,arch)
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

    # prepared statement for update_one()
    @stmt_select_count_id =
      @db.prepare('select count(id) from pkg_tbl where pkgname == ? AND arch == ? AND lastupdate >= ?')
    @stmt_insert_or_ignore_into_pkg_tbl = 
      @db.prepare('insert or ignore into pkg_tbl (pkgname,arch) values(?,?)')
    @stmt_select_id_from_pkg_tbl2 =
      @db.prepare('select id from pkg_tbl where pkgname == ? AND arch == ?')
    @stmt_insert_into_capability_tbl = 
      @db.prepare('insert into capability_tbl (owner, capability, comparison, version) values (?,?,?,?)')

    @stmt_insert_into_dependency_tbl =
      @db.prepare('insert into dependency_tbl (owner, capability, comparison, version) values (?,?,?,?)')
    @stmt_insert_into_conflict_tbl =
      @db.prepare('insert into conflict_tbl (owner, capability, comparison, version) values (?,?,?,?)')
    @stmt_insert_into_obsolete_tbl =
      @db.prepare('insert into obsolete_tbl (owner, capability, comparison, version) values (?,?,?,?)')
    @stmt_insert_into_file_tbl = 
      @db.prepare('insert into file_tbl (owner, path) values (?, ?)')

    @stmt_update_pkg_tbl =
      @db.prepare('UPDATE pkg_tbl SET pkgfile = ?, lastupdate = ?, buildtime = ? WHERE id == ?')

    # for delete_one()
    @stmt_select_id_from_pkg_tbl1 =
      @db.prepare('select id from pkg_tbl where pkgfile == ?')
    @stmt_delete_from_pkg_tbl =
      @db.prepare('delete from pkg_tbl where id == ?')

    # for delete_cached()
    @stmt_delete_from_capability_tbl =
      @db.prepare('delete from capability_tbl where owner == ?')
    @stmt_delete_from_dependency_tbl =
      @db.prepare('delete from dependency_tbl where owner == ?')
    @stmt_delete_from_conflict_tbl =
      @db.prepare('delete from conflict_tbl where owner == ?')
    @stmt_delete_from_obsolete_tbl =
      @db.prepare('delete from obsolete_tbl where owner == ?')
    @stmt_delete_from_file_tbl =
      @db.prepare('delete from file_tbl where owner == ?')

  end

  def close
    # update_one()
    @stmt_select_count_id.close
    @stmt_insert_or_ignore_into_pkg_tbl.close
    @stmt_select_id_from_pkg_tbl2.close
    @stmt_insert_into_capability_tbl.close

    @stmt_insert_into_dependency_tbl.close
    @stmt_insert_into_conflict_tbl.close
    @stmt_insert_into_obsolete_tbl.close
    @stmt_insert_into_file_tbl.close

    @stmt_update_pkg_tbl.close
    
    # for delete_one()
    @stmt_select_id_from_pkg_tbl1.close
    @stmt_delete_from_pkg_tbl.close

    # for delete_cached()
    @stmt_delete_from_capability_tbl.close
    @stmt_delete_from_dependency_tbl.close
    @stmt_delete_from_conflict_tbl.close
    @stmt_delete_from_obsolete_tbl.close
    @stmt_delete_from_file_tbl.close
    super()
 end

  def check(opts = nil)
    opts = @options if nil==opts

    @db.transaction { |db|
      db.execute('DELETE FROM pkg_tbl WHERE pkgfile IS NULL')

      sql = 'SELECT pkgfile,MAX(id) AS id FROM pkg_tbl GROUP BY pkgfile HAVING COUNT(*) > 1'
      db.execute(sql) do |pkgfile,id|
        STDERR.puts "warrning: #{pkgfile} has broken entries, fixing them..."
        sql = 'DELETE FROM pkg_tbl WHERE pkgfile == ? AND id != ?'
        db.execute(sql, [pkgfile, id])
      end
    }
  rescue => e
    STDERR.puts "   exception: #{e} " if (opts[:verbose]>-1)
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

    failed = false
    @db.transaction
    list.each {|pkgfile|
      failed = ! update_one(@db, pkgfile, opts)
      break if failed
    }
    if failed then
      @db.rollback
    else
      @db.commit
    end
    return !failed
  end

  private 
  def delete_one(db, pkgfile, opts)  
    STDERR.puts "deleting entry for #{pkgfile}" if (opts[:verbose]>1) 
    id = @stmt_select_id_from_pkg_tbl1.execute!([pkgfile]).to_i
    if nil != id then
      delete_cached(db, id)
      @stmt_delete_from_pkg_tbl.execute!([id])
    end
  end

  #
  #
  # returns true when DB is updated, otherwise returns false
  private
  def update_one(db, pkgfile, opts) 
    pkgfile.encode!(Encoding::ASCII)
    filename = "#{opts[:pkgdir_base]}/#{pkgfile}".encode(Encoding::ASCII)
    STDERR.puts "checking #{filename}\n" if (opts[:verbose]>1)
    timestamp = File.mtime(filename).to_i
    pkgname = File.basename(pkgfile).split("-")[0..-3].join("-")
    arch = File.basename(pkgfile).split('.')[-2]

    if !opts[:force_update] then
      if @stmt_select_count_id.get_first_value([pkgname, arch, timestamp]).to_i == 1 then
        STDERR.puts "skipping #{pkgfile}" if (opts[:verbose]>1) 
        return true
      end
    end
        
    STDERR.puts "updating entry for #{pkgname}" if (opts[:verbose]>-1) 

    # create pkg_tbl entry
    @stmt_insert_or_ignore_into_pkg_tbl.execute!([pkgname, arch])
    id = @stmt_select_id_from_pkg_tbl2.get_first_value([pkgname,arch]).to_i
    STDERR.puts "id :#{id} pkgname: #{pkgname}.#{arch}" if opts[:verbose]>1

    # delete old datas
    delete_cached(db, id)
    
    # insert capability(=provides)
    pkg = RPM::Package.open(filename)
    pkg.provides.each {|prov|
      name, op, ver = prov.conv
      @stmt_insert_into_capability_tbl.execute!([id, name, op, ver])
    }
    
    # insert dependency(=requires)
    pkg.requires.each {|req|
      name, op, ver = req.conv
      @stmt_insert_into_dependency_tbl.execute!([id, name, op, ver])
    }
    
    pkg.conflicts.each {|conflict|
      name, op, ver = conflict.conv
      @stmt_insert_into_conflict_tbl.execute!([id, name, op, ver])
    }
    
    pkg.obsoletes.each {|obso|
      name, op, ver = obso.conv
      @stmt_insert_into_obsolete_tbl.execute!([id, name, op, ver])
    }
    
    if opts[:update_file_tbl] then
      pkg.files.each {|file|
        path = file.path.encode(Encoding::ASCII, :replace => "?")
        @stmt_insert_into_file_tbl.execute!([id, path])
      }
    end

    @stmt_update_pkg_tbl.execute!([pkgfile, timestamp, pkg[RPM::TAG_BUILDTIME], id])
               
    pkg = nil

    return true
  rescue => e
    STDERR.puts "   exception: #{e} " if (opts[:verbose]>-1)
    STDERR.puts "#{pkgfile} is bad rpm package, skip" if (opts[:verbose]>-1)
    pkg = nil

    return false
  end

  private  
  def delete_cached(db, id)
    @stmt_delete_from_capability_tbl.execute!([id])
    @stmt_delete_from_dependency_tbl.execute!([id])
    @stmt_delete_from_conflict_tbl.execute!([id])
    @stmt_delete_from_obsolete_tbl.execute!([id])
    @stmt_delete_from_file_tbl.execute!([id])
  end

end  # end of class PkgDB
