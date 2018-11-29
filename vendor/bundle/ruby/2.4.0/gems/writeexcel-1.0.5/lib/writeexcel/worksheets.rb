class Workbook < BIFFWriter
  require 'writeexcel/properties'
  require 'writeexcel/helper'

  class Worksheets < Array
    attr_accessor :activesheet
    attr_writer :firstsheet

    def initialize
      @activesheet = nil
    end

    def activesheet_index
      index(@activesheet)
    end

    def firstsheet_index
      index(@firstsheet) || 0
    end

    def selected_count
      self.select { |sheet| sheet.selected? }.size
    end
  end
end
