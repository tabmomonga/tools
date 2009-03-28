# lib/config.rb
#
# by Hiromasa YOSHIMOTO <y@momonga-linux.org>

# -----------------------------------------------------------------
# 定数
#

# MOMO_xxx      build(), install() などの返り値

MOMO_SUCCESS         =   0  #  ビルド成功
MOMO_SKIP            =   1  #  SKIP
MOMO_FAILURE         =   2  #  失敗
MOMO_OBSOLETE        =   3  #  OBSOLETE
MOMO_LOOP            =   4  #  依存関係にループがあったため失敗
MOMO_CHECKSUM        =   5  #  ファイルのチェックサムが間違っている
MOMO_NOTFOUND        =   6  #  ファイルのダウンロードに失敗した
MOMO_BUILDREQ        =   7  #  BuildReqしているパッケージが用意できなかった
MOMO_SIGINT          =   8  #  sigint で中断された
MOMO_NO_SUCH_PACKAGE =  10  # パッケージが存在しない
MOMO_UNDEFINED       = 999  # 内部エラー状態


# -----------------------------------------------------------------
# 設定
#
# OPTS[] 


OPTS[:verbose]           = 0
OPTS[:debug]             = false

OPTS[:specdb_filename]   = ".specdb.db"
OPTS[:pkgdb_filename]    = ".pkgdb.db"
OPTS[:logdb_filename]    = ".logdb.db"

OPTS[:log_file_compress] = true
OPTS[:compress_cmd]      = "bzip2 -f -9"

OPTS[:debug_build]       = false
OPTS[:enable_distcc]     = false
OPTS[:numjobs]           = 1

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
