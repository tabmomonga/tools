#!/usr/bin/ruby
#
# upload the results of OmoiKondara2
#
# test version, 2nd
#
# by Hiromasa YOSHIMOTO <y@momonga-linux.org>
#

$:.unshift(File.dirname($0))

require 'optparse'
require 'set'
require 'net/https'
require 'uri'
Net::HTTP.version_1_2
require 'ecode.rb'


MAX_UPLOAD_UNIT = 100    # number of upload per request
CONFIG_VERSION = "0.3"   # config file version

UploadParams     = Set.new ["username", "password", 
                            "hostname", "arch", "branch", "version"]
EssentialParams  = Set.new ["report_url", "report_log"]
AdditionalParams = Set.new ["proxy"]

Config = Hash.new
Config[:verbose] = false

# ------------------------------------------------------
def min(a, b)
  return (a>b)?b:a
end

def debug(msg)
  if Config[:verbose] then
    STDERR.puts "#{msg}"
  end
end

def warning(msg)
  STDERR.puts "warning: #{msg}"
end

def error(msg)
  STDERR.puts "error: #{msg}"
end

def fatal(msg)
  abort("fatal: #{msg}")
end

def load_config(file)
  args = {}

  open(file) { |f|
    f.each_line { |line|
      next  if line =~ /^#.*$/ or line =~ /^$/
      line.chomp!
      s = line.split("=")
      v = s.shift
      v.downcase!

      if UploadParams.include?(v) or
          EssentialParams.include?(v) or
          AdditionalParams.include?(v) then
        args[v] = s.shift
      else
        warning(" '#{v}=#{s.shift}' in '#{file}' will be ignored.")
      end
    }
  }

  # check version
  if CONFIG_VERSION != "#{args['version']}" then
    fatal("your config file is too old, please update your #{file}")
    return nil
  end
  # check upload/essential params
  flag=true
  (UploadParams + EssentialParams).each {|v|
    r = args.include?(v)
    if !r then
      error( "parameter '#{v}' is not set" )
      flag=false
    end
  }
  if !flag then
    fatal("please check your configuration in #{file}")
    return nil
  end

  return args

rescue => e
  error("load_config failed     #{e}")
  return nil
end

def load_csv_log(file)
  log = []

  open(file) { |f|
    f.each_line { |line|
      next  if line =~ /^#.*$/ or line =~ /^$/
      line.chomp!
      s = line.split(",")

      pname=s[0]
      rev=Integer(s[1])
      sstr=s[2]

      status = get_status_number(sstr)

      #debug( "#{pname} #{rev} #{status} [#{sstr}]")

      log.push([pname, rev, status]) 
    }
  }
  return log
rescue => e
  error("load_csv_log failed     #{e}")
  return nil
end

# logs[] の offset番目 から num 個の log を upload する
#
# 返値は upload したlogの個数

def sub_upload(args, logs, offset, num)
  #debug("sub_upload(offset: #{offset}, num:#{num})")

  return -1 if nil == args['report_url']

  uri = URI.parse(args['report_url'])
  proxy_host = nil
  proxy_port = nil
  if args['proxy'] && args['proxy'].size > 0 then
    tmp = URI.parse(args['proxy'])
    proxy_host = tmp.host
    proxy_port = tmp.port
    #debug("proxy: #{proxy_host}, #{proxy_port}")
  end

  unsafe="[]%; &=-+"
  conn = Net::HTTP::Proxy(proxy_host, proxy_port).new(uri.host, uri.port)
  if "https" == uri.scheme then
    conn.use_ssl = true
    # !!FIXME!!  証明書の検証は行わない
    conn.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
  conn.start { |http|
    query = UploadParams.map{|k| "#{URI.encode(k,unsafe)}=#{URI.encode(args[k],unsafe)}" }.join("&")

    if Config[:verbose] then
      query += "&magic=1"
    end

    for i in offset..(offset+num-1) do
      query += "&p[]=#{URI.encode(logs[i][0],unsafe)}&r[]=#{logs[i][1]}&s[]=#{logs[i][2]}"
    end

    debug("query: #{query}")
    response = http.post(uri.path, query)
    
    puts response.body
  }
  return num

rescue => e 
  error("sun_upload failed     #{e}")
  return -1
end

# upload 
def upload(args, logs)    

  offset = 0

  while offset < logs.size
    num = min(logs.size - offset, MAX_UPLOAD_UNIT)
    num = sub_upload(args, logs, offset, num)
    if num < 0 then
      abort("sub_upload() failed");
      break;
    end
    offset += num
  end

  return offset == logs.size
rescue => e 
  error("upload     #{e}")
  return false
end


# ------------------------------------------------------

opts = OptionParser.new
opts.on("-d", "--debug"){|v| Config[:verbose] = true } 
opts.parse!(ARGV)

conffile = ARGV[0]
datafile = ARGV[1]

args = load_config(conffile)
if nil == args then
  abort("load_config() failed");
end


logs = load_csv_log(datafile)
if nil == logs then
  abort("load_csv_log() failed");
end

r = upload(args, logs)
if !r then
  abort("upload() failed");
end

exit 0
