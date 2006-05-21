###--
### OmoiKondara
###
### Copyright (C) 2003 Momonga Project.
###
### $Id: rpm.rb,v 1.2 2003/05/05 08:24:54 muraken Exp $
###++

begin
  require "rpmmodule"

  module RPM
    class DB
      def self.exist?(name)
        pkg = nil
        begin
          rpmdb = open
          rpmdb.each_match(RPM::TAG_PROVIDENAME, name) {|pkg| break}
        ensure
          rpmdb.close
        end
        not pkg.nil?
      end # def self.exist?(name)

      def self.[](name)
        pkg = []
        begin
          rpmdb = open
          rpmdb.each_match(RPM::TAG_PROVIDENAME, name) {|a| pkg.push(a) }
        ensure
          rpmdb.close
        end
        pkg
      end # def self.[](name)
    end # class DB

    class Spec
      def convert
        Hash[
          :sources  => self.sources,
          :packages => self.packages.collect {|a| a.convert },
          :archs    => self.buildarchs,
          :requires => (if self.buildrequires.nil? then
                          []
                        else
                          self.buildrequires.collect {|a| a.convert }
                        end),
        ]
      end # def convert
    end # class Spec

    class Package
      def convert
        Hash[
          :name     => self.name,
          :version  => self.version,
          :group    => self[TAG_GROUP],
          :provides => self.provides.collect {|a| a.convert },
          :requires => self.requires.collect {|a| a.convert },
        ]
      end # def convert
    end # class Package

    class Dependency
      def convert
        rel = if le? then "<="
              elsif lt? then "<"
              elsif ge? then ">="
              elsif gt? then ">"
              elsif eq? then "=="
              else  nil end
        Hash[
          :name    => self.name,
          :version => (if rel.nil? then
                         nil
                       else
                         self.version
                       end),
          :rel     => rel,
        ]
      end # def convert
    end # class Dependency
  end # module RPM

  module OmoiKondara
    module RPM
      include ::RPM

      def self.setup_rpmrc(root, name)
        begin
          require "omokon/config"
          rpmrc = "#{root}/#{name}/rpmrc"
          rpmmacros = "#{root}/#{name}/rpmmacros"
          ::File.open(rpmrc, "w") do |io|
            template = if Config.i.debug_build? then
                         "#{root}/rpmrc.debug"
                       else
                         "#{root}/rpmrc"
                       end
            ::IO.foreach(template) do |line|
              case line
              when /^macrofiles/ then
                io.puts("#{line.chomp}#{rpmmacros}")
              else
                io.print(line)
              end
            end
          end
          ::File.open(rpmmacros, "w") do |io|
            io.puts("%_topdir   #{root}/#{name}")
            io.puts("%_arch     #{Config.i.build_architecture}")
            io.puts("%_host_cpu #{Config.i.build_architecture}")
            if Config.i.enable_distcc? then
              io.puts("%OmoiKondara_enable_distcc 1")
            else
              io.puts("%OmoiKondara_enable_distcc 0")
            end
            if Config.i.debug_build? then
              io.puts("%OmoiKondara_debug_build 1")
              io.puts("%__os_install_post \\")
              io.puts("    /usr/lib/rpm/brp-compress \\")
              io.puts("    /usr/lib/rpm/modify-init.d \\")
              io.puts("%{nil}")
            else
              io.puts("%OmoiKondara_debug_build 0")
            end
          end
          ::RPM.readrc(rpmrc)
          yield
        ensure
          require "fileutils"
          FileUtils.rm(rpmrc, :force)
          FileUtils.rm(rpmmacros, :force)
        end
      end # def self.setup_rpmrc(root, name)
    end # module RPM
  end # module OmoiKondara

rescue LoadError

  module RPM
    class DB
      def self.exist?(name)
        system("rpm -q #{name} > /dev/null 2>&1")
        $?.to_i.zero?
      end # def self.exist?(name)
    end # class DB
  end # module RPM

end

###--
### Local Variables:
### mode: ruby
### ruby-indent-level: 2
### indent-tabs-mode: nil
### End:
###++
