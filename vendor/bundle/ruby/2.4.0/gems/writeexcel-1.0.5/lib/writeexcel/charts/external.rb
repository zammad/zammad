# -*- coding: utf-8 -*-
###############################################################################
#
# External - A writer class for Excel external charts.
#
# Used in conjunction with WriteExcel
#
# perltidy with options: -mbl=2 -pt=0 -nola
#
# Copyright 2000-2010, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'writeexcel/chart'

module Writeexcel

class External < Chart # :nodoc:
  ###############################################################################
  #
  # new()
  #
  def initialize(external_filename, *args)
    super(*args)

    @filename     = external_filename
    @external_bin = true

    _initialize    # Requires overridden initialize().
    self
  end

  ###############################################################################
  #
  # _initialize()
  #
  # Read all the data into memory for the external binary style chart.
  #
  def _initialize
    filename   = @filename
    filehandle = File.open(filename, 'rb')

    @filehandle    = filehandle
    @datasize      = FileTest.size(filename)
    @using_tmpfile = false

    # Read the entire external chart binary into the the data buffer.
    # This will be retrieved by _get_data() when the chart is closed().
    @data = @filehandle.read(@datasize)
  end

  ###############################################################################
  #
  # _close()
  #
  # We don't need to create or store Chart data structures when using an
  # external binary, so we have a default close method.
  #
  def close
    nil
  end
end  # class Chart

end  # module Writeexcel
