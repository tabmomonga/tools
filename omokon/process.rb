###--
### OmoiKondara
###
### Copyright (C) 2003 Momonga Project.
###
### $Id: process.rb,v 1.1 2003/05/06 18:11:59 muraken Exp $
###++

module OmoiKondara

  class PipedProcess

    def in
      @in[1]
    end # def in

    def out
      @out[0]
    end # def out

    def err
      @err[0]
    end # def err

    def wait
      if @pid then
        begin
          Process.waitpid(@pid)
          @status = $?
        ensure
          @in[1].close unless @in[1].closed?
          @out[0].close unless @out[0].closed?
          @err[0].close unless @err[0].closed?
          Logger.i.info("terminate process #{@pid} (exit code == #{@status})\n")
          @pid = nil
        end
      end
    end

    def fork
      @in = IO.pipe
      @out = IO.pipe
      @err = IO.pipe
      @pid = Process.fork do
	@in[1].close
	@out[0].close
	@err[0].close
	$stdin.reopen(@in[0])
	$stdout.reopen(@out[1])
	$stderr.reopen(@err[1])
        $defout = $stdout
	begin
	  status = yield
	ensure
	  @in[0].close
	  @out[1].close
	  @err[1].close
	  Process.exit!(status || 0)
	end
      end
      Logger.i.info("forking process (pid #{pid})\n")
      @in[0].close
      @out[1].close
      @err[1].close
    end # def fork

    attr_reader :pid
    attr_reader :status

    def initialize
      @pid = nil
      @status = nil
    end # def initialize
  end # class PipedProcess

  class SimpleProcess < PipedProcess
    def self.stream_observer(stream, timeout)
      Thread.new do
        if timeout then
          begin
            require "timeout"
            timeout(timeout) do
              while s = stream.gets do
                Logger.i.info(s)
              end
            end
          rescue TimeoutError
            Logger.i.info("process (pid #{pid}) timeout\n")
          end
        else
          while s = stream.gets do
            Logger.i.info(s)
          end
        end
      end
    end # def self.observe_stream(stream, timeout)

    def fork
      begin
        super
        thrd_out = SimpleProcess.stream_observer(out, @timeout)
        thrd_err = SimpleProcess.stream_observer(err, @timeout)
        thrd_out.join
        thrd_err.join
      ensure
        wait
      end
    end # def fork

    def initialize(timeout=nil)
      @timeout = timeout
    end # def initialize(timeout=nil)
  end # class SimpleProcess

  class Executer < SimpleProcess
    attr_reader :cmdline

    def exec
      Logger.i.info(%Q[execute "#{cmdline}"\n])
      fork do
        rv = 0
        begin
          ::Kernel.exec(cmdline)
        rescue SystemCallError => e
          $stderr.print("exec failed on #{e.class.name}\n")
          rv = 1
        rescue => e
          $stderr.print("#{e.message}\n")
          $stderr.print("#{e.backtrace.join("\n")}\n")
          rv = 1
        end
        rv
      end
      wait
    end # def exec

    def initialize(cmdline, timeout=nil)
      super(timeout)
      @cmdline = cmdline
    end
  end # class Executer

end # module OmoiKondara

###--
### Local Variables:
### mode: ruby
### ruby-indent-level: 2
### indent-tabs-mode: nil
### End:
###++
