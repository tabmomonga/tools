### -*- mode: ruby; indent-tabs-mode: nil; -*-
###
### dependency classes for OmoiKondara
###
### Copyright (C) 2002 Kenta MURATA <muraken@kondara.org>.

require 'rpm'

module OmoiKondara

  class Dependency

    attr_reader :name
    attr_reader :version
    attr_reader :flags
    attr_reader :owner_name
    attr_reader :owner_version

    def lt?
      (flags & RPM::SENSE_LESS).nonzero?
    end # def lt?

    def gt?
      (flags & RPM::SENSE_GREATER).nonzero?
    end # def gt?

    def eq?
      (flags & RPM::SENSE_EQUAL).nonzero?
    end # def eq?

    def le?
      lt? && eq?
    end # def le?

    def ge?
      gt? && eq?
    end # def ge?

    def initialize(rpmdep, tname, tver)
      @name = rpmdep.name
      @version = rpmdep.version
      @flags = rpmdep.flags
      @owner_name = tname
      @owner_version = tver
    end # def initialize(rpmdep, tname, tver)

  end # class Dependency

  class Provide < Dependency
  end # class Provide < Dependency

  class Require < Dependency

    def pre?
      (flags & RPM::SENSE_PREREQ).nonzero?
    end # def pre?

  end # class Require < Dependency

  class Conflict < Dependency
  end # class Conflict < Dependency

  class Obsolete < Dependency
  end # class Obsolete < Dependency

end # module OmoiKondara

