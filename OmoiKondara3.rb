require "singleton"
require "stringio"

module OmoiKondara # :nodoc:
  # Getopt class represents option parser for MacroContext class.
  class Getopt
    class Error           < StandardError; end
    class InvalidOption   < Error;         end
    class MissingArgument < Error;         end

    attr_reader :argv
    attr_reader :optstring

    attr_accessor :opterr
    alias :opterr? :opterr

    attr_reader :ordering

    def set_error(type, message)
      @error = type
      @error_message = message

      @options = nil
      @rest_singles = nil
      @non_option_arguments = nil

      raise type, message
    end
    protected :set_error

    attr_reader :error
    alias :error? :error

    attr_reader :error_message

    def terminate
      return nil if @state == :terminated
      raise RuntimeError, "an error has occured" if error?

      @state = :terminated
      @non_option_arguments.reverse_each do |argument|
        argv.unshift(argument)
      end

      @options = nil
      @rest_singles = nil
      @non_option_arguments = nil

      self
    end

    def terminated?
      @state == :terminated
    end

    def get
      case @state
      when :yet then
        @state = :started
      when :terminated then
        return nil
      end

      if @rest_singles.length > 0 then
        argument = "-" + @rest_singles
      elsif argv.length == 0 then
        terminate
        return nil
      elsif ordering == :permute then
        while argv.length > 0 and argv[0] !~ /^-./ do
          @non_option_arguments.push(argv.shift)
        end
        if argv.length == 0 then
          terminate
          return nil
        end
        argument = argv.shift
      elsif ordering == :require_order then
        if argv[0] !~ /^-./ then
          terminate
          return nil
        end
        argument = argv.shift
      else
        argument = argv.shift
      end

      ## check special argumen `--'.
      if argument == "--" and @rest_singles.length == 0 then
        terminate
        return nil
      end

      optname, optarg = nil, ""
      if argument =~ /^-(.)/ then
        optname, @rest_singles = Regexp.last_match[1], Regexp.last_match.post_match
        if @options.include?(optname) then
          if @options[optname][:require_argument] then
            if @rest_singles.length > 0 then
              optarg = @rest_singles
              @rest_singles = ""
            elsif argv.length > 0 then
              optarg = argv.shift
            else
              # POSIX 1003.2 specifies the format of this message.
              set_error(MissingArgument, "option requires an argument -- #{optname}")
            end
          end
        else
          # Invalid option
          # POSIX 1003.2 specifies the format of this message.
          if @posixly_correct then
            set_error(InvalidOption, "illegal option -- #{optname}")
          else
            set_error(InvalidOption, "invalid option -- #{optname}")
          end
        end
      else
        # Non-option argument
        # Only :return_in_order falled into here.
        return "\1", argument
      end
      return optname, optarg
    end

    def parse
      loop do
        optname, optarg = get
        break if optname.nil?
        yield(optname, optarg)
      end
    end

    def initialize(argv, optstring)
      @argv = argv.to_ary.dup
      @opterr = true
      @colon = false
      @optstring = optstring.to_str.freeze
      @posixly_correct = ENV.include?("POSIXLY_CORRECT")
      @ordering = @posixly_correct ? :require_order : :permute
      if @optstring =~ /^[-+:]?/ then
        optstring = Regexp.last_match.post_match
        case Regexp.last_match[0]
        when "-" then
          @ordering = :return_in_order
        when "+" then
          @ordering = :require_order
        when ":" then
          @opterr = false
          @colon = true
        end
      end
      @options = {}
      optstring.scan(/(.)(:)?/) do |opt, arg|
        if not @options.has_key?(opt) then
          @options[opt] = {}
          @options[opt][:require_argument] = !arg.nil?
        end
      end
      @state = :yet
      @rest_singles = ""
      @non_option_arguments = []
      @error = nil
      @error_message = nil
    end
  end

  ## MacroContext class provides context to expand, define and
  ## undefine macros.
  class MacroContext
    class IllegalMacroError < ArgumentError; end
    class UnterminatedOptionError < ArgumentError; end
    class EmptyBodyError < ArgumentError; end
    class UnterminatedBodyError < ArgumentError; end

    module Pattern
      MACRO_NAME_PATTERN = %Q[([A-Za-z_][0-9A-Za-z_]{2,})].freeze
      MACRO_NAME_RE = Regexp.compile(MACRO_NAME_PATTERN, Regexp::EXTENDED).freeze

      MACRO_DEFINE_PATTERN = %Q[
        ^\\s*
        #{MACRO_NAME_PATTERN}       (?# 1: name)
        (?:\\(([^\\)]*)\\))?        (?# 2: opts)
        \\s*
        (?:
         \\{([^\\}]*)\\}            (?# 3: body)
        |
         (.*)                       (?# 4: body)
        )
        \\s*$].freeze
      MACRO_DEFINE_RE = Regexp.compile(MACRO_DEFINE_PATTERN, Regexp::EXTENDED).freeze

      MACRO_EXPAND_PATTERN = %Q[
        %(?:
          [\\!\\?]*
          \\-?
          (?:
            [A-Za-z_][A-Za-z0-9_]*.*
          |
            \\*{1,2}
          |
            \\#
          )
        |
          \\([^\\)]*\\)
        |
          \\{[\\!\\?]*
          (?:
            [^\\ \\}]*\\s*
          |
            [^\\ :]*\\s*:[^\\}]*
          )
          \\}
        |
          %
        )].freeze
      MACRO_EXPAND_RE = Regexp.compile(MACRO_EXPAND_PATTERN, Regexp::EXTENDED).freeze
    end

    Entry = Struct.new(:name, :option, :body, :level)

    RMIL_DEFAULT    = -15
    RMIL_MACROFILES = -13
    RMIL_RPMRC      = -11
    RMIL_CMDLINE    = -7
    RMIL_TARBALL    = -5
    RMIL_SPEC       = -3
    RMIL_OLDSPEC    = -1
    RMIL_GLOBAL     = 0

    def self.parse_macro(str)
      _, a, b, c, d = Pattern::MACRO_DEFINE_RE.match(str).to_a
      d.gsub!(/\\(.)/){ $1 } if d
      [a, b, c||d]
    end

    def self.parse_arguments(arguments)
      arguments.scan(/\S+/)
    end

    def length
      @table.length
    end

    def add_macro(name, option, body, level)
      @table[name] ||= []
      @table[name].unshift(Entry.new(name, option, body, level))
    end
    private :add_macro

    def define_internal(macro, level, expand)
      name, option, body = MacroContext.parse_macro(macro)
      if name.nil? then
        raise IllegalMacroError, "illegal macro `#{macro}'"
      elsif option.nil? and body =~ /^\(/ then
        raise UnterminatedOptionError, "unterminated option `#{macro}'"
      elsif body.nil? or body.length == 0 then
        raise EmptyBodyError, "empty body `#{macro}'"
      elsif body =~ /^\{/ then
        raise UnterminatedBodyError, "unterminated body `#{macro}'"
      end

      add_macro(name, option, body, level - 1)
    end
    private :define_internal

    def define(macro, level=nil)
      level = (level || 0).to_int
      macro = macro.to_str
      define_internal(macro, level, false)
    end

    def process_negate_and_exists(match)
      if match =~ /^%(\{?)([\!\?]*)/ then
        brace, a = Regexp.last_match.to_a[1, 2]
        negate, exists = false, false
        a.split("").each do |b|
          case b
          when "!" then
            negate = !negate
          when "?" then
            exists = !exists
          end
        end
        match = match.gsub(/^%#{brace}[\!\?]*/, "%#{brace}")
      end
      [match, negate, exists]
    end
    private :process_negate_and_exists

    def process_builtin_macros(name, arguments, negate)
      # XXX
    end
    private :process_builtin_macros

    def grab_arguments(entry, arguments, depth)
      add_macro("0", nil, entry.name, depth)
      add_macro("**", nil, arguments, depth)
      argv = MacroContext.parse_arguments(arguments)

      1.upto(9) do |i|
        break if argv.length <= i - 1
        add_macro(i.to_s, nil, argv[i-1], depth)
      end
      begin
        Getopt.new(argv, entry.option).parse do |opt, arg|
          
        end
      rescue
      end
    end
    private :grab_arguments

    def process_arguments(entry, arguments, depth)
      if arguments then
        grab_arguments(entry, arguments, depth)
      else
        add_macro("**", nil, "", depth)
        add_macro("*", nil, "", depth)
        add_macro("#", nil, "0", depth)
        add_macro("0", nil, entry.name, depth)
      end
    end
    private :process_arguments

    def free_arguments(entry, depth)
      @table.each do |name, entries|
        if entries[0].level >= depth then
          if entries.length == 1 then
            @table.delete(name)
          else
            entries.shift
          end
        end
      end
    end
    private :free_arguments

    def process_macros(name, arguments, negate, exists, depth)
      case name
      when "global" then
        define_internal(arguments, RMIL_GLOBAL, true)
      when "define" then
        define_internal(arguments, depth, false)
      when "undefine" then
        undefine_internal(arguments)
      when "echo" then
      when "warn" then
      when "error" then
      when "trace" then
      when "dump" then
      when "basename", "suffix", "expand", "verbose",
          "uncompress", "url2path", "u2p", "S", "P", "F" then
        process_builtin_macros(name, arguments, negate)
      else
        entry = @table[name] ? @table[name][0] : nil
        if name =~ /^\-/ then
          if not ((entry.nil? and not negate) or (entry and negate)) then
            if arguments then
              expand_internal(arguments, depth, false)
            elsif entry and entry.body then
              expand_internal(entry.body, depth, false)
            end
          end
        elsif exists then
          if not ((entry.nil? and not negate) or (entry and negate)) then
            if arguments then
              expand_internal(arguments, depth, false)
            elsif entry and entry.body then
              expand_internal(arguments, depth, false)
            end
          end
        elsif entry.nil? then
          nil ## warning?
        else
          process_arguments(entry, arguments, depth) if entry and entry.option
          if entry.body then
            rv = expand(entry.body)
            free_arguments(entry.option, depth)
            rv
          end
        end
      end
    end
    private :process_macros

    def expand_internal(str, depth)
      depth += 1
      str.gsub(Pattern::MACRO_EXPAND_RE) do |match|
        p match
        orig_match = match
        match, negate, exists = process_negate_and_exists(match)

        case match
        when /^%%/ then
          "%"
        when /^%\(([^\)]*)\)/ then
          `#{self.expand($1)}`
        when /^%([A-Za-z_][A-Za-z0-9_]{2,})\s*(.*)$/, # %hoge fuga
            /^%\{([^\s:]+)\s*:([^\}]*)\}/,            # %{hoge:fuga}
            /^%\{([^\s\}]+)\s*\}/,                    # %{hoge}
            /^%([A-Za-z_0-9])/,                       # %0, %1, ...
            /^%(\*{1,2}|\#)/ then                     # %*, %**, ...
          n, a = Regexp.last_match.to_a[1, 2]
          process_macros(n, a, negate, exists, depth) || orig_match
        end
      end
    end
    private :expand_internal

    def expand(str)
      expand_internal(str, 0)
    end

    def initialize
      @table = {}
    end
  end

  class SpecParser
    SOURCE       = 1
    PREPROCESSED = 2
    STRUCTURED   = 4

    attr_reader :macro_context

    def parse(pass=nil)
      pass ||= STRUCTURED

      lineno = 0
      while line = @source.gets do

        lineno += 1
      end
    end

    def initialize(source)
      if source.respond_to?(:gets) then
        @source = source
      elsif source.kind_of?(String) then
        @source = StringIO.new(source)
      else
        raise TypeError, "wrong type of argument (#{source.class} for IO)"
      end

      @macro_context = MacroContext.new
    end
  end

  ## Version class represents version number.
  class Version
    include Comparable

    attr_reader :v
    attr_reader :r
    attr_reader :e

    # Compare between two version instances.
    #
    # ------------------------------------------------
    # self.e  other.e  self.r  other.r    result
    # ------------------------------------------------
    #      F        F       F        F       (1)
    #      F        F       F        T       (2)
    #      F        F       T        F       (3)
    #      F        F       T        T       (4)
    # ------------------------------------------------
    #      F        T       F        F       (5)
    #      F        T       F        T       (6)
    #      F        T       T        F       (7)
    #      F        T       T        T       (8)
    # ------------------------------------------------
    #      T        F       F        F       (9)
    #      T        F       F        T      (10)
    #      T        F       T        F      (11)
    #      T        F       T        T      (12)
    # ------------------------------------------------
    #      T        T       F        F      (13)
    #      T        T       F        T      (14)
    #      T        T       T        F      (15)
    #      T        T       T        T      (16)
    # ------------------------------------------------
    #                            T: recv.nil? == true
    #                            F: recv.nil? == false
    # 
    #  (1) self.v <=> other.v
    #  (2) (self.v == other.v) ? -1 : (self.v <=> other.v)
    #  (3) (self.v == other.v) ?  1 : (self.v <=> other.v)
    #  (4) (self.v == other.v) ? (self.r <=> other.r) : (self.v <=> other.v)
    #  (5) -1
    #  (6) -1
    #  (7) -1
    #  (8) -1
    #  (9)  1
    # (10)  1
    # (11)  1
    # (12)  1
    # (13) (self.e == other.e) ? (1) : (self.e <=> other.e)
    # (14) (self.e == other.e) ? (2) : (self.e <=> other.e)
    # (15) (self.e == other.e) ? (3) : (self.e <=> other.e)
    # (16) (self.e == other.e) ? (4) : (self.e <=> other.e)
    def <=>(other)
      sense = 0
      if self.e and self.e > 0 and other.e and other.e > 0 then
        sense = self.e <=> other.e # (13), (14), (15), (16)
      elsif self.e and self.e > 0 then
        sense = 1 # (9), (10), (11), (12)
      elsif other.e and other.e > 0 then
        sense = -1 # (5), (6), (7), (8)
      end
      if sense == 0 then
        sense = self.v <=> other.v # (1), (2), (3), (4)
        if sense == 0 then
          if self.r and other.r then
            sense = self.r <=> other.r # (4)
          elsif self.r then
            sense = 1 # (3)
          elsif other.r then
            sense = -1 # (2)
          end
        end
      end
      sense
    end

    def vr
      v + (r ? "-#{r}" : "")
    end

    def evr
      (e ? "#{e}:" : "") + vr
    end

    alias_method :to_s, :evr

    def initialize(v, r=nil, e=nil)
      @v = v
      @r = r
      @e = (e ? e.to_i : nil)
    end

    DIGIT = "[0-9]"
    LETTER = "[0-9A-Za-z]"

    EVR_PATTERN = "
      (?:
        (#{DIGIT}+)                     (?# 1: epoch)
        \\:
      )?
      (
        #{LETTER}+
        (?:\\.#{LETTER}+)*
      )                                 (?# 2: version)
      (?:
        \\-
        (
          #{LETTER}+
          (?:\\.#{LETTER}+)*
        )                               (?# 3: release)
      )?
    "

    EVR = Regexp.new("^" + EVR_PATTERN + "$", Regexp::EXTENDED, "N").freeze

    def self.parse(str)
      e, v, r = EVR.match(str)[1,3]
      new(v, r, e ? e.to_i : nil)
    end
  end

  class Dependency # :nodoc:
    attr_reader :name
    attr_reader :version
    attr_reader :rel

    def =~(prov)
      prov.satisfy?(self)
    end

    def any_version?
      rel.nil?
    end

    def initialize(name, rel=nil, version=nil)
      @name = name.to_str
      if rel and version.nil? then
        raise ArgumentError, "version required"
      end
      @version, @rel = nil
      if rel then
        case rel
        when :"==", :"<", :"<=", :">", :">=" then
          @rel = rel
        when "==", "<", "<=", ">", ">=" then
          @rel = rel.intern
        when :"=", "=" then
          @rel = :"=="
        else
          raise ArgumentError, "invalid relation"
        end
        @version = (version === Version) ? version : Version.parse(version.to_str)
      end
    end
  end

  ## Provide represents a feature to provide on package.
  class Provide < Dependency # :nodoc:

    ## Returns true if satisfy the dependency. otherwise, returns
    ## false.
    ##
    ## @see	rpmdsCompare in the rpm-4.2.1/lib/rpmds.c
    def satisfy?(dep)
      if self.name != dep.name then
        return false
      end
      if self.any_version? or dep.any_version? then
        return true
      end
      sense = 0
      if self.version.e and dep.version.e then
        sense = self.version.e <=> dep.version.e
      elsif self.version.e and self.version.e > 0 then
        sense = 1
      elsif dep.version.e and dep.version.e > 0 then
        sense = -1
      end
      if sense == 0 then
        sense = self.version.v <=> dep.version.v
        if sense == 0 and self.version.r and dep.version.r then
          sense = self.version.r <=> dep.version.r
        end
      end
      if sense < 0 and
          ((self.rel == :">" or self.rel == :">=") or
           (dep.rel  == :"<" or dep.rel  == :"<=")) then
        return true
      elsif sense > 0 and
          ((self.rel == :"<" or self.rel == :"<=") or
           (dep.rel  == :">" or dep.rel  == :">=")) then
        return true
      elsif sense == 0 and
          (((self.rel == :"==" or self.rel == :"<=" or self.rel == :">=") and
            (dep.rel  == :"==" or dep.rel  == :"<=" or dep.rel  == :">=")) or
           ((self.rel == :"<"  or self.rel == :"<=") and
            (dep.rel  == :"<"  or dep.rel  == :"<=")) or
           ((self.rel == :">"  or self.rel == :">=") and
            (dep.rel  == :">"  or dep.rel  == :">="))) then
        return true
      end
      false
    end

    alias_method :"=~", :satisfy?
  end

  class Require < Dependency # :nodoc:
    # pre?
    def pre?
      @pre
    end

    def initialize(name, rel=nil, version=nil, pre=false)
      super(name, rel, version)
      @pre = pre
    end
  end

  Conflict = Class.new(Dependency) # :nodoc:
  Obsolete = Class.new(Dependency) # :nodoc:

  ## Package represents RPM package.
  class Package
    attr_reader :name
    attr_reader :version
    attr_reader :group
    attr_reader :provides
    attr_reader :requires
    attr_reader :obsoletes
    attr_reader :conflicts

    def initialize(name, version, group, deps={})
      @name = name
      @version = version
      @group = group
      @provides = OmoiKondara::ArrayOf(Provide)[*(deps[:provides] || []).to_ary]
      @requires = OmoiKondara::ArrayOf(Require)[*(deps[:requires] || []).to_ary]
      @obsoletes = OmoiKondara::ArrayOf(Obsolete)[*(deps[:obsoletes] || []).to_ary]
      @conflicts = OmoiKondara::ArrayOf(Conflict)[*(deps[:conflicts] || []).to_ary]
    end
  end

  ## Spec represents spec file.
  class Spec
    attr_reader :packages

    attr_reader :build_requires
    attr_reader :build_confclits

    def initialize(packages=[], restrictions={})
      @packages = OmoiKondara::ArrayOf(Package).new(packages.to_ary)
      @build_requires = OmoiKondara::ArrayOf(Require).
        new((restrictions[:build_requires] || []).to_ary)
      @build_conflicts = OmoiKondara::ArrayOf(Conflict).
        new((restrictions[:build_conflicts] || []).to_ary)
    end

    ## if Ruby/RPM is not available, use this method to parse spec
    ## file.
    def self.parse_nostrict(filename)
      ## XXX
    end
    private_class_method :parse_nostrict

    ## parsing spec file.
    def self.parse(filename)
      #if OmoiKondara.strict? then
      #else
      begin
        return parse_nostrict(filename)
      rescue SystemCallError => e
        raise e # XXX
      end
      #end
    end
  end

  ## Environment represents execution status of OmoiKondara
  class Environment

    def pool_directory
      @pooldir
    end

    def mirrors
      @mirrors.dup
    end

    def get_downloader(url, md5sum=nil)
      nil
    end

    def display
      @display.dup
    end

    def numjobs
      @numjobs
    end

    def verbose?
      @verbose
    end

    def debug_build?
      @debug_build
    end

    def script_mode?
      @script_mode
    end

    def quiet?
      @quiet
    end

    def strict?
      OmoiKondara.can_strict? and @strict
    end

    def rpm_option
      @rpm_option.dup
    end

    protected

    def read_conf(filename)
      conf = File.read(filename).untaint
      begin
        self.taint
        @mirrors.taint
        @url_aliases.taint
        t = Thread.new do
          $SAFE = 4
          self.instance_eval(conf, filename, 1)
        end
        t.join
      ensure
        @url_aliases.untaint
        @mirrors.untaint
        self.untaint
      end
    end

    private

    def set_pool_directory(str)
      @pooldir = str.dup.freeze
    end

    def add_mirror_url(ary)
      @mirrors += ary
    end

    def set_download_method(sym)
      @download_method = sym
      if sym == :block then
        @download_block = Proc.new
      end
    end

    def set_download_command(str)
      @download_command = str.dup
    end

    def set_display(str)
      @display = str.dup
    end

    def add_url_alias(hash)
      @url_aliases.update(hash)
    end

    def set_numjobs(int)
      @numjobs = int
    end

    def verbose_true
      @verbose = true
    end

    def verbose_false
      @verbose = false
    end

    def debug_build_true
      @debug_build = true
    end

    def debug_build_false
      @debug_build = false
    end

    def script_mode_true
      @script_mode = true
    end

    def script_mode_false
      @script_mode = false
    end

    def quiet_true
      @quiet = true
    end

    def quiet_false
      @quiet = false
    end

    def strict_true
      @strict = true
    end

    def strict_false
      @strict = false
    end

    def set_rpm_option(str)
      @rpm_option = str.dup
    end

    def initialize
      @pooldir = nil
      @mirrors = []
      @ftp_command = nil
      @display = nil
      @url_aliases = {}
      @numjobs = 1
      @verbose = false
      @debug_build = false
      @script_mode = false
      @quiet = false
      @strict = true
      @rpm_option = nil
    end
  end

  ## load ruby-rpm
  begin
    require "rpmmodule"
    module_eval{ def self.can_strict?; true; end }
  rescue LoadError
    module_eval{ def self.can_strict?; false; end }
  end
end

### :nodoc:
### Local Varaibles:
### mode: ruby
### ruby-indent-level: 2
### indent-tabs-mode: nil
### End:
