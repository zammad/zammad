# -*- coding: utf-8 -*-

class WriteFile
  def initialize
    @data            = ''
    @datasize        = 0
    @limit           = 8224

    # Open a tmp file to store the majority of the Worksheet data. If this fails,
    # for example due to write permissions, store the data in memory. This can be
    # slow for large files.
    @filehandle = Tempfile.new('writeexcel')
    @filehandle.binmode

    # failed. store temporary data in memory.
    @using_tmpfile = @filehandle ? true : false
  end

  ###############################################################################
  #
  # _prepend($data)
  #
  # General storage function
  #
  def prepend(*args)
    data = join_data(args)
    @data = data + @data

    data
  end

  ###############################################################################
  #
  # _append($data)
  #
  # General storage function
  #
  def append(*args)
    data = join_data(args)

    if @using_tmpfile
      @filehandle.write(data)
    else
      @data += data
    end

    data
  end

  private

  def join_data(args)
    data =
      ruby_18 { args.join } ||
      ruby_19 { args.compact.collect{ |arg| arg.dup.force_encoding('ASCII-8BIT') }.join }
    # Add CONTINUE records if necessary
    data = add_continue(data) if data.bytesize > @limit

    @datasize += data.bytesize

    data
  end
end
