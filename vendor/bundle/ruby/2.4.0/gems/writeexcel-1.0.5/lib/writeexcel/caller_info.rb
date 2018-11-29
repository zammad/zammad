# -*- coding: utf-8 -*-
module CallerInfo
  #
  # return stack trace info if defined?($debug).
  #
  def caller_info
    caller(3).collect { |info|
      file = File.expand_path(info.sub(/:(\d+)[^\d`]*(`([^']+)')?/, ''))
      { :file => file, :line => $1, :method => $3 }
    }.select { |info| info[:method] }  # delete if info[:method] == nil
  end
end
