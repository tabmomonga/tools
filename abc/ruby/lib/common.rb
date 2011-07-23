# -*- coding: utf-8 -*-

def momo_abort(msg)
  STDERR.puts ""
  STDERR.puts "***** fatal error *****"
  STDERR.puts msg
  STDERR.puts ""
  STDERR.puts caller
  STDERR.puts ""
  STDERR.puts "please report this message to devel.ja@momonga-linux.org"
  STDERR.puts ""
  STDERR.puts "pwd: #{Dir.pwd}"
  STDERR.puts "command: #{$PROGRAM_NAME} #{ARGV.join(' ')}"
  STDERR.puts ""
  STDERR.puts "***********************"
  exit!(4)
end

def momo_assert
  #raise "Assertion failed !" unless yield
  momo_abort("Assertion failed!") unless yield
end

def rpm46?
  true
end


def is_installed(req)
  
end

class Job
  attr_reader :level, :parent
  attr_reader :specdir, :specname
  attr_reader :option
  attr_reader :valid
  attr_accessor :db

  private
  def backup_logfile(log_file)
    return  unless File.exist?(log_file)
    mtime = File.mtime(log_file)
    suffix = mtime.strftime('%Y%m%d%H%M%S')
    File.rename(log_file, "#{log_file}.#{suffix}")
    
    `#{@option[:compress_cmd]} '#{log_file}.#{suffix}'` if @option[:log_file_compress]
  rescue Exception => e
    momo_abort("exception: #{e}")
  end


  def debug(msg)
    return if @option[:verbose] < 1 
    @log.puts(msg) 
    STDOUT.puts(msg) if @option[:debug]
  end

  def log(msg)
    @log.puts(msg)
    STDOUT.puts(msg) if @option[:debug]
  end


  def exec_command(cmd)
    result = `#{cmd} 2>&1`
    @log.puts result
  end

  public
  def initialize(specfile, parent, opts = nil)
    @valid = false
    return if ! File.exist?(specfile)

    @option = opts.nil? ? OPTS : opts
    @parent = parent

    @level  = parent.nil? ? 0   : parent.level
    @db     = parent.nil? ? nil : parent.db

    @specdir = File.expand_path(File.dirname(specfile))
    @specname = File.basename(specfile, ".spec")

    file = "#{@specdir}/Build.log"
    backup_logfile(file)
    @log = File.open(file, "a+:utf-8")

    @valid = true
  end


end
