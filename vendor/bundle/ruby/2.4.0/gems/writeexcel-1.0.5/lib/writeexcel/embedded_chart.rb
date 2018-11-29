module Writeexcel

class Worksheet < BIFFWriter
  require 'writeexcel/helper'

  class EmbeddedChart
    attr_reader :row, :col, :chart, :vertices

    def initialize(worksheet, row, col, chart, x_offset = 0, y_offset = 0, scale_x = 1, scale_y = 1)
      @worksheet = worksheet
      @row, @col, @chart, @x_offset, @y_offset, @scale_x, @scale_y =
        row, col, chart, x_offset, y_offset, scale_x, scale_y
      @width = default_width * scale_x
      @height = default_height * scale_y
      @vertices = calc_vertices
    end

    # Calculate the positions of comment object.
    def calc_vertices
      @worksheet.position_object( @col, @row, @x_offset, @y_offset, @width, @height)
    end

    private

    def default_width
      526
    end

    def default_height
      319
    end
  end
end

end
