###--
### OmoiKondara
###
### Copyright (C) 2003 Momonga Project.
###
### $Id: logger.rb,v 1.1 2003/05/06 18:11:59 muraken Exp $
###++

module OmoiKondara

  require "singleton"
  class Logger
    include Singleton

    class << self
      alias_method :i, :instance
    end

    DEBUG   = 0
    INFO    = 1
    WARN    = 2
    ERROR   = 3
    CAUTION = 4
    FATAL   = 5
    UNKNOWN = 6

    attr_accessor :threshold

    def set_verbose(flag=true)
      if flag then
	@threshold = INFO
      else
	@threshold = FATAL
      end
    end # def set_verbose(flag=true)

    def set_debug(flag=true)
      @debug = flag
    end # def set_debug(flag=true)

    def backup_file(filename)
      if File.file?(filename) then
        suffix = File.mtime(filename).strftime("%Y%m%d%H%M%S")
        File.rename(filename, "#{filename}.#{suffix}")
      end
    end # def backup_file(filename)
    private :backup_file

    def push_file(filename, append=false)
      backup_file(filename) unless append
      io = File.open(filename, append ? "a" : "w")
      io.sync = true
      @files.push(io)
    end # def push_file(filename, append=false)

    def pop_file
      @files.pop.close unless @files.empty?
    end # def pop_file

    PREFIX = [
      "DEBUG",
      "INFO",
      "WARNING",
      "ERROR",
      "CAUTION",
      "FATAL",
      "UNKNOWN",
    ]
    def log(level, *args)
      if level >= threshold then
	((level >= WARN) ? $stderr : $stdout).
          print("#{PREFIX[level]}: #{Process.pid}: ", *args)
      end
      if @files.last then
        @files.last.print("#{PREFIX[level]}: #{Process.pid}: ", *args)
      end
    end # def log(level, trace, *args)
    private :log

    def debug(*args)
      trace = caller(1).first.split(/:/)[1,2].join(":") + ": "
      log(DEBUG, trace, *args)
    end # def debug(*args)

    def info(*args)
      log(INFO, *args)
    end # def info(*args)

    def warning(*args)
      log(WARN, *args)
    end # def warning(*args)

    def error(*args)
      log(ERROR, *args)
    end # def error(*args)

    def caution(*args)
      log(CAUTION, *args)
    end # def error(*args)

    def fatal(*args)
      log(FATAL, *args)
    end # def fatal(*args)

    def unknown(*args)
      log(UNKNOWN, *args)
    end # def unknown(*args)

    def initialize
      set_verbose(false)
      set_debug(false)
      @files = []
    end # def initialize
  end # class Logger

end # module OmoiKondara

###--
### Local Variables:
### mode: ruby
### ruby-indent-level: 2
### indent-tabs-mode: nil
### End:
###++
