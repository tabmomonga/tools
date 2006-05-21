### -*- mode: ruby; indent-tabs-mode: nil; -*-
###
### package class for OmoiKondara
###
### Copyright (C) 2002 Kenta MURATA <muraken@kondara.org>.

require 'rpm'
require 'omokon/dependency'

module OmoiKondara

  class Package

    attr_reader :name
    attr_reader :version
    attr_reader :summary
    attr_reader :group
    attr_reader :provides
    attr_reader :requires
    attr_reader :conflicts
    attr_reader :obsoletes

    def to_s
      "#{name}-#{version}"
    end # def to_s

    def initialize(rpmpkg)
      @name = rpmpkg.name
      @version = rpmpkg.version
      @summary = rpmpkg[RPM::TAG_SUMMARY]
      @group = rpmpkg[RPM::TAG_GROUP]
      @provides = rpmpkg.provides.collect{|dep| Provide.new dep, @name, @version}
      @requires = rpmpkg.requires.collect{|dep| Require.new dep, @name, @version}
      @conflicts = rpmpkg.conflicts.collect{|dep| Conflict.new dep, @name, @version}
      @obsoletes = rpmpkg.obsoletes.collect{|dep| Obsolete.new dep, @name, @version}
    end # def initialize(rpmpkg)

  end # class Package

end # module OmoiKondara
