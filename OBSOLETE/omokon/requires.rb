###--
### OmoiKondara
###
### Copyright (C) 2003 Momonga Project.
###
### $Id: requires.rb,v 1.4 2003/05/04 19:33:47 muraken Exp $
###++

module OmoiKondara
  ary = []

  flag = true
  begin
    require "rpmmodule"

    if RPM::Version.new(RPM::VERSION) < RPM::Version.new("1.1.10") then
      flag = false
    end
  rescue LoadError
    flag = false
  end
  ary.push "ruby-rpm" unless flag

  flag = true
  begin
    require "fileutils"

  rescue LoadError
    flag = false
  end
  ary.push "ruby-shim" unless flag

  if not ary.empty? then
    require "omokon/config"
    require "omokon/sysenv"

    def self.in_dir(dir)
      begin
        puts("Entering Directory: #{dir}")
        oldpwd = Dir.pwd
        Dir.chdir(dir)
        yield
      ensure
        Dir.chdir(oldpwd)
        puts("Leaving Directory: #{dir}")
      end
    end # def self.in_dir(dir)

    def self.parse_specfile(filename)
      spec = {
        :macros => {
          "_topdir" => File.dirname(filename),
          "_tmppath" => "/var/tmp",
        },
        :sources => {},
        :nosource => [],
        :patches => {},
        :nopatch => [],
      }
      File.open(filename, "r") do |io|
        io.each_line do |line|
          case line
          when /^\s*(source|patch)(\d*):\s*(\S+)/i
            type = $1
            uri = $3.gsub(/%{?(\w+)}?/) do
              spec[:macros][$1.downcase]
            end
            n = ($2 == "") ? 0 : $2.to_i
            if type =~ /source/i then
              spec[:sources][n] = uri
            else
              spec[:patches][n] = uri
            end
          when /^\s*no(source|patch):\s*(.+)/i
            type = $1
            ary = $2.split(/\s/).collect{|a| a.to_i}
            if type =~ /source/i then
              spec[:nosource].concat(ary)
            else
              spec[:nopatch].concat(ary)
            end
          when /^%define\s+(\w+)\s+(\S+)\s*$/
            mname = $1.downcase
            mbody = $2
            spec[:macros][mname] = mbody.gsub(/%{?(\w+)}?/) do
              spec[:macros][$1.downcase]
            end
          when /^\s*(\S+):\s*(.+)\s*$/
            spec[:macros][$1.downcase] = $2.gsub(/%{?(\w+)}?/) do
              spec[:macros][$1.downcase]
            end
          end
        end
      end
      [ :name,
        :epoch,
        :version,
        :release,
        :group ].each do |id|
        spec[id] = spec[:macros][id.to_s.downcase]
      end
      spec
    end # def self.parse_specfile(filename)

    def self.exec_command(cmdline)
      STDOUT.puts(cmdline)
      system(cmdline)
    end # def self.exec_command(cmdline)

    def self.prepare_directories
      exec_command("mkdir -p SOURCES")
      exec_command("mkdir -p BUILD")
      exec_command("mkdir -p SRPMS")
      exec_command("mkdir -p RPMS/#{SystemEnvironment.arch}")
      exec_command("mkdir -p RPMS/noarch")
    end # def self.prepare_directories

    def self.download_file(uri)
      exec_command("#{Config.i.download} #{uri}")
      exec_command("cp -pvf #{Config.i.topdir}/SOURCES #{File.basename(uri)}")
    end # def self.download_file(uri)

    def self.prepare_sources(sources, nosource)
      sources.each do |n, uri|
        filename = File.basename(uri)
        if nosource.include?(n) then
          if File.file?("#{Config.i.topdir}/SOURCES/#{filename}") then
            exec_command("cp -pfv #{Config.i.topdir}/SOURCES/#{filename} SOURCES")
          else
            in_dir("SOURCES") { download_file(uri) }
          end
        else
          exec_command("cp -pfv #{filename} SOURCES")
        end
      end
    end # def self.prepare_sources(spec)

    def self.setup_rpmmacros
      File.open("rpmmacros", "w") do |io|
        io.puts("%_topdir #{Dir.pwd}")
        io.puts("%_arch #{SystemEnvironment.arch}")
        io.puts("%_host_cpu #{SystemEnvironment.arch}")
      end
    end # def self.setup_rpmmacros

    def self.setup_rpmrc
      File.open("rpmrc", "w") do |io|
        IO.foreach("../rpmrc") do |line|
          case line
          when /^macrofiles/ then
            io.puts("#{line.chomp}#{Dir.pwd}/rpmmacros")
          else
            io.print(line)
          end
        end
      end
      setup_rpmmacros
    end # def self.setup_rpmrc

    def self.execute_rpmbuild(filename)
      exec_command("rpmbuild --rcfile rpmrc -ba #{filename}")
    end # def self.execute_rpmbuild

    def self.install_packages
      exec_command("sudo rpm -Uvh RPMS/*/*.rpm")
    end # def self.install_packages

    def self.cleanup
      exec_command("rm -rf BUILD SOURCES SRPMS RPMS")
    end # def self.cleanup

    def self.build_and_install(name)
      topdir = "#{Dir.pwd}/#{name}"
      spec = parse_specfile("#{topdir}/#{name}.spec")
      in_dir(topdir) do
        prepare_directories
        prepare_sources(spec[:sources], spec[:nosource])
        prepare_sources(spec[:patches], spec[:nopatch])
        setup_rpmrc
        if execute_rpmbuild("#{name}.spec") then
          install_packages
        end
        exit 1
        cleanup
      end
    end # def self.build_and_install(name)

    ary.each {|a| build_and_install(a) }
    exec("#{$0} #{ARGV.join(" ")}")
  end
end # module OmoiKondara

###--
### Local Variables:
### mode: ruby
### ruby-indent-level: 2
### indent-tabs-mode: nil
### End:
###++
