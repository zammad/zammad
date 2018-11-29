class Workbook < BIFFWriter
  require 'writeexcel/properties'
  require 'writeexcel/helper'

  class SharedString
    attr_reader :string, :str_id

    def initialize(string, str_id)
      @string, @str_id = string, str_id
    end
  end

  class SharedStringTable
    attr_reader :str_total

    def initialize
      @shared_string_table = []
      @string_to_shared_string = {}
      @str_total = 0
    end

    def has_string?(string)
      !!@string_to_shared_string[string]
    end

    def <<(string)
      @str_total += 1
      unless has_string?(string)
        shared_string = SharedString.new(string, str_unique)
        @shared_string_table << shared_string
        @string_to_shared_string[string] = shared_string
      end
      id(string)
    end

    def strings
      @shared_string_table.collect { |shared_string| shared_string.string }
    end

    def id(string)
      @string_to_shared_string[string].str_id
    end

    def str_unique
      @shared_string_table.size
    end

    def block_sizes
      @block_sizes ||= calculate_block_sizes
    end

    #
    # Handling of the SST continue blocks is complicated by the need to include an
    # additional continuation byte depending on whether the string is split between
    # blocks or whether it starts at the beginning of the block. (There are also
    # additional complications that will arise later when/if Rich Strings are
    # supported). As such we cannot use the simple CONTINUE mechanism provided by
    # the add_continue() method in BIFFwriter.pm. Thus we have to make two passes
    # through the strings data. The first is to calculate the required block sizes
    # and the second, in store_shared_strings(), is to write the actual strings.
    # The first pass through the data is also used to calculate the size of the SST
    # and CONTINUE records for use in setting the BOUNDSHEET record offsets. The
    # downside of this is that the same algorithm repeated in store_shared_strings.
    #
    def calculate_block_sizes
      # Iterate through the strings to calculate the CONTINUE block sizes.
      #
      # The SST blocks requires a specialised CONTINUE block, so we have to
      # ensure that the maximum data block size is less than the limit used by
      # add_continue() in BIFFwriter.pm. For simplicity we use the same size
      # for the SST and CONTINUE records:
      #   8228 : Maximum Excel97 block size
      #     -4 : Length of block header
      #     -8 : Length of additional SST header information
      #     -8 : Arbitrary number to keep within add_continue() limit
      # = 8208
      #
      continue_limit = 8208
      block_length   = 0
      written        = 0
      block_sizes    = []
      continue       = 0

      strings.each do |string|
        string_length = string.bytesize

        # Block length is the total length of the strings that will be
        # written out in a single SST or CONTINUE block.
        #
        block_length += string_length

        # We can write the string if it doesn't cross a CONTINUE boundary
        if block_length < continue_limit
          written += string_length
          next
        end

        # Deal with the cases where the next string to be written will exceed
        # the CONTINUE boundary. If the string is very long it may need to be
        # written in more than one CONTINUE record.
        encoding      = string.unpack("xx C")[0]
        split_string  = 0
        while block_length >= continue_limit
          header_length, space_remaining, align, split_string =
            Workbook.split_string_setup(encoding, split_string, continue_limit, written, continue)

          if space_remaining > header_length
            # Write as much as possible of the string in the current block
            written      += space_remaining

            # Reduce the current block length by the amount written
            block_length -= continue_limit -continue -align

            # Store the max size for this block
            block_sizes.push(continue_limit -align)

            # If the current string was split then the next CONTINUE block
            # should have the string continue flag (grbit) set unless the
            # split string fits exactly into the remaining space.
            #
            if block_length > 0
              continue = 1
            else
              continue = 0
            end
          else
            # Store the max size for this block
            block_sizes.push(written +continue)

            # Not enough space to start the string in the current block
            block_length -= continue_limit -space_remaining -continue
            continue = 0
          end

          # If the string (or substr) is small enough we can write it in the
          # new CONTINUE block. Else, go through the loop again to write it in
          # one or more CONTINUE blocks
          #
          if block_length < continue_limit
            written = block_length
          else
            written = 0
          end
        end
      end

      # Store the max size for the last block unless it is empty
      block_sizes.push(written +continue) if written +continue != 0

      block_sizes
    end
  end
end
