###--
### OmoiKondara
###
### Copyright (C) 2003 Momonga Project.
###
### $Id: omokon.rb,v 1.1 2003/05/07 01:34:56 muraken Exp $
###++

require "omokon/requires"

module OmoiKondara

  def self.resolved?(require, version)
    case require[:rel]
    when "<" then
      version <  require[:version]
    when "<=" then
      version <= require[:version]
    when ">" then
      version >  require[:version]
    when ">=" then
      version >= require[:version]
    when "==" then
      version == require[:version] or
        version.v == require[:version].v
    else
      true
    end
  end # def self.resolved?(require, version)

  def self.install_package(filename)
    puts "install_package(#{filename})"
    pkg = RPM::Package.open(filename)
    pkg.requires.each {|req| install(req.convert) }
    puts "sudo rpm -Uvh #{filename}"
  end # def self.install_package(filename)

  def self.install(require)
    puts "install(#{require.inspect})"
    resolved = false
    unresolved = []
    RPM::DB[require[:name]].each do |pkg|
      p pkg.name
      if resolved?(require, pkg.version) then
        resolved = true
      else
        unresolved.push(pkg)
      end
    end
    if not resolved then
      packages = SpecDB.i.packages[require[:name]].select do |pkg|
        resolved?(require, pkg[:version])
      end

      require "omokon/pkgpool.rb"
      require "omokon/config.rb"
      packages.each do |pkg|
        p pkg
        builtpkgs = PackagePool.i.search_package(pkg[:name], Config.i.build_arch)
        if builtpkgs.empty? then
          build(pkg[:spec])
          builtpkgs = PackagePool.i.search_package(pkg[:name], Config.i.build_arch)
        end
        builtpkgs.each {|fn| install_package(fn) }
      end
    end
  end # def self.install(require)

  def self.build_spec(name)
    topdir = "#{Dir.pwd}/#{name}"
    specfile = "#{topdir}/#{name}.spec"
    puts "rpmbuild #{specfile}"
  end # def self.build_spec(name)

  def self.build(name)
    puts "build(#{name})"
    require "omokon/specdb"
    if not SpecDB.i.specs.has_key?(name) then
      raise ArgumentError, "#{name} is not found"
    end

    ## check build requires
    require "omokon/rpm"
    SpecDB.i.specs[name][:requires].each {|req| install(req) }

    build_spec(name)
  end # def self.build(name)

end # module OmoiKondara

###--
### Local Variables:
### mode: ruby
### ruby-indent-level: 2
### indent-tabs-mode: nil
### End:
###++
