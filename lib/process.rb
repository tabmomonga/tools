#--
# $Id: process.rb,v 1.1 2003/12/18 21:50:55 muraken Exp $
#++

require "timeoutio"

# = ChildProcess
#
# Author::  Kenta MURATA <muraken2 at nifty.com>
# Version:: 1.0
# License:: Ruby
#
# == Summary
#
# Process#fork creates new native process and returns pid.
# ChildProcess object is encapsulating that pid and operation for
# process.
#
# == Usage
#
# Sample usage of ChildProcess with IO.pipe:
#
#  pipe = IO.pipe
#  child = ChildProcess.fork(pipe) do |pipe|
#    # child process context
#    pipe[0].clone
#    pipe[1].puts "ahi"
#    pipe[1].close
#  end
#  pipe[1].close
#  puts "> #{pipe[0].gets}"  # => "> ahi"
#  child.wait
class ChildProcess
  include Process

  # Returns the process ID.
  attr_reader :pid

  # Return the exit status. If process is alived, returns nil.
  attr_reader :status

  # Wait child process to finish.
  def wait
    @status = Process.waitpid2(self.pid).last
  end

  # Forks new native process and evaluate block with given arguments.
  def initialize(*args)
    @status = nil
    @pid = Process.fork do
      @pid = Process.pid
      yield(*args)
      exit!(0)
    end
  end

  class << self
    alias :fork :new

    # Executes the command
    #
    # See also Kernel#exec.
    def exec(cmdline)
      fork{ ::Kernel.exec(cmdline) }
    end
  end
end

# = PipedProcess
#
# Author::  Kenta MURATA <muraken2 at nifty.com>
# Version:: 1.0
# License:: Ruby
#
# == Summary
#
# PipedProcess object is have three pipes, stdin, stdout and stderr,
# to communicate between parent process and child process.
#
# == Usage
#
#  child = PipedProcess.fork do
#    $stdout.write("child process: #{$stdin.read}")
#  end
#  child.stdin.print("ahi")
#  child.stdin.close
#  puts(child.stdout.read)  # => "child process: ahi"
#  child.wait
class PipedProcess < ChildProcess

  # Accessor for stdin. This is readable for child and writable for
  # parent.
  attr_reader :stdin

  # Accessor for stdout. This is writable for child and readable for
  # parent.
  attr_reader :stdout

  # Accessor for stderr. This is writable for child and readable for
  # parent.
  attr_reader :stderr

  # Creates new native process with three pipes.
  def initialize(*args)
    stdin = IO.pipe
    stdout = IO.pipe
    stderr = IO.pipe
    super do |*args|
      stdin[1].close
      stdout[0].close
      stderr[0].close
      $stdin.reopen(stdin[0])
      $stdout.reopen(stdout[1])
      $stderr.reopen(stderr[1])
      @stdin = $stdin
      @stdout = $stdout
      @stderr = $stderr
      $defout = $stdout
      yield(*args)
    end
    stdin[0].close
    stdout[1].close
    stderr[1].close
    @stdin = stdin[1]
    @stdout = stdout[0]
    @stderr = stderr[0]
  end
end

# = TimeoutProcess
#
# Author::  Kenta MURATA <muraken2 at nifty.com>
# Version:: 1.0
# License:: Ruby
#
# == Summary
#
# TimeoutProcess is subclass of PipedProcess, but all pipe is
# decorated by TimeoutIO.
#
# See also TimeoutIO.
class TimeoutProcess < PipedProcess
  alias :timeout_try :timeout
  private :timeout_try

  # Timeout period time in second.
  attr_reader :timeout

  # Creates new native process with _timeout_ for timeout period time.
  def initialize(timeout, *args)
    @timeout = timeout
    super(*args)
    @stdout = TimeoutIO.new(timeout, @stdout)
    @stderr = TimeoutIO.new(timeout, @stderr)
  end
end

###--
### Local Varaibles:
### mode: ruby
### ruby-indent-level: 2
### indent-tabs-mode: nil
### End:
###++
