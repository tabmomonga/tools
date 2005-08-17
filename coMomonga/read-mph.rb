#!/usr/bin/ruby

# Usage:
# read-mph.rb <request_pkg> <mph file path> <format>

request_pkg = ARGV[0].split(" ")
arch = ["i686","noarch"]
path = ARGV[1]
format = ARGV[2].to_s

@pkg_hash = {}

# mphFilenamePackage
def readMph(path,arch)
  pkg_tmp ={}

  File.read("#{path}/#{arch}.mph").each do |line|

    if line =~ /^Filename:/:
      pkg_tmp["Filename"] = line.to_s.split(" ")[1]
    end

    if line =~ /^Package:/:
      # nil
      if pkg_tmp.size > 0:
        pkg_tmp["arch"] = arch
        @pkg_hash[pkg_tmp["Package"]] = pkg_tmp
        pkg_tmp ={}
      end
      pkg_tmp["Package"] = line.to_s.split(" ")[1]
    end
  end
end

# mph
arch.each do |arc|
  readMph(path,arc)
end

# rpm
res = []
request_pkg.each do |package|
  pkg_dat = @pkg_hash[package] 
  unless pkg_dat == nil:
    res.push(pkg_dat)
  end
end

# 
res.each do | rpm |
  tmp = format.clone
  # #{arch}#{rpm}
  print tmp.gsub('#{arch}',rpm["arch"]).gsub('#{rpm}',rpm["Filename"]),"\n"
  # print tmp.gsub('#{arch}/',"").gsub('#{rpm}',rpm["Filename"]),"\n"
  # print tmp.gsub('#{arch}/',"").gsub('#{rpm}',rpm["Package"]),"\n"
end

