# -*- ruby -*-
#
# by Hiromasa YOSHIMOTO <y@momonga-linux.org>
#

StatusCodes = {
  0 => "SUCCESS",

  1 => "ERR_SPEC_SYNTAX",
  2 => "ERR_LOOP",
  3 => "ERR_DOWNLOAD",
  4 => "ERR_BUILDDEP",
  5 => "ERR_CHECKSUM",
  6 => "ERR_RPM_PREP",
  7 => "ERR_RPM_BUILD",
  8 => "ERR_RPM_CHECK",
  9 => "ERR_RPM_INSTALL",
  10 => "ERR_RPM_CLEAN",
  
  9999 => "UNKNOWN"
}


def get_status_number(string)
  r = StatusCodes.index(string)
  return (nil!=r)?r:9999
end

def get_status_string(number)
  return StatusCodes.include?(number)?StatusCodes[number]:"UNKNOWN"
end

