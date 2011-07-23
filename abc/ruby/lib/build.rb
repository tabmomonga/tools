# -*- coding: utf-8 -*-
require 'lib/common.rb'

class Job

  def prepare_buildreqs
    result = MOMO_UNDEFINED
    debug("prepare_buildreqs #{specname}")

    
    sql ="SELECT capability,operator,version FROM buildreq_tbl, specfile_tbl WHERE owner==id AND #{specname}"
    db.execute(sql) {|req|
      next is_installed(req)
      

    }

    result = MOMO_SUCCESS
  ensure
    debug("prepare_buildreqs #{specname} returns #{result}")
    return result 
  end
end
