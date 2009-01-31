# lib/config.rb
#
# by Hiromasa YOSHIMOTO <y@momonga-linux.org>



OPTS[:verbose]=0
OPTS[:specdb_filename]   = ".specdb.db"
OPTS[:pkgdb_filename]    = ".pkgdb.db"
OPTS[:logdb_filename]    = ".logdb.db"

class MoConfig
  def MoConfig.parse_conf(configfile_list)
    configfile_list.each {|configfile|
      return unless File.exist?(configfile)
      
      File.open(configfile).each_line {|line|
        line.chomp!
        next  if line =~ /^#/ or line =~ /^$/
        s = line.split(/\s+/, 2)
        v = s.shift
        v.downcase!
        case v
        when "topdir"
          OPTS[:pkgdir] = File.expand_path(s[0])
        when "pkgdir"
          OPTS[:specdir] = File.expand_path(s[0])
        end
      }
    }
  end
  
  def MoConfig.get_arch_and_notfile
    arch = `uname -m`
    case arch
    when 'x86_64'
      notfile = 'NOT.x86_64'
      arch = 'x86_64'
    when /^i\d86$/
      notfile = 'NOT.ix86'
      arch = 'i686'
    when /^alpha/
      notfile = 'NOT.alpha'
      open('/proc/cpuinfo').readlines.each do |line|
        if line =~ /^cpu model\s*:\s*EV([0-9]).*$/ && $1 == '5'
          arch = 'alphaev5'
          break
        end
      end
    when 'mips'
      notfile = 'NOT.mips'
      open('/proc/cpuinfo').readlines.each do |line|
        if line =~ /^cpu model\s*:\s*R5900.*/
        arch = 'mipsel'
          break
        end
      end
    when /^ppc64/
      notfile = 'NOT.ppc64'
      arch = 'ppc64'
    when /^ppc/
      notfile = 'NOT.ppc'
      arch = 'ppc'
    when /^ia64/
      notfile = 'NOT.ia64'
      arch = 'ia64'
    else
      STDERR.puts %Q(WARNING: unsupported architecture #{arch})
    end
    
    return arch, notfile
  end

end

MoConfig.parse_conf([".OmoiKondara"])

OPTS[:arch], OPTS[:notfile] = MoConfig.get_arch_and_notfile

OPTS[:archdir_list] = [ OPTS[:arch], "noarch" ]

OPTS[:pkgdir_list] = []
Dir.glob("#{OPTS[:pkgdir]}*") {|pkgdir|
  OPTS[:archdir_list].each {|archdir|
    OPTS[:pkgdir_list].push("#{pkgdir}/#{archdir}")
  }
}
