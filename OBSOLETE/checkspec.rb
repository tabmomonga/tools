require 'ftools'
require 'find'
require 'rpmmodule'

ARCH = RUBY_PLATFORM.split('-')[0]

RPM.verbosity = RPM::MESS_VERBOSE

def pre(name)
  open("#{name}/rpmrc.checkspec", 'w') do |io|
    macrofiles = ''
    IO.foreach('rpmrc') do |line|
      unless line =~ /macrofiles/ then
	io.print line
      else
	macrofiles = line.chomp
      end
    end
    io.puts "#{macrofiles}#{Dir.pwd}/#{name}/rpmmacros.checkspec"
  end

  open("#{name}/rpmmacros.checkspec", 'w') do |io|
    io.puts "%_topdir #{Dir.pwd}/#{name}"
    io.puts "%_arch #{ARCH}"
    io.puts "%_arch #{ARCH}"
  end

  RPM.readrc "#{name}/rpmrc.checkspec"

  Dir.mkdir "#{name}/SOURCES"
  Dir.glob("#{name}/*").each do |filename|
    next  unless File.file? filename
    File.symlink filename, "#{name}/SOURCES/#{File.basename filename}"
  end
end

def clean(name)
  system "rm -rf #{name}/SOURCES"
  File.rm_f '#{name}/rpmrc.checkspec'
  File.rm_f '#{name}/rpmmacros.checkspec'
end

specs = Dir.glob('*/*.spec').sort.collect {|a| File.expand_path a }

maxlen = File.basename(specs.max {|a, b|
			 File.basename(a).length <=> File.basename(b).length
		       }).length

specs.each do |specfile|
  name = File.basename File.dirname specfile
  begin
    pre name

    spec = RPM::Spec.open specfile
    spec.buildrequires.select {|a| a.name =~ %r!^/! }.collect {|a| a.name }.sort.each do |r|
      puts format "%#{maxlen}s: #{r}", File.basename(specfile)
    end  if spec.buildrequires
    pmaxlen = spec.packages.max {|a, b| a.name.length <=> b.name.length}.name.length
    spec.packages.each do |pkg|
      pkg.requires.select {|a| a.name =~ %r!^/! }.collect {|a| a.name }.sort.each do |r|
	puts format "%#{maxlen}s: %#{pmaxlen}s: #{r}", File.basename(specfile), pkg.name
      end  if pkg.requires
    end  if spec.packages

    clean name
  rescue
    clean name
  end
end
