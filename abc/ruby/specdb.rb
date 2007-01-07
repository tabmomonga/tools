require 'sqlite3'
require 'rpm'

class SpecDB 
  
  def open(database)
    @db = SQLite3::Database.new(database)
  end

  def close
    @db.close
  end

  def delete(name)
    @db.transaction() {|db|
      id = db.get_first_value("select id from specfile_tbl where name == '#{name}'")
      if nil!=id then
        delete_cache(db, id)
      end
    }
  end
  
  def update(name, opts = nil)
    filename="#{name}/#{name}.spec"
    timestamp = File.mtime(filename).to_i

    if !opts[:force_update] then
      sql = "select count(id) from specfile_tbl where name == '#{name}' and lastupdate>=#{timestamp}"
      if  @db.get_first_value(sql) == "1"  then
        STDERR.puts "skip #{name}" if (opts[:verbose]>0) 
        return 
      end
    end
    
    spec = RPM::Spec.open(filename)
    if spec.nil? then
      STDERR.puts "failed to parse #{filename}."
      exit 1
    end
    
    @db.transaction {|db|
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
    
    spec = nil
  end
  
  private
  
  def delete_cache(db, id)
    db.execute("delete from buildreq_tbl where owner == #{id}");
    db.execute("delete from package_tbl where owner == #{id}");
    db.execute("delete from require_tbl where owner == #{id}");
    db.execute("delete from provide_tbl where owner == #{id}");
  end
  
end  # end of class SpecDB



