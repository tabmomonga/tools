###--
### OmoiKondara
###
### Copyright (C) 2003 Momonga Project.
###
### $Id: config.rb,v 1.6 2003/05/07 01:29:28 muraken Exp $
###++

require "omokon/rpm"

module OmoiKondara

  require "singleton"
  class Config
    include Singleton

    class << self
      alias_method :i, :instance
    end

    begin
      require "optparse"
      
      class OptionParser < ::OptionParser
        PROGRAM_NAME = File.basename($0).freeze
        BANNER = "usage: #{PROGRAM_NAME} [OPTIONS] [name...]".freeze

        attr_reader :argv

        [ :ignore_noarch,
          :force,
          :group_check,
          :main_only,
          :nonfree,
          :script_mode,
          :scanpackages,
          :verbose,
          :debug_build,
          :mirror_first,
          :enable_ccache,
          :enable_distcc ].each do |ident|
          self.class_eval %Q{
            def #{ident}?
              @#{ident}
            end
          }
        end

        attr_reader :dependencies
        attr_reader :rpmopt
        attr_reader :build_arch
        attr_reader :jobs

        def set_default
          @ignore_noarch = false
          @dependencies  = nil
          @force_build   = false
          @group_check   = false
          @main_only     = false
          @nonfree       = false
          @rpmopt        = nil
          @script_mode   = false
          @scanpackages  = false
          @verbose       = false
          @debug_build   = false
          @mirror_first  = false
          @enable_ccache = true
          @enable_distcc = false
          @build_arch    = nil
          @jobs          = 1
        end # def set_default
        protected :set_default

        def register_options
          on("-a", "--archdep", "ignore noarch packages") {|@ignore_noarch|}
          on("-d", "--depend=DEPS", String, "specify dependencies") {|@dependencies|}
          on("-f", "--force", "force build") {|@force|}
          on("-g", "--groupcheck", "process group check only") {|@groupcheck|}
          on("-m", "--main", "build only main package") {|@main_only|}
          on("-n", "--nonfree", "also build Nonfree packages") {|@nonfree|}
          on("-N", "--nonstrict", "proceed by old behavior") {|@nostrict|}
          on("-r", "--rpmopt=RPMOPT", String, "specify option through to rpmbuild") {|@rpmopt|}
          on("-s", "--script", "script friendly output mode") {|@script|}
          on("-S", "--scanpackages", "execute mph-scanpackages") {|@scanpackages|}
          on("-v", "--verbose", "enable verbose output") {|@verbose|}
          on("-G", "--debug", "build for debugging") {|@debug_build|}
          on("-M", "--mirrorfirst", "download from mirror first") {|@mirror_first|}
          on("-C", "--noccache", "cancel ccache") {|@cancel_ccache|}
          on("-D", "--distcc", "enable distcc") {|@enable_distcc|}
          on("-j", "--jobs=N", Numeric, "the number of jobs for make") {|@jobs|}
        end # def register_options
        protected :register_options

        def initialize(argv)
          super(BANNER)
          program_name = PROGRAM_NAME

          on_tail("--help", "show this message") { print to_s; exit }
          register_options
          set_default
          @argv = argv.dup
          parse!(@argv)

          if RPM::DB.exist?("ccache") then
            @cancel_ccache = true
          end

          if RPM::DB.exist?("distcc") then
            @enable_ccache = false
          end
        end # def initialize(argv)
      end # class OptionParser

      attr_reader :options

      def parse_cmdline(argv)
        @options = OptionParser.new(argv)
      end # def parse_cmdline(argv)

      def method_missing(name, *args)
        options.__send__(name, *args)
      end # def method_missing(name, *args)

    rescue LoadError
    end

    FILES = [
      "./.OmoiKondara",
      "~/.OmoiKondara",
      "/etc/OmoiKondara.conf",
    ]

    attr_reader :topdir

    def on_topdir(*args)
      @topdir = args.first
    end # def on_topdir(*args)
    private :on_topdir

    attr_reader :mirrors

    def on_mirror(*args)
      @mirrors ||= []
      @mirrors += args
    end # def on_mirror(*args)
    private :on_mirror

    attr_reader :download

    def on_ftp_cmd(*args)
      @download = args.join(" ")
    end # def on_ftp_cmd(*args)
    private :on_ftp_cmd

    attr_reader :display

    def on_display(*args)
      @display = args.join(" ")
    end # def on_display(*args)
    private :on_display

    attr_reader :url_aliases

    def on_url_alias(*args)
      @url_aliases ||= {}
      re = Regexp.compile(args.shift)
      @url_aliases[re] = args.first
    end # def on_url_alias(*args)
    private :on_url_alias

    attr_reader :distcc_hosts

    def on_distcc_host(*args)
      @distcc_hosts ||= []
      if not @distcc_hosts.include?(args.first) then
        @distcc_hosts.push args.first
      end
    end # def on_distcc_host(*args)
    private :on_distcc_host

    def distcc_verbose?
      @distcc_verbose
    end

    def on_distcc_verbose(*args)
      @distcc_verbose = true
    end # def on_distcc_verbose(*args)
    private :on_distcc_verbose

    def build_architecture
      require "omokon/sysenv"
      options.build_arch || SystemEnvironment.arch
    end # def build_architecture

    def initialize
      FILES.each do |filename|
        filename = File.expand_path(filename)
        next unless File.file?(filename)
        IO.foreach(filename) do |line|
          next if line =~ /^#.*$|^$/
          name, *ary = line.split
          begin
            __send__("on_" + name.downcase, *ary)
          rescue NameError => e
#            Logger.instance.
#              warning("unknown configuration keyword `#{name}' in #{filename}\n")
          end
        end # IO.foreach(filename) do |line|
      end # FILES.each do |file|
    end # def initialize
  end # class Config

end # module OmoiKondara

###--
### Local Variables:
### mode: ruby
### ruby-indent-level: 2
### indent-tabs-mode: nil
### End:
###++
