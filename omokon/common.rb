### -*- mode: ruby; indent-tabs-mode: nil; -*-

require 'mutex_m'
require 'net/ftp'
require 'net/http'

require 'omokon/package'
require 'omokon/spec'
require 'omokon/specdb'

module OmoiKondara

  ARCH = case `uname -m`
         when /i.86/
           'i586'
         when /alpha/
           arch = 'alpha'
           IO.foreach('/proc/cpuinfo') do |line|
             if line =~ /^cpu model\s*:\s*EV(\d).*$/ then
               arch = 'alphaev5' if $1.to_i == 5
             end
           end
           arch
         when /mips/
           arch = 'mips'
           IO.foreach('/proc/cpuinfo') do |line|
             arch += 'EE' if line =~ /^system type\s*:\s*EE PS2\s*$/
             if line =~ /^byteorder\s*:\s*(.+)\s*$/ then
               if $1 == 'little' then
                 arch += 'le'
               else
                 arch += 'be'
               end
             end
           end
           arch
         else
           `uname -m`.chomp
         end # case `uname -m`

  OS = `uname -s`.chomp.downcase

  VALID_GROUP = [
    'Amusements/Games',
    'Amusements/Graphics',
    'Applications/Archiving',
    'Applications/Communications',
    'Applications/Databases',
    'Applications/Editors',
    'Applications/Emulators',
    'Applications/Engineering',
    'Applications/File',
    'Applications/Internet',
    'Applications/Multimedia',
    'Applications/Productivity',
    'Applications/Publishing',
    'Applications/System',
    'Applications/Text',
    'Development/Debuggers',
    'Development/Languages',
    'Development/Libraries',
    'Development/System',
    'Development/Tools',
    'Documentation',
    'System Environment/Base',
    'System Environment/Daemons',
    'System Environment/Kernel',
    'System Environment/Libraries',
    'System Environment/Shells',
    'User Interface/Desktops',
    'User Interface/X',
    'User Interface/X Hardware Support',
  ]

  Output = Object.new
  Output.extend Mutex_m
  def Output.puts(*args)
    io = Thread.current[:stdout] || STDOUT
    if io == STDOUT then
      synchronize do
        io.print "[#{Thread.current[:job]}]" if Thread.current[:job]
        io.puts(*args)
      end
    else
      io.puts(*args)
    end # if io == STDOUT then
  end # def Output.puts

  Error = Object.new
  Error.extend Mutex_m
  def Error.puts(*args)
    io = Thread.current[:stderr] || STDERR
    if io == STDERR then
      synchronize {
        io.print "[#{Thread.current[:job]}]" if Thread.current[:job]
        io.puts(*args)
      }
    else
      io.puts(*args)
    end # if io == STDERR then
  end # def Error.puts

  def OmoiKondara.execute(cmdline, log=nil, verbose=false)
    Output.puts "---- #{cmdline}"
    pid = Process.fork
    status = nil
    if pid.nil? then
      if log and !verbose then
        $stdout.close
        log.dup
        $stderr.close
        log.dup
      end
      exec cmdline
    end # if pid.nil then
    Process.waitpid pid
    $?
  end # def OmoiKondara.execute(cmdline)

  DOWNLOAD_BEGIN    = :download_begin
  DOWNLOAD_PROGRESS = :download_progress
  DOWNLOAD_FINISH   = :download_finish

  DownloadSignal = Struct.new(:type, :uri, :amount, :total)

  Downloader = Object.new

  def Downloader.download(uri, destination)
    case uri
    when %r!^http://([^/]+)(.+)$!
      host, path = $1, $2
      s = Net::HTTP
      if $PROXY_ADDRESS and $PROXY_PORT then
        s = Net::HTTP::Proxy($PROXY_ADDRESS, $PROXY_PORT)
      end
      s.start(host) do |http|
        header = http.head path
        total = header['content-length']
        amount = 0
        if total then
          total = total.to_i
          amount = File.stat(destination).size if File.exist? destination
        else
          ::File.rm_f destination
        end
        open(destination, 'wb') do |io|
          yield DownloadSignal.new(DOWNLOAD_BEGIN, uri, amount, total) if block_given?
          while amount < total do
            header = if amount.zero? then nil else { 'range' => "#{amount}-" } end
            http.get(path) do |buf|
              amount += buf.length
              io.write buf
              yield DownloadSignal.new(DOWNLOAD_PROGRESS, uri, amount, total) if block_given?
            end # http.get(path) do |buf|
            break  if total.nil?
          end # while amount != total then
          yield DownloadSignal.new(DOWNLOAD_FINISH, uri, amount, total) if block_given?
        end # open(destination, 'wb') do |io|
      end # s.start(host) do |http|
    when %r!^ftp://([^/]+)(.+)$!
      host, path = $1, $2
      if host =~ /^([^@]+)@(.+)$/ then
        user, passwd = $1.split('.')
        host = $2
      end
      user ||= 'anonymous'
      passwd ||= $MAILADDR
      begin
        s = Net::FTP.new(host, user, passwd)
        s.chdir ::File.dirname path
        remotefile = ::File.basename path
        total = s.size(remotefile)
        amount = 0
        amount = ::File.stat(destination).size if File.exist? destination
        return if total and total == amount
        yield DownloadSignal.new(DOWNLOAD_BEGIN, uri, amount, total) if block_given?
        open(destination, 'ab') do |io|
          while amount < total do
            s.retrbinary("RETR #{remotefile}", 10, amount.nonzero? ? amount : nil) do |data|
              amount += data.length
              io.write data
              yield DownloadSignal.new(DOWNLOAD_PROGRESS, uri, amount, total) if block_given?
            end
            break  if total.nil?
          end
        end # open(destination, 'ab') do |io|
        yield DownloadSignal.new(DOWNLOAD_FINISH, uri, amount, total) if block_given?
      rescue => e
        raise e
      ensure
        s.close  if s
      end
    when %r!^file://(.+)$!
      path = $1
      File.symlink path, destination
    when /^(\w+):/
      raise "unknown protocol: #{$1}"
    else
      raise "invalid URI: #{uri}"
    end # case uri
  end # def Downloader.download(uri, path)

  RPMDB = Object.new
  RPMDB.extend Mutex_m

  def RPMDB.wait
    lock
    unlock
  end # def RPMDB.wait

  def RPMDB.all_matches(name)
    pkgs = []
    begin
      wait
      rpmdb = RPM::DB.new
      rpmdb.each_match(RPM::DBI_LABEL, name){|a| pkgs.push a}
    ensure
      rpmdb = nil
      GC.start
    end
    pkgs
  end # def RPMDB.all_matches(name)

  def RPMDB.installed?(name)
    not all_matches(name).empty?
  end # def RPMDB.installed?(name)

  def RPMDB.install(root, db, name)
    pkgs = db.packages_by_name name
    raise "package not found: #{name}" if pkgs.empty?
    pkgs.each do |pkg|
      pkgs2 = all_matches pkg.to_s
      f = pkgs2.empty?
      pkgs2.each do |pkg2|
        if pkg.version > pkg2.version or
            pkg.version.newer? pkg2.version then
          f = true
          break
        end
      end
      next  unless f
      pkg.conflicts.flatten.each do |dep|
        pkgs2 = []
        begin
          rpmdb = RPM::DB.new
          pkgs2 = rpmdb.select{|a| a.name == dep.name}
        ensure
          rpmdb = nil
          GC.start
        end
        pkgs2.each do |pkg2|
          f = false
          if dep.version then
            if dep.le? and
                (pkg2.version == dep.version or
                 pkg2.version.older? dep.verision) then
              f = true
            elsif dep.ge? and
                (pkg2.version == dep.version or
                 pkg2.version.newer? dep.version) then
              f = true
            elsif dep.eq? and
                pkg2.version == dep.version then
              f = true
            elsif dep.lt? and
                pkg2.version.older? dep.version then
              f = true
            elsif dep.ge? and
                pkg2.version.newer? dep.version then
              f = true
            end
          else # if dep.version then
            f = true
          end # if dep.version then
          next  unless f
          RPMDB.uninstall root, db, pkg2.name
        end # pkgs2.each do |pkg2|
      end # pkg.conflicts.flatten.each do |dep|
      pkg.requires.each do |dep|
        pkgs2 = db.what_provides dep.name
        raise "capability not found: #{dep.name}" if pkgs2.empty?
        spec = db.spec_by_package pkg
        pkgs2.each do |pkg2|
          if pkg2.name != pkg.name and !installed?(pkg2.to_s) then
            spec2 = db.spec_by_package pkg2
            if (!spec2.data[:zoo] or
                (spec2.data[:zoo] and spec.data[:zoo])) and
                (!spec2.data[:nonfree] or
                 (spec2.data[:nonfree] and spec.data[:nonfree])) then
              RPMDB.install(root, db, pkg2.name)
            end
          end
        end # pkgs2.each do |pkg2|
      end # pkg.requires do |dep|
      filename = Dir.glob("#{root}*/*/#{pkg}.*.rpm").select{|a| a !~ %r!/SRPMS/!}
      spec = db.spec_by_package(pkg)
      if filename.empty? then
        spec.build
      else
        ver = RPM::Version.new(filename[0].sub(/\.[^.]+\.rpm$/, '').
                               split('-')[-2..-1].join '-')
        if ver < spec.packages[0].version or
            ver.older? spec.packages[0].version then
          spec.build
        end
      end
      filename = Dir.glob("#{root}*/*/#{pkg}.*.rpm").select{|a| a !~ %r!/SRPMS/!}
      raise "unable find package file: #{pkg}" if filename.empty?
      synchronize do
        OmoiKondara.execute "sudo rpm -Uvh --force --nodeps #{filename[0]}"
      end
    end # pkgs.each do |pkg|
  end # def RPMDB.install(root, db, name)

  def RPMDB.uninstall(root, db, name)
    Output.puts "try to uninstall #{name}"
    pkgs = []
    synchronize do
      begin
        RPM::DB.new.each_match(RPM::DBI_LABEL, name){|a| pkgs.push a}
      ensure
        GC.start
      end
    end
    pkgs.each do |pkg|
      pkg.provides.each do |dep|
        pkgs2 = []
        synchronize do
          begin
            RPM::DB.new.each_match(RPM::TAG_REQUIRENAME, dep.name){|a| pkgs2.push a}
          ensure
            GC.start
          end
        end
        pkgs2.each do |pkg2|
          unless pkg2.name == name or pkg2.to_s == name then
            RPMDB.uninstall root, db, pkg2.to_s
	  end
        end
      end # pkg.provides do |dep|
      synchronize do
        OmoiKondara.execute "sudo rpm -e --nodeps #{pkg.to_s}"
      end
    end # pkgs2.each do |pgks2|
  end # def RPMDB.uninstall(root, db, name)

end # module OmoiKondara
