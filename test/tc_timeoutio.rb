#--
# $Id: tc_timeoutio.rb,v 1.1 2003/12/18 21:50:55 muraken Exp $
#++

require "test/unit"
require "timeoutio"
require "process"

class TC_TimeoutIO < Test::Unit::TestCase
  def test_timeout
    child = PipedProcess.fork do |proc|
      $stdin.read
      sleep 5
    end
    io = TimeoutIO.new(1, child.stdout)
    child.stdin.close
    assert_raises(TimeoutError) { io.gets }
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
