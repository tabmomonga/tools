# -*- coding: utf-8 -*-
# lib/install.rb
#
# by Hiromasa YOSHIMOTO <y@momonga-linux.org>



def rpmq_buildtime(pkgfile)
  name = File.basename(pkgfile).split('-')[0..-3].join('-')
  ts=`LANG=C \\rpm -q --qf '%{BUILDTIME}' #{name}`.to_i
  return ts
end

def file_buildtime(filename)
  ts=`LANG=C \\rpm -qp --qf '%{BUILDTIME}' #{filename}`.to_i
  return ts
end


# Retrieves pkgfiles from pkgdb for the "requested" capabilities
def select_required_packages(db, requested, opts = nil)
  if opts.nil? then
    opts = OPTS
  end
  
  installpkg = Set.new
  msg = nil

  count = 0
  while requested.count >0  && count < opts[:max_retry] do
    count = count + 1

    if opts[:verbose]>1 then
      STDERR.puts "loop: #{count}\n"
      STDERR.puts "  Targets:"
      requested.each do |req|
        STDERR.puts "    #{req}"
      end
    end

    before = installpkg.count

    requested.each do |cap|
      found = false
      if cap =~ /\.rpm$/ then
        cap = "#{OPTS[:pkgdir_base]}/#{cap}"
        if !File.exist?(cap) then
          msg = "  no such file, #{cap}"
          return 
        end

        current = rpmq_buildtime(cap)
        target = file_buildtime(cap)
        if (0 == current) || (current != target) then
          STDERR.puts "  Installing #{cap}" if opts[:verbose]>1
          installpkg.add(cap)
          found = true
        else
          STDERR.puts " #{cap} is already installed" if opts[:verbose]>1
          next
        end
      end
      
      if !found then
        sql = "SELECT pkgfile,buildtime FROM pkg_tbl WHERE pkgname GLOB '#{cap}'"
        db.execute(sql) do |pkgfile,buildtime|
          pkgfile = "#{OPTS[:pkgdir_base]}/#{pkgfile}"
          ts = rpmq_buildtime(pkgfile)
          if ts != buildtime.to_i then
            STDERR.puts "  Installing #{File.basename(pkgfile)} for #{cap}" if opts[:verbose]>1
            installpkg.add(pkgfile)
          end
          found = true
        end
      end

      if !found then
        sql = "SELECT pkgfile,buildtime FROM capability_tbl INNER JOIN pkg_tbl ON id==owner WHERE capability GLOB '#{cap}'"
        db.execute(sql) do |pkgfile,buildtime|
          pkgfile = "#{OPTS[:pkgdir_base]}/#{pkgfile}"
          ts = rpmq_buildtime(pkgfile)
          if ts != buildtime.to_i then
            STDERR.puts "  Installing #{File.basename(pkgfile)} for #{cap}" if opts[:verbose]>1
            installpkg.add(pkgfile)
          end
          found = true
        end
      end

      if !found then
        msg = "there is no package providing #{cap}"
        return
      end
    end

    if installpkg.count == before  then
      # すでにinstall済の場合
      msg = nil
      return 
    end

    missing = Set.new
    
    cmd="LANG=C \\rpm --test -vU #{installpkg.to_a.join(' ')} 2>&1"
    log=`#{cmd}`
    log.each_line do |line|
      line.chomp!
      token = line.split
      cap = nil
      dep = nil
      if line =~ /is needed by \(installed\)/ then
        dep = token[0]
        cap = token[-1].split('-')[0..-3].join('-')
      elsif line =~ / is needed by / then
        cap = token[0]
        dep = token[-1]
      end

      if cap then
        missing.add(cap)
        STDERR.puts "  Adding #{cap} for #{dep}" if opts[:verbose]>1
      end
    end  

    requested = missing.to_a - requested
  end

  if count>=opts[:max_retry] then
    msg = "Too many dependancies"
  end

ensure
  installpkg.clear if msg

  return installpkg, msg
end
