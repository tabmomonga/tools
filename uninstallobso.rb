#!/usr/bin/env ruby
#
# This program scans through your CVS working copy for the packages and
# lists binary packages names with the file OBSOLETE in its directory.
#
# Copyright 2003 Momonga Project <admin@momonga-linux.org>
#
# Permission is granted for use, copying, modification, distribution,
# and distribution of modified versions of this work as long as the
# above copyright notice is included.
#

flag_files = %w( OBSOLETE .SKIP )

$:.unshift(File.dirname($0))
require 'rpm'
require 'environment'

# check where we are... should we cd to the $PKGDIR?
if File.expand_path($PKGDIR) != File.expand_path(Dir.getwd)
	puts "Run in pkgs/ dir."
	exit 1
end

# for Ruby/RPM
RPM.readrc( './rpmrc' )
RPM.readrc( '/usr/lib/rpm/rpmrc' )
ARCH=RPM[%{_target_cpu}]

# scan through the directories
obso_pkgs = []
flag_files.each do |flag_file|
	Dir.glob( "*/#{flag_file}" ).each do |f|
		name = File.dirname( f )
		spec = RPM::Spec.open( "#{name}/#{name}.spec" )
		if spec.nil? then
			$stderr.puts "Error in reading #{name}/#{name}.spec"
			next
		end
		spec.packages.each do |pkg|
			system( "rpm -q #{pkg.name} > /dev/null" )
			if 0 == $? then	# rpm -q returns 0 if the package is installed
				obso_pkgs << pkg.name
			end
		end
	end
end

# show the result
unless obso_pkgs.empty? then
	puts 'OBSOLETEd packages are installed in your system, do the following if you want:'
	puts "sudo rpm -e #{obso_pkgs.join(' ')}"
else
	puts 'There is no OBSOLETEd packages installed in your system.'
end
