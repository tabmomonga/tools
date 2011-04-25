#!/usr/bin/ruby -Ku
# -*- coding: utf-8 -*-

require 'rpm'
require 'optparse'

date   = Time.now.strftime('%a %b %d %Y')

if ARGV == nil || ARGV.size == 0
	program = $0.split('/')[-1]
	puts "Usage: #{program} [ -a, --address ADDRESS ] [ -m, --message MESSAGE ] [ -n, --name NAME ] {specfile|dir}..."
	exit 1
end

ARGV.options { |opt|
	opt.on('-a ADDRESS', '--address ADDRESS', String, 'E-mail address') { |v|
		@myaddr = v
	}

	opt.on('-m MESSAGE', '--message MESSAGE', String, 'message that is described in changelog') { |v|
		@message = v
	}

	opt.on('-n NAME', '--name NAME', String, 'Your Name') { |v|
		@myname = v
	}

	opt.parse!
}

if ! @myaddr
	puts "Need your E-mail address, define by -a or --address option"
	exit 1
end

if ! @message
	puts "Need message to put changelog, define -m or --message option"
	exit 1
end

if ! @myname
	puts "Need your name, define by -n or --name option"
	exit 1
end
 
if ARGV == nil || ARGV.size == 0
	program = $0.split('/')[-1]
	puts "Usage: #{program} [ -a, --address ADDRESS ] [ -m, --message MESSAGE ] [ -n, --name NAME ] {specfile|dir}..."
	exit 1
end

ARGV.each { |file| 
	if /\.spec$/ !~ file
		file = file.delete('/')
		if FileTest.exist?("#{file}/#{file}.spec")
			file = "#{file}/#{file}.spec"
		else
			next
		end
	end

	spec = RPM::Spec.open(file)

	@epoch = spec.packages[0].version.e

	@ver = spec.packages[0].version.v

	relarray = spec.packages[0].version.r.sub(/m\.mo[1-9]/,'').split('.')
	relarray[-1] = relarray[-1].to_i + 1
	@rel = relarray.join(".") + "m"

	File.open(file, 'r+') { |f|
		@newfile = ""
		f.each_line { |line|
			if line =~ /^%global\s+momorel/
				rel = line.split(/\s+/)[2].to_i
				rel += 1
				len = line.length - line.split(/\s+/)[2].length - 1
				line = line[0, len] + "#{rel}\n"
			end

			evr = if @epoch.nil? || @epoch.zero?
					"#{@ver}-#{@rel}"
                              else
                                	"#{@epoch}:#{@ver}-#{@rel}"
                              end

			changelog = <<-EOD
%changelog
* #{date} #{@myname} <#{@myaddr}>
- (#{evr})
- #{@message}
EOD

			if line =~ /^%changelog/i
				line.sub!(/^%changelog/i, "#{changelog}")
			end

			@newfile << line
		}
		f.rewind
		f.print @newfile
		f.flush
		f.truncate(f.pos)
	}
}
