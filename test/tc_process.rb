#--
# $Id$
#++

require "test/unit"
require "process"

class TC_ChildProcess < Test::Unit::TestCase
  def test_fork
    pipe = IO.pipe
    child = ChildProcess.fork(pipe) do |pipe|
      pipe[1].close
      pid = pipe[0].read.to_i
      pipe[0].close
      exit!(Process.pid - pid)
    end
    pipe[0].close
    assert_nil(child.status)
    assert_not_equal(Process.pid, child.pid)
    pipe[1].print "#{child.pid}"
    pipe[1].close
    child.wait
    assert_not_nil(child.status)
    assert_equal(0, child.status)
  end
end

class TC_PipedProcess < Test::Unit::TestCase
  def test_pipe
    child = PipedProcess.fork do
      $stdout.write($stdin.read)
    end
    child.stdin.print "OmoiKondara"
    child.stdin.close
    str = child.stdout.read
    child.wait
    assert_equal("OmoiKondara", str)
  end
end

class TC_TimeoutProcess < Test::Unit::TestCase
  def test_timeout
    child = TimeoutProcess.fork(1) do |proc|
      $stdin.read
      sleep 5
    end
    child.stdin.close
    assert_raises(TimeoutError) { child.stdout.gets }
    child.wait
  end
end

###--
### Local Varaibles:
### mode: ruby
### ruby-indent-level: 2
### indent-tabs-mode: nil
### End:
###++
