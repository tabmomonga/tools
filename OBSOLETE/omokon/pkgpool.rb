###--
### OmoiKondara
###
### Copyright (C) 2003 Momonga Project.
###
### $Id: pkgpool.rb,v 1.1 2003/05/07 01:34:56 muraken Exp $
###++

require "features/ruby18"

module OmoiKondara

  require "singleton"
  class PackagePool
    include Singleton

    class << self
      alias_method :i, :instance
    end

    attr_reader :placement
    attr_reader :archs

    def search_package(name, arch=nil)
      if arch.nil? then
        require "omokon/sysenv"
        arch = SystemEnvironment.arch
      elsif not archs.include?(arch) then
        raise ArgumentError, "unknown architecture: #{arch}"
      end
      require "omokon/rpm"
      pkglist = []
      Dir.glob("#{placement}/#{arch}/#{name}-*.#{arch}.rpm").each do |fn|
        pkg = RPM::Package.open(fn)
        pkglist.push(fn) if pkg.name == name
      end
      pkglist
    end # def search_package(name, arch)

    def store(filename)
      
    end # def store(filename)

    def include?(name, version=nil, arch=nil)
      pkg = search_package(name, arch)
      if version then
        pkg = nil if pkg.version != version
      end
      not pkg.nil?
    end # def include?(name, version, arch)

    def initial_scan
      @archs = []
      Dir.foreach(@placement) do |entity|
        case entity
        when /^\./, "SOURCES", "SRPMS"
          # skip if dot file or SOURCES or SRPMS
          next
        else
          # skip not directory
          next unless File.directory?("#{@placement}/#{entity}")
          @archs.push entity
        end
      end
    end # def initial_scan
    protected :initial_scan

    DEFAULT_PLACEMENT = File.expand_path("~/PKGS")

    def init_placement(placement=nil)
      @placement = placement || DEFAULT_PLACEMENT
      if not File.exist?(@placement) then
        raise ArgumentError, "placement is not exist: #{@placement}"
      elsif not File.directory?(@placement) then
        raise ArgumentError, "placement is not directory: #{@placement}"
      end
      initial_scan
    end # def init_placement(placement=nil)
  end # class PackagePool

end # module OmoiKondara

###--
### Local Variables:
### mode: ruby
### ruby-indent-level: 2
### indent-tabs-mode: nil
### End:
###++
