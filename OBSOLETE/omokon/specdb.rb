###--
### OmoiKondara
###
### Copyright (C) 2003 Momonga Project.
###
### $Id: specdb.rb,v 1.7 2003/05/07 01:34:56 muraken Exp $
###++

require "features/ruby18"
require "omokon/config"
require "omokon/logger"

class File
  def self.md5sum(filename)
    require "digest/md5"
    Digest::MD5.hexdigest(IO.readlines(filename).join)
  end
end

module OmoiKondara

  require "singleton"
  class SpecDB
    include Singleton

    class << self
      alias_method :i, :instance
    end

    attr_reader :specs
    attr_reader :packages

    def initialize
      @specs = {}
      @packages = {}
    end # def initialize

    def load_pstore(filename)
      if File.file?(filename) then
        require "pstore"
        PStore.new(filename).transaction {|db| @specs = db[:specs] }
      end
    end # def load_pstore(filename)
    protected :load_pstore

    def scan_specfiles(root=nil)
      root = root ? File.expand_path(root) : Dir.pwd
      @specs.each_key do |key|
        @specs.delete(key) unless File.file?("#{root}/#{key}/#{key}.spec")
      end
      Dir.foreach(root) do |entry|
        fullpath = "#{root}/#{entry}"
        next unless File.directory?(fullpath)
        next if entry =~ /^\./
        next unless File.file?("#{fullpath}/#{entry}.spec")
        if @specs[entry] and
            @specs[entry][:md5sum] == File.md5sum("#{fullpath}/#{entry}.spec") then
          next
        end
        spec = SpecDB.load_specfile(root, entry)
        if spec then
          spec[:md5sum] = File.md5sum("#{fullpath}/#{entry}.spec")
          @specs[entry] = spec
        end
      end
    end # def scan_specfiles(root)
    protected :scan_specfiles

    def save_pstore(filename)
      require "pstore"
      PStore.new(filename).transaction do |db|
        db[:specs] = @specs
        db.commit
      end
    end # def save_pstore(filename)
    protected :save_pstore

    def init_packages
      @packages = {}
      @specs.each do |name, spec|
        spec[:packages].each do |pkg|
          @packages[pkg[:name]] ||= []
          @packages[pkg[:name]].push(pkg)
          pkg[:provides].each do |prov|
            @packages[prov[:name]] ||= []
            @packages[prov[:name]].push(pkg)
          end
          pkg[:spec] = name
        end
      end
    end # def init_packages
    protected :init_packages

    def load(root, filename)
      Dir.chdir(root) do
        load_pstore(filename)
        scan_specfiles
        save_pstore(filename)
        init_packages
      end
    end # def load(root, filename)

    def self.load_specfile(root, name)
      filename = "#{root}/#{name}/#{name}.spec"
      if not File.file?(filename) then
        raise ArgumentError, "file not found: #{filename}"
      end

      spec = nil
      begin
        Logger.i.info("Loading #{filename}\n")
        require "omokon/process"
        proc = PipedProcess.new
        pipe_obj = IO.pipe
        proc.fork do
          begin
            require "omokon/rpm"
            RPM.setup_rpmrc(root, name) do
              spec = RPM::Spec.open(filename)
              spec = spec.convert
            end
          rescue
          ensure
            Marshal.dump(spec, pipe_obj[1])
            pipe_obj[1].close
          end
        end
        proc.in.reopen($stdin)
        pipe_obj[1].close

        require "timeout"
        thrd_out = Thread.new do
          begin
            timeout(5) do
              while s = proc.out.gets do
                Logger.i.info(s)
              end
            end
          rescue TimeoutError
          end
        end
        thrd_err = Thread.new do
          begin
            timeout(5) do
              while s = proc.err.gets do
                Logger.i.warning(s)
              end
            end
          rescue TimeoutError
          end
        end
        thrd_out.join
        thrd_err.join
        spec = Marshal.load(pipe_obj[0])
      ensure
        proc.wait
        pipe_obj[0].close
      end
      spec
    end # def self.load_specfile(root, name)

    DEFAULT_FILENAME = ".specdb"

    def self.load(root, filename=nil)
      specdb = SpecDB.instance
      specdb.load(root, filename || DEFAULT_FILENAME)
    end # def self.load
  end # class SpecDB

end # module OmoiKondara

###--
### Local Variables:
### mode: ruby
### ruby-indent-level: 2
### indent-tabs-mode: nil
### End:
###++
