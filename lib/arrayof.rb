#--
# $Id: arrayof.rb,v 1.1 2003/12/18 19:02:50 muraken Exp $
#++

require "weakref"

# = ArrayOf
#
# Author::  Kenta MURATA <muraken2 at nifty.com>
# Version:: 1.0
# License:: Ruby
#
# == Summary
#
# This is similar Array, but this have constraints about type of
# object (except NilClass).
#
# See:: http://www.notwork.org/~gotoken/mag/cmagazine/gokudo/9th/
# See:: http://www2a.biglobe.ne.jp/~seki/ruby/flyaway-1.0b1.tar.gz
class ArrayOf < Array
  @element_class = Object

  # Returns the class of elements.
  def self.element_class
    @element_class
  end

  # Set the class of elements.
  def self.set_element_class(klass)
    raise TypeError, "NilClass is not supported" if klass == NilClass
    @element_class = klass
    self
  end
  private_class_method :set_element_class

  # Returns a new array populate with the given objects.
  #
  #  ArrayOf(Integer)[1, 2, 3, 4, 5]    # => ArrayOf(Integer)[1, 2, 3, 4, 5]
  #  ArrayOf(Integer)[1, 2, [3, 4, 5]]  # => TypeError!!
  def self.[](*args)
    new.replace(args)
  end

  def self.inspect
    "ArrayOf(#{element_class})"
  end

  def self.to_s
    inspect
  end

  # Returns the class of elements.
  def element_class
    self.class.element_class
  end

  # Checks the class of argument objects.
  def type_check(*args)
    e = args.find{|i| i.nil? or not i.kind_of?(element_class) }
    if e then
      raise TypeError,
        "unexpected class of argument `#{e.inspect}'" +
        "(#{e.class} for #{element_class})"
    end
    true
  end
  private :type_check

  # Element Assignment
  #
  #  ary[anInteger] = anObject       # => anObject
  #  ary[start, length] = aSubArray  # => aSubArray
  #  ary[aRange] = aSubArray         # => aSubArray
  #
  # Sets the element at index _anInteger_, or replaces a subarray
  # starting at index _start_ and continuing for _length_ elements, or
  # replaces a subarray specified by _aRange_.  If _anInteger_ is
  # greater than the current capacity of the array, the array grows
  # automatically.  A negative _anInteger_ will count backward from
  # the end of the array.  Inserts elements if _length_ is zero.  If
  # _aSubArray_ is nil, deletes elements from _ary_.
  #
  # An IndexError is raised if a negative index points past the
  # beginning of the _ary_.
  #
  # If the class of _anObject_ is not kind of the _ary_.element_class,
  # raises TypeError.
  #
  # See also ArrayOf#push, ArrayOf#unshift.
  def []=(*args)
    if args.length == 2 then
      if args[0].is_a?(Range) then
        type_check(*args[1])
      else
        type_check(args[1])
      end
    elsif args.length == 3 then
      type_check(*args[2])
    end
    super
  end

  # Append
  #
  #  ary << anObject  # => ary
  #
  # Pushes the given _anObject_ on to the end of this array.  This
  # expression returns the array itself, so several appends may be
  # chained together.
  #
  # If the class of _anObject_ is not kind of the _ary_.element_class,
  # raises TypeError.
  #
  # See also ArrayOf#push.
  def <<(obj)
    type_check(obj)
    super
  end

  # Destructive collects
  #
  #  ary.collect!{|item| ... }
  #
  # Invokes block once for each element of _ary_, replacing the
  # element with the value returned by block.
  #
  # If value returned by block is not kind of _ary_.element_class,
  # raises TypeError.
  #
  #  ArrayOf[1, 2].collect!{|i| i+1    }  # => ArrayOf[2, 3]
  #  ArrayOf[1, 2].collect!{|i| i.to_f }  # => TypeError!!
  #
  # See also Array#collect.
  def collect!
    super{|item| type_check(item = yield(item)) and item }
  end

  # Synonym of collect!
  alias_method :map!, :collect!

  # Concatenate
  #
  #  ary.concat(anOtherArray)  # => ary
  #
  # Appends the elements in _anOtherArray_ to _ary_.
  #
  # If the element in _anOtherArray_ is not kind of
  # _ary_.element_class, raises TypeError.
  #
  #  ArrayOf[1, 2].concat([3, 4])  # => ArrayOf(Integer)[1, 2, 3, 4]
  def concat(other)
    type_check(*other)
    super
  end

  # Filling
  #
  #  ary.fill(anObject)                    # => ary
  #  ary.fill(anObject, start [, length])  # => ary
  #  ary.fill(anObject, aRange)            # => ary
  #
  # Sets the selected elements of _ary_ (which may be the entier
  # array) to _anObject_.  A _start_ of nil is equivalent to zero.  A
  # _length_ of nil is equivalent to _ary_.length.
  #
  # If _anObject_ is not kind of _ary_.element_class, raises
  # TypeError.
  #
  def fill(*args)
    if block_given? then
      return super{|i| type_check(i = yield(i)) and i }
    elsif 1 <= args.length and args.length <= 3 then
      type_check(args[0])
    end
    super
  end

  # Insertion
  #
  #  ary.insert(anIndex, anObject[, ...])  # => ary
  #
  # Inserts the _anObject_, ... at index _anIndex_ in _ary_.  This
  # operation is the same as following code:
  #
  #  ary[anIndex, 0] = [anObject, ...]
  #
  # If inserted objects are not kind of _ary_.element_class, raises
  # TypeError.
  #
  # See also ArrayOf#[]=.
  def insert(nth, *args)
    type_check(*args)
    super
  end

  # Appends the given argument(s) to the end of this array (as with a
  # stack).
  #
  # If given argument is not kind of element_class of this array,
  # raises TypeError.
  def push(*args)
    type_check(*args)
    super
  end

  # Replaces the contents of this array with the contents of given
  # array, truncating or expanding if necessary.
  #
  # If element in given array is not kind of element_class of this
  # array, raises TypeError.
  def replace(another)
    type_check(*another)
    super
  end

  # Prepends given objects to the front of this array, and shifts all
  # other elements up one.
  #
  # If given object is not kind of element_class of this array, raises
  # TypeError.
  def unshift(*args)
    type_check(*args)
    super
  end

  # Inspects instance.
  def inspect
    "#{self.class}#{super}"
  end

  def initialize(*args)
    if args.length == 2 then
      type_check(args[1])
    elsif args.length == 1 then
      if args[0].is_a?(Array) then
        type_check(*args[0])
      elsif args[0].is_a?(Fixnum) then
        if block_given? then
          return super{|i| type_check(i = yield(i)) and i }
        end
      end
    end
    super
  end
end

# = ArrayOfFactory
#
# Author::  Kenta MURATA <muraken2 at nifty.com>
# Version:: 1.0
# License:: Ruby
#
# == Summary
#
# ArrayOfFactory is factory of ArrayOf class.
#
# See:: http://www.notwork.org/~gotoken/mag/cmagazine/gokudo/9th/
# See:: http://www2a.biglobe.ne.jp/~seki/ruby/flyaway-1.0b1.tar.gz
module ArrayOfFactory
  # Map for element class to weak reference to ArrayOf(element class).
  CLASS_TO_REF_MAP = {}

  # Map for object id of ArrayOf(element class) to element class.
  ID_TO_CLASS_MAP = {}

  @@finalizer = lambda do |id|
    __old_status = Thread.critical
    begin
      Thread.critical = true
      klass = self::ID_TO_CLASS_MAP[id]
      if klass then
        self::CLASS_TO_REF_MAP.delete(klass)
        self::ID_TO_CLASS_MAP.delete(id)
      end
    ensure
      Thread.critical = __old_status
    end
  end

  ## The factory method for ArrayOf.
  def self.get_class(klass)
    __old_status = Thread.critical
    begin
      Thread.critical = true
      ref = self::CLASS_TO_REF_MAP[klass]
      begin
        return ref.__getobj__ if ref
      rescue
      end
      aryof = Class.new(ArrayOf).instance_eval{ set_element_class(klass) }
      ObjectSpace.define_finalizer(aryof, @@finalizer)
      ref = WeakRef.new(aryof)
      self::CLASS_TO_REF_MAP[klass] = ref
      self::ID_TO_CLASS_MAP[aryof.__id__] = klass
      return aryof
    ensure
      Thread.critical = __old_status
    end
  end
end

# Returns class of Array associated to class specified by _type_.
#
# If _type_ is NilClass, raises TypeError.
def ArrayOf(type)
  ArrayOfFactory.get_class(type)
end

###--
### Local Varaibles:
### mode: ruby
### ruby-indent-level: 2
### indent-tabs-mode: nil
### End:
###++
