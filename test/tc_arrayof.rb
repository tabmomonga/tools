#--
# $Id$
#++

require "test/unit"
require "arrayof"

class TC_ArrayOf < Test::Unit::TestCase
  class C1
  end

  class C2 < C1
  end

  class C3 < C1
  end

  C4 = Class.new(C1)

  def test_new
    assert_same(ArrayOf(Integer), ArrayOf(Integer))
    assert(ArrayOf(Integer) != ArrayOf(Fixnum))
  end

  def test_equality
    assert_equal(ArrayOf(C1), ArrayOf(C1))
    assert_not_equal(ArrayOf(C2), ArrayOf(C3))
    assert_equal(C1, ArrayOf(C1).element_class)
    assert_equal(C2, ArrayOf(C2).element_class)
    assert_equal(C3, ArrayOf(C3).element_class)
    assert_equal(C4, ArrayOf(C4).element_class)
  end

  def test_arrayof
    ary = ArrayOf(Integer)[1, 2, 3]
    assert_raises(TypeError){ ary.push(1.0) }
    assert_raises(TypeError){ ary.unshift(1.0) }
    assert_raises(TypeError){ ary[2] = 1.0 }
    assert_raises(TypeError){ ary[1..4] = [1, 1.0] }
    assert_raises(TypeError){ ary[1, 2] = [1, 1.0] }
    assert_raises(TypeError){ ary.replace([1, 1.0, "a"]) }
  end

  def test_gc
    fooid = nil
    lambda do
      foo = ArrayOf(Thread)
      bar = ArrayOf(Fixnum)

      fooid = foo.__id__
      GC.start
      foo = ArrayOf(Thread)
      assert_equal(fooid, foo.__id__)
    end.call

    GC.start
    assert_not_equal(fooid, ArrayOf(Thread).__id__)
  end
end

###--
### Local Varaibles:
### mode: ruby
### ruby-indent-level: 2
### indent-tabs-mode: nil
### End:
###++
