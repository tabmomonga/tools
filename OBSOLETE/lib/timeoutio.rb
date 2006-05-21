#--
# $Id: timeoutio.rb,v 1.1 2003/12/18 21:50:55 muraken Exp $
#++

require "delegate"
require "timeout"

# = TimeoutIO
#
# Author::  Kenta MURATA <muraken2 at nifty.com>
# Version:: 1.2
# License:: Ruby
#
# == Summary
#
# TimeoutIO is decorator to append timeout reading and writing
# capability for IO object.
#
# See also IO, Timeout.
#
# == Usage
#
#  open("|cmdline") do |io|
#    io = TimeoutIO.new(io, 10)  # timeout 10 sec.
#    begin
#      while io.gets do
#        ...
#      end
#    rescue TimeoutError
#      $stderr.puts("timeout!!")
#    end
#  end
#
#--
# = TODO
#
# * Implements dup and clone.
# * Supports asymmetric timeout periods.
# * Supports not IO but IO-like objects. (i.e. Zlib::GZipReader, etc.)
#++
class TimeoutIO < DelegateClass(IO)
  alias :timeout_try :timeout
  private :timeout_try

  # Timeout period time in second.
  attr_reader :timeout

  def getc
    c = nil
    timeout_try(self.timeout){ c = super }
    c
  end

  def gets(rs=nil)
    s = nil
    timeout_try(self.timeout){ s = super(rs) }
    s
  end

  def read(length=nil)
    s = nil
    timeout_try(self.timeout){ s = super(length) }
    s
  end

  def readchar
    c = nil
    timeout_try(self.timeout){ c = super }
    c
  end

  def readline(rs=nil)
    s = nil
    timeout_try(self.timeout){ s = super(rs) }
    s
  end

  def readlines(rs=nil)
    a = nil
    timeout_try(self.timeout){ a = super(rs) }
    a
  end

  def sysread(length)
    s = nil
    timeout_try(self.timeout){ s = super(length) }
    s
  end

  def each(rs=nil)
    while s = gets(rs) do
      yield(s)
    end
    self
  end

  alias :each_line :each

  def each_byte
    while c = getc do
      yield(c)
    end
    self
  end

  def write(str)
    timeout_try(self.timeout) { super }
  end

  def syswrite(string)
    timeout_try(self.timeout) { super }
  end

  def fsync
    timeout_try(self.timeout){ super }
    0
  end

  def to_io
    self
  end

  # Creates decorator for _io_ instance with _timeout_ for timeout
  # period time.
  def initialize(timeout, io)
    super(io)
    @timeout = timeout
  end
end

###--
### Local Varaibles:
### mode: ruby
### ruby-indent-level: 2
### indent-tabs-mode: nil
### End:
###++
