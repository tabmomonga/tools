### -*- mode: ruby; indent-tabs-mode: nil; -*-
###
### spec file class for OmoiKondara
###
### Copyright (C) 2002 Kenta MURATA <muraken@kondara.org>.

require 'rpm'
require 'omokon/common'
require 'omokon/package'

module OmoiKondara

  class Spec

    attr_reader :name
    attr_reader :packages
    attr_reader :sources
#    attr_reader :buildroot
#    attr_reader :buildsubdir
    attr_reader :buildarchs
    attr_reader :buildrequires
    attr_reader :buildconflicts
    attr_reader :data

    def initialize(rpmspec)
      @name = rpmspec.packages[0].name
      @packages = rpmspec.packages.collect {|rpmpkg| Package.new rpmpkg}
      @sources = rpmspec.sources
#      @buildroot = rpmspec.buildroot
#      @buildsubdir = rpmspec.buildsubdir
      @buildarchs = rpmspec.buildarchs
      if rpmspec.buildrequires then
        @buildrequires = rpmspec.buildrequires.
          collect {|dep| Require.new dep, @name, nil}
      else
        @buildrequires = []
      end
      if rpmspec.buildconflicts then
        @buildconflicts = rpmspec.buildconflicts.
          collect {|dep| Conflict.new dep, @name, nil}
      else
        @buildconflicts = []
      end
      @data = {}
    end # def initialize(rpmspec)

  end # def Spec

end # module OmoiKondara
