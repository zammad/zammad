module Writeexcel

class Worksheet < BIFFWriter
  require 'writeexcel/helper'

  class Outline
    attr_accessor :row_level, :style, :below, :right
    attr_writer   :visible

    def initialize
      @row_level = 0
      @style     = 0
      @below     = 1
      @right     = 1
      @visible   = true
    end

    def visible?
      !!@visible
    end
  end
end

end
