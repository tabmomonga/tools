#!/usr/bin/env ruby
# To prepare for rpm[build] -bb or -ba
# Fetch source files and patch files from the net if necessary

if ARGV.length == 0 then
  print "Usage: #{$0} specfile_directory [...]\n"
  exit
end

WGET = "wget -c --passive-ftp"

# find SOURCES dir
MACROPATH = ['/usr/lib/rpm/macros',
       '/usr/lib/rpm/redhat/macros',
       '/etc/rpm/macros',
       '~/.rpmmacros']

top_dir = nil
MACROPATH.each do |p|
  pass = File.expand_path(p)
  if FileTest.file?(pass)
    open(pass) do |f|
      f.each_line do |line|
	if line =~ /^%_topdir\s+(.*)/
	  top_dir = $1
	end
      end
    end
  end
end
SRCDIR = top_dir + "/SOURCES"
if top_dir.nil? or not FileTest.directory?(SRCDIR)
  print "SOURCES directory not found\n"
  exit
end

debug_mode = false
while arg = ARGV.shift
  if arg == '-d'
    debug_mode = true 
    next
  end
  spec_dir = File.expand_path(arg)
  if not FileTest.directory?(spec_dir)
    printf "%s is not a directory, skip...\n", spec_dir
    next
  end
  dirname = File.basename(spec_dir)
  spec = File.expand_path(spec_dir + "/" + dirname + ".spec")
  if not FileTest.file?(spec)
    printf "spec file %s is not found, skip...\n", spec
    next
  end

  src = {}
  nosrc = []
  pat = {}
  nopat = []
  macros = {}

  open(spec) do |f|
    f.each_line do |line|
      if line =~ /^\s*source(\d*)\s*:\s*(\S+)/i or
	     line =~ /^\s*patch(\d*)\s*:\s*(\S+)/i
	uri = $2
	n = $1
	n = "0" if $1 == ""
	if line =~ /^\s*source(\d*)\s*:/i
	  src[n] = uri 
	else
	  pat[n] = uri
	end
      elsif line =~ /^\s*%NoSource\s+(\d+)\s+(\S+)\s+\S+$/
	nosrc.push $1
	src[$1] = $2
      elsif line =~ /^\s*%NoPatch\s+(\d+)\s+(\S+)\s+\S+$/
	nopat.push $1
	pat[$1] = $2
      elsif line =~ /^\s*nosource\s*:\s*(.*)/i or
	        line =~ /^\s*nopatch\s*:\s*(.*)/i
	ns = $1.split(' ')
	if line =~ /^\s*nosource\s*:/i # source
	  if ns.empty?
	    nosrc.push n
	  else
	    ns.each do |n0|
	      nosrc.push n0
	    end
	  end
	else # patch
	  if ns.empty?
	    nopat.push n
	  else
	    ns.each do |n0|
	      nopat.push n0
	    end
	  end
	end
      elsif line =~ /^%define\s+(\S+)\s+(\S+)\s*$/ or
	         line =~ /^%global\s+(\S+)\s+(\S+)\s*$/
	nam = $1
	v = $2
	if v !~ /%{\w+}/ 
	  macros[nam.upcase] = v
	else # macro expansion
	  macros[nam.upcase] = v.gsub(/%{(\w+)}/) {macros[$1.upcase]}
	end
      elsif line =~ /^(\S+)\s*:\s*(%{\w+}.*%{\w+}.*)\s*$/
	macros[$1.upcase] = $2.gsub(/%{(\w+)}/) {macros[$1.upcase]}
      elsif line =~ /^(\S+)\s*:\s*%{(.+)}\s*$/
	macros[$1.upcase] = macros[$2.upcase.strip]
      elsif line =~ /^(\S+)\s*:\s*%(\w+)\s*$/
	macros[$1.upcase] = macros[$2.upcase.strip]
      elsif line =~ /^(\S+)\s*:\s*(.+)\s*$/
	macros[$1.upcase] = $2.strip
      end
    end 

    # now get sources and patches in SRCDIR
    for type in ['src', 'pat']
      if type == 'src'
	h = src
	no = nosrc
      else
	h = pat
	no = nopat
      end

      h.each_key do |k|
	if not no.member?(k) # copy from the local directory
	  if h[k] =~ /%{\w+}/ # macro expansion
	    s = h[k].gsub(/%{(\w+)}/) {macros[$1.upcase]}
	  else
	    s = h[k]
	  end
	  cmd = sprintf "cp %s/%s %s", spec_dir, File.basename(s), SRCDIR
	  print cmd, "\n"
	  system cmd unless debug_mode
	else # get it from the Internet
	  savedir = Dir.pwd
	  begin
	    Dir.chdir SRCDIR
	    if h[k] =~ /\/\//
	      if h[k] =~ /%{\w+}/ # macro expansion
		s = h[k].gsub(/%{(\w+)}/) {macros[$1.upcase]}
	      else
		s = h[k]
	      end
	      cmd = sprintf "%s %s", WGET, s
	      print cmd, "\n"
	      system cmd unless debug_mode
	    end
	  ensure
	    Dir.chdir savedir
	  end
	end
      end
    end # for end
  end
end
