#!/usr/bin/env ruby
pack_list = `rpm -qa`.split(/\n/)

total = pack_list.size
mopack = pack_list.grep(/[mk]$/).size
printf "Your distribution's Momonga-do is %.2f%%!\n", mopack/total.to_f * 100.0
printf "(total = %d momonga-package = %d)\n", total, mopack


