require "test/unit"
require "stringio"
require "OmoiKondara3"

class TC_OmoiKondara_Getopt < Test::Unit::TestCase
  include OmoiKondara

  def setup
    @getopt1 = Getopt.new("-a -b -cfoobar -d ahi".split, "abc:d:0123456789")
  end

  def test_getopt
    a, b = false, false
    @getopt1.parse do |opt, arg|
      case opt
      when "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
        flunk("digits occured")
      when "a"
        a = true
      when "b"
        b = true
      when "c"
        assert_equal("foobar", arg)
      when "d"
        assert_equal("ahi", arg)
      end
    end
    assert(a)
    assert(b)
  end
end

class TC_OmoiKondara_MacroContext < Test::Unit::TestCase
  include OmoiKondara

  def setup
    @mc = MacroContext.new
  end

  def test_length
    assert_equal(0, @mc.length)
  end

  def test_define
    assert_raises(MacroContext::IllegalMacroError) do
      @mc.define("123hoge fuga")
    end
    assert_raises(MacroContext::UnterminatedOptionError) do
      @mc.define("hoge(fuga")
    end
    assert_raises(MacroContext::UnterminatedOptionError) do
      @mc.define("hoge({fuga}")
    end
    assert_raises(MacroContext::EmptyBodyError) do
      @mc.define("hoge")
    end
    assert_raises(MacroContext::EmptyBodyError) do
      @mc.define("hoge()")
    end
    assert_raises(MacroContext::EmptyBodyError) do
      @mc.define("hoge(){}")
    end
    assert_raises(MacroContext::UnterminatedBodyError) do
      @mc.define("hoge{")
    end
    assert_raises(MacroContext::UnterminatedBodyError) do
      @mc.define("hoge(){")
    end

    assert_nothing_raised{ @mc.define("hoge fuga") }
    assert_equal("fuga", @mc.expand("%{hoge}"))
    assert_nothing_raised{ @mc.define("ahi() %{1}") }
    assert_equal("hoge1", @mc.expand("%ahi hoge1"))
    assert_equal("hoge2", @mc.expand("%{ahi:hoge2}"))
    assert_equal("afugab", @mc.expand("%{?hoge:a%{hoge}b}"))
    assert_equal(2, @mc.length)
  end
end

class TC_OmoiKondara_SpecParser < Test::Unit::TestCase
  include OmoiKondara

  def setup
    @spec1 = %Q[
%global momorel 1
Name: test
Version: 1.0
Release: %{momorel}m
License: GPL
Group: hoge
URL: http://hoge/
BuildRoot: %{_tmppath}/%{name}-%{version}-root
    ]
  end

  def test_parse
    source = StringIO.new(@spec1)
    parser = SpecParser.new(source)
    parser.parse(SpecParser::SOURCE       |
                 SpecParser::PREPROCESSED |
                 SpecParser::STRUCTURED) do |element|
      case element.pass
      when 0 then
        assert_equal(:line, element.type)
        case element.attr[:lineno]
        when 0 then
          assert_equal("%global momorel 1", element.attr[:line])
        when 3 then
          assert_equal("Release: %{momorel}m", element.attr[:line])
        when 7 then
          assert_equal("BuildRoot: %{_tmppath}/%{name}-%{version}-root",
                       element.attr[:line])
        end
      when 1 then
        assert_equal(:line, element.type)
        case element.attr[:lineno]
        when 0 then
          assert_equal("", element.attr[:line])
        when 3 then
          assert_equal("Release: 1m", element.attr[:line])
        when 7 then
          assert_equal("BuildRoot: %{_tmppath}/test-1.0-root",
                       element.attr[:line])
        end
      when 2 then
        case element.type
        when :build_restriction
          assert_equal("%{_tmppath}/test-1.0-root", element[:buildroot])
        when :package
          assert_equal(0, element[:index])
          assert_equal("test", element[:name])
          assert_equal("1.0", element[:version])
          assert_equal("1m", element[:release])
          assert_equal("GPL", element[:license])
          assert_equal("hoge", element[:group])
          assert_equal("http://hoge/", element[:url])
        when :prep, :build, :install, :clean, :check, :files, :changelog
          flunk("unexpected case: #{element.type}")
        end
      end
    end
  end
end

class TC_OmoiKondara_Version < Test::Unit::TestCase
  include OmoiKondara

  def test_vr
    assert_equal("1.1-2m", Version.new("1.1", "2m").vr)
    assert_equal("1.1-2m", Version.new("1.1", "2m", 4).vr)
    assert_equal("1.1", Version.new("1.1", nil, 4).vr)
  end

  def test_evr
    assert_equal("1.1-2m", Version.new("1.1", "2m").evr)
    assert_equal("4:1.1-2m", Version.new("1.1", "2m", 4).evr)
    assert_equal("4:1.1", Version.new("1.1", nil, 4).evr)
  end

  def test_cmp
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
    assert_equal( 0, Version.new("1.1") <=> Version.new("1.1"))
    assert_equal(-1, Version.new("1.1") <=> Version.new("1.2"))
    assert_equal( 1, Version.new("1.1") <=> Version.new("1.0"))
    assert_equal( 0, Version.new("1.1.1") <=> Version.new("1.1.1"))
    assert_equal(-1, Version.new("1.1.1") <=> Version.new("1.1.1.1"))
    assert_equal( 1, Version.new("1.1.1") <=> Version.new("1.1"))
    assert_equal(-1, Version.new("1.1a") <=> Version.new("1.1b"))
    assert_equal( 1, Version.new("1.1a") <=> Version.new("1.1"))

    #  (2) (self.v == other.v) ? -1 : (self.v <=> other.v)
    assert_equal(-1, Version.new("1.1") <=> Version.new("1.1", "1m"))
    assert_equal(-1, Version.new("1.1") <=> Version.new("1.2", "1m"))
    assert_equal( 1, Version.new("1.1") <=> Version.new("1.0", "1m"))
    assert_equal(-1, Version.new("1.1.1") <=> Version.new("1.1.1", "1m"))
    assert_equal(-1, Version.new("1.1.1") <=> Version.new("1.1.1.1", "1m"))
    assert_equal( 1, Version.new("1.1.1") <=> Version.new("1.1", "1m"))

    #  (3) (self.v == other.v) ?  1 : (self.v <=> other.v)
    assert_equal( 1, Version.new("1.1", "1m") <=> Version.new("1.1"))
    assert_equal(-1, Version.new("1.1", "1m") <=> Version.new("1.2"))
    assert_equal( 1, Version.new("1.1", "1m") <=> Version.new("1.0"))
    assert_equal( 1, Version.new("1.1.1", "1m") <=> Version.new("1.1.1"))
    assert_equal(-1, Version.new("1.1.1", "1m") <=> Version.new("1.1.1.1"))
    assert_equal( 1, Version.new("1.1.1", "1m") <=> Version.new("1.1"))

    #  (4) (self.v == other.v) ? (self.r <=> other.r) : (self.v <=> other.v)
    assert_equal( 0, Version.new("1.1",   "1m") <=> Version.new("1.1",     "1m"))
    assert_equal(-1, Version.new("1.1",   "1m") <=> Version.new("1.2",     "1m"))
    assert_equal( 1, Version.new("1.1",   "1m") <=> Version.new("1.0",     "1m"))
    assert_equal( 0, Version.new("1.1.1", "1m") <=> Version.new("1.1.1",   "1m"))
    assert_equal(-1, Version.new("1.1.1", "1m") <=> Version.new("1.1.1.1", "1m"))
    assert_equal( 1, Version.new("1.1.1", "1m") <=> Version.new("1.1",     "1m"))

    assert_equal( 0, Version.new("1.1", "1m") <=> Version.new("1.1", "1m"))
    assert_equal(-1, Version.new("1.1", "1m") <=> Version.new("1.1", "2m"))
    assert_equal( 1, Version.new("1.1", "1m") <=> Version.new("1.1", "0.20030807.1m"))
    assert_equal(-1, Version.new("1.1", "0.20030807.1m") <=> Version.new("1.1", "0.20030807.2m"))

    #  (5) -1
    #  (6) -1
    #  (7) -1
    #  (8) -1
    assert_equal(-1, Version.new("1.1", "1m") <=> Version.new("1.1", "1m", 1))
    assert_equal(-1, Version.new("1.1", "1m") <=> Version.new("1.2", "1m", 1))
    assert_equal(-1, Version.new("1.2", "1m") <=> Version.new("1.1", "1m", 1))
    assert_equal(-1, Version.new("1.1", "1m") <=> Version.new("1.1", "2m", 1))
    assert_equal(-1, Version.new("1.1", "2m") <=> Version.new("1.1", "1m", 1))

    #  (9)  1
    # (10)  1
    # (11)  1
    # (12)  1
    assert_equal(1, Version.new("1.1", "1m", 1) <=> Version.new("1.1", "1m"))
    assert_equal(1, Version.new("1.1", "1m", 1) <=> Version.new("1.2", "1m"))
    assert_equal(1, Version.new("1.2", "1m", 1) <=> Version.new("1.1", "1m"))
    assert_equal(1, Version.new("1.1", "1m", 1) <=> Version.new("1.1", "2m"))
    assert_equal(1, Version.new("1.1", "2m", 1) <=> Version.new("1.1", "1m"))

    # (13) (self.e == other.e) ? (1) : (self.e <=> other.e)
    assert_equal( 0, Version.new("1.1", nil, 1) <=> Version.new("1.1", nil, 1))
    assert_equal(-1, Version.new("1.1", nil, 1) <=> Version.new("1.2", nil, 1))
    assert_equal( 1, Version.new("1.1", nil, 1) <=> Version.new("1.0", nil, 1))
    assert_equal( 0, Version.new("1.1.1", nil, 1) <=> Version.new("1.1.1", nil, 1))
    assert_equal(-1, Version.new("1.1.1", nil, 1) <=> Version.new("1.1.1.1", nil, 1))
    assert_equal( 1, Version.new("1.1.1", nil, 1) <=> Version.new("1.1", nil, 1))
    assert_equal(-1, Version.new("1.1a", nil, 1) <=> Version.new("1.1b", nil, 1))
    assert_equal( 1, Version.new("1.1a", nil, 1) <=> Version.new("1.1", nil, 1))

    assert_equal( 0, Version.new("1.1", nil, 1) <=> Version.new("1.1", nil, 1))
    assert_equal(-1, Version.new("1.1", nil, 1) <=> Version.new("1.1", nil, 2))
    assert_equal( 1, Version.new("1.1", nil, 2) <=> Version.new("1.1", nil, 1))
    assert_equal(-1, Version.new("1.1", nil, 1) <=> Version.new("1.2", nil, 2))
    assert_equal(-1, Version.new("1.2", nil, 1) <=> Version.new("1.1", nil, 2))
    assert_equal( 1, Version.new("1.1", nil, 2) <=> Version.new("1.2", nil, 1))
    assert_equal( 1, Version.new("1.2", nil, 2) <=> Version.new("1.1", nil, 1))

    # (14) (self.e == other.e) ? (2) : (self.e <=> other.e)
    assert_equal(-1, Version.new("1.1", nil, 1) <=> Version.new("1.1", "1m", 1))
    assert_equal(-1, Version.new("1.1", nil, 1) <=> Version.new("1.2", "1m", 1))
    assert_equal( 1, Version.new("1.1", nil, 1) <=> Version.new("1.0", "1m", 1))
    assert_equal(-1, Version.new("1.1.1", nil, 1) <=> Version.new("1.1.1", "1m", 1))
    assert_equal(-1, Version.new("1.1.1", nil, 1) <=> Version.new("1.1.1.1", "1m", 1))
    assert_equal( 1, Version.new("1.1.1", nil, 1) <=> Version.new("1.1", "1m", 1))

    assert_equal( 1, Version.new("1.1", nil, 2) <=> Version.new("1.1", "1m", 1))
    assert_equal( 1, Version.new("1.1", nil, 2) <=> Version.new("1.2", "1m", 1))
    assert_equal(-1, Version.new("1.1", nil, 1) <=> Version.new("1.0", "1m", 2))
    assert_equal( 1, Version.new("1.1.1", nil, 2) <=> Version.new("1.1.1", "1m", 1))
    assert_equal( 1, Version.new("1.1.1", nil, 2) <=> Version.new("1.1.1.1", "1m", 1))
    assert_equal(-1, Version.new("1.1.1", nil, 1) <=> Version.new("1.1", "1m", 2))

    # (15) (self.e == other.e) ? (3) : (self.e <=> other.e)
    assert_equal( 1, Version.new("1.1", "1m", 1) <=> Version.new("1.1", nil, 1))
    assert_equal(-1, Version.new("1.1", "1m", 1) <=> Version.new("1.2", nil, 1))
    assert_equal( 1, Version.new("1.1", "1m", 1) <=> Version.new("1.0", nil, 1))
    assert_equal( 1, Version.new("1.1.1", "1m", 1) <=> Version.new("1.1.1", nil, 1))
    assert_equal(-1, Version.new("1.1.1", "1m", 1) <=> Version.new("1.1.1.1", nil, 1))
    assert_equal( 1, Version.new("1.1.1", "1m", 1) <=> Version.new("1.1", nil, 1))

    assert_equal(-1, Version.new("1.1", "1m", 1) <=> Version.new("1.1", nil, 2))
    assert_equal( 1, Version.new("1.1", "1m", 2) <=> Version.new("1.2", nil, 1))
    assert_equal(-1, Version.new("1.1", "1m", 1) <=> Version.new("1.0", nil, 2))
    assert_equal(-1, Version.new("1.1.1", "1m", 1) <=> Version.new("1.1.1", nil, 2))
    assert_equal( 1, Version.new("1.1.1", "1m", 2) <=> Version.new("1.1.1.1", nil, 1))
    assert_equal(-1, Version.new("1.1.1", "1m", 1) <=> Version.new("1.1", nil, 2))

    # (16) (self.e == other.e) ? (4) : (self.e <=> other.e)
    assert_equal( 0, Version.new("1.1", "1m", 1) <=> Version.new("1.1", "1m", 1))
    assert_equal(-1, Version.new("1.1", "1m", 1) <=> Version.new("1.2", "1m", 1))
    assert_equal( 1, Version.new("1.1", "1m", 1) <=> Version.new("1.0", "1m", 1))
    assert_equal( 0, Version.new("1.1.1", "1m", 1) <=> Version.new("1.1.1", "1m", 1))
    assert_equal(-1, Version.new("1.1.1", "1m", 1) <=> Version.new("1.1.1.1", "1m", 1))
    assert_equal( 1, Version.new("1.1.1", "1m", 1) <=> Version.new("1.1", "1m", 1))

    assert_equal( 0, Version.new("1.1", "1m", 1) <=> Version.new("1.1", "1m", 1))
    assert_equal(-1, Version.new("1.1", "1m", 1) <=> Version.new("1.1", "2m", 1))
    assert_equal( 1, Version.new("1.1", "1m", 1) <=> Version.new("1.1", "0.20030807.1m", 1))
    assert_equal(-1, Version.new("1.1", "0.20030807.1m", 1) <=> Version.new("1.1", "0.20030807.2m", 1))

    assert_equal(-1, Version.new("1.1", "1m", 1) <=> Version.new("1.1", "1m", 2))
    assert_equal( 1, Version.new("1.1", "1m", 2) <=> Version.new("1.1", "1m", 1))
    assert_equal( 1, Version.new("1.1", "1m", 2) <=> Version.new("1.2", "1m", 1))
    assert_equal(-1, Version.new("1.1", "1m", 1) <=> Version.new("1.0", "1m", 2))
    assert_equal(-1, Version.new("1.1.1", "1m", 1) <=> Version.new("1.1.1", "1m", 2))
    assert_equal( 1, Version.new("1.1.1", "1m", 2) <=> Version.new("1.1.1", "1m", 1))
    assert_equal( 1, Version.new("1.1.1", "1m", 2) <=> Version.new("1.1.1.1", "1m", 1))
    assert_equal(-1, Version.new("1.1.1", "1m", 1) <=> Version.new("1.1", "1m", 2))

    assert_equal(-1, Version.new("1.1", "1m", 1) <=> Version.new("1.1", "1m", 2))
    assert_equal( 1, Version.new("1.1", "1m", 2) <=> Version.new("1.1", "1m", 1))
    assert_equal( 1, Version.new("1.1", "1m", 2) <=> Version.new("1.1", "2m", 1))
    assert_equal(-1, Version.new("1.1", "1m", 1) <=> Version.new("1.1", "0.20030807.1m", 2))
    assert_equal( 1, Version.new("1.1", "0.20030807.1m", 2) <=> Version.new("1.1", "0.20030807.2m", 1))
  end

  def test_parse
    assert_equal(Version.new("1.1a"), Version.parse("1.1a"))
    assert_equal(Version.new("1.1", "1m", 1), Version.parse("1:1.1-1m"))
    assert_equal(Version.new("1.1", "0.20030807m", 1), Version.parse("1:1.1-0.20030807m"))
    assert_equal(Version.new("1.1a", nil, 1), Version.parse("1:1.1a"))
  end
end

class TC_OmoiKondara_Dependency < Test::Unit::TestCase
  include OmoiKondara

  def test_new
    dep = Dependency.new("hoge", "==", "1.1-2m")
    assert_equal("hoge", dep.name)
    assert_equal("1.1", dep.version.v)
    assert_equal("2m", dep.version.r)
    assert_equal(:"==", dep.rel)

    dep = Dependency.new("hoge", "=", "1.1-2m")
    assert_equal("hoge", dep.name)
    assert_equal("1.1", dep.version.v)
    assert_equal("2m", dep.version.r)
    assert_equal(:"==", dep.rel)

    assert_raises(ArgumentError){ Dependency.new("hoge", "=") }
  end
end

class TC_OmoiKondara_Provide < Test::Unit::TestCase
  include OmoiKondara

  def setup
    @prov1 = Provide.new("hoge")
    @prov2 = Provide.new("hoge", "==", "1.1-2m")
    @prov3 = Provide.new("hoge", "<=", "1.1-2m")
    @prov4 = Provide.new("hoge", ">=", "1.1-2m")
  end

  def test_satisfy
    assert(@prov1 =~ Require.new("hoge"))
    assert(@prov1 =~ Require.new("hoge", "==", "1.1"))
    assert(@prov1 =~ Require.new("hoge", ">=", "1.1"))
    assert(@prov1 !~ Require.new("fuga"))

    assert(@prov2 =~ Require.new("hoge"))
    assert(@prov2 =~ Require.new("hoge", "==", "1.1"))
    assert(@prov2 =~ Require.new("hoge", ">=", "1.1"))
    assert(@prov2 !~ Require.new("hoge", "==", "1.2"))
    assert(@prov2 !~ Require.new("hoge", ">", "1.1"))
    assert(@prov2 !~ Require.new("fuga"))

    assert(@prov3 =~ Require.new("hoge"))
    assert(@prov3 =~ Require.new("hoge", "==", "1.1"))
    assert(@prov3 =~ Require.new("hoge", ">=", "1.1"))
    assert(@prov3 =~ Require.new("hoge", "<=", "2.0"))
    assert(@prov3 !~ Require.new("hoge", "==", "1.2"))
    assert(@prov3 !~ Require.new("fuga"))

    assert(@prov4 =~ Require.new("hoge"))
    assert(@prov4 =~ Require.new("hoge", "==", "1.1"))
    assert(@prov4 =~ Require.new("hoge", ">=", "1.1"))
    assert(@prov4 =~ Require.new("hoge", "<=", "2.0"))
    assert(@prov4 !~ Require.new("hoge", "==", "1.0"))
    assert(@prov4 !~ Require.new("fuga"))
  end
end

class TC_OmoiKondara_Package < Test::Unit::TestCase
  include OmoiKondara

  def setup
    @pkg_1 = Package.new("testpkg1", "1.0-1m", "Applications/Publishing")
    @req_1 = Require.new("hoge")
    @prov_1 = Provide.new("fuga")
  end

  def test_new
    begin
      assert_nothing_raised() do
        Package.new("fuga", "1.2-2m", "Development/Languages",
                    { :requires => [ @req_1 ],
                      :provides => [ @prov_1 ] })
      end
      assert_raises(TypeError) do
        Package.new("fuga", "1.2-2m", "Development/Languages",
                    { :requires => [ @req_1, @prov_1 ] })
      end
    end
  end
end

#class TC_OmoiKondara_Spec < Test::Unit::TestCase
#end

BEGIN { $LOAD_PATH.unshift(File.dirname(__FILE__)).uniq! }

### :nodoc:
### Local Varaibles:
### mode: ruby
### ruby-indent-level: 2
### indent-tabs-mode: nil
### End:
