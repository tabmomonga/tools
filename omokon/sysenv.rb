###--
### OmoiKondara
###
### Copyright (C) 2003 Momonga Project.
###
### $Id$
###++

module OmoiKondara

  ## Methods group to get more system environment information.
  ##
  module SystemEnvironment
    GETCONF = "/usr/bin/getconf"
    CPUINFO = "/proc/cpuinfo"

    def self.getconf(name)
      `#{GETCONF} #{name} 2>/dev/null`.chomp
    end # def self.getconf(name)

    ## Returns processor count.
    ##
    def self.processor_count
      if @@nprocessors.nil? then
        @@nprocessors = getconf("_NPROCESSORS_ONLN").to_i
      end
      @@nprocessors
    end # def self.processor_count
    @@nprocessors = nil

    ## Returns /proc/cpuinfo contents converted to hash array.
    ##
    def self.cpuinfo
      if @@cpuinfo.nil? then
        @@cpuinfo = []
        i = nil
        IO.foreach(CPUINFO) do |line|
          next if line =~ /^\s*$/
          key, val = /^(.+?)\s*:\s*(.+)$/.match(line)[1,2]
          case key
          when "processor"
            i = val.to_i
            @@cpuinfo[i] = {}
          when "flags"
            @@cpuinfo[i][key] = val.split(/\s/)
          else
            @@cpuinfo[i][key] = val
          end
        end
      end
      @@cpuinfo
    end
    @@cpuinfo = nil

    ## Returns architecture name.
    ##
    def self.architecture
      if @@arch.nil? then
        @@arch = `uname -m`
        case @@arch
        when /i.86/
          @@arch = "i586"

        when "alpha"
          if cpuinfo["cpu model"] and
              /EV([0-9])/.match(cpuinfo["cpu model"])[1] == "5" then
            @@arch = "alphaev5"
          end

        when "mips"
          if cpuinfo["cpu model"] and cpuinfo["cpu model"] =~ /R59000/ then
            @@arch = "mipsel"
          end
        end
      end
      @@arch
    end # def self.architecture
    class << self
      alias_method :arch, :architecture
    end
    @@arch = nil

  end # module SystemEnvironment

end # module OmoiKondara

###--
### Local Variables:
### mode: ruby
### ruby-indent-level: 2
### indent-tabs-mode: nil
### End:
###++
