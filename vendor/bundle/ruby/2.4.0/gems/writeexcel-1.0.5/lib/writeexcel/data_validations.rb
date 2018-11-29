module Writeexcel

class Worksheet < BIFFWriter
  require 'writeexcel/helper'

  class DataValidations < Array
    #
    # the count of the DV records to follow.
    #
    # Note, this could be wrapped into store_dv() but we may require separate
    # handling of the object id at a later stage.
    #
    def count_dv_record   #:nodoc:
      return if empty?

      dval_record(-1, size)  # obj_id = -1
    end

    private

    #
    # Store the DV record which contains the number of and information common to
    # all DV structures.
    #    obj_id       # Object ID number.
    #    dv_count     # Count of DV structs to follow.
    #
    def dval_record(obj_id, dv_count)   #:nodoc:
      record      = 0x01B2       # Record identifier
      length      = 0x0012       # Bytes to follow

      flags       = 0x0004       # Option flags.
      x_coord     = 0x00000000   # X coord of input box.
      y_coord     = 0x00000000   # Y coord of input box.

      # Pack the record.
      header = [record, length].pack('vv')
      data   = [flags, x_coord, y_coord, obj_id, dv_count].pack('vVVVV')

      header + data
    end
  end

  require 'writeexcel/convert_date_time'

  class DataValidation
    include ConvertDateTime

    def initialize(parser = nil, param = {})
      @parser        = parser
      @cells         = param[:cells]
      @validate      = param[:validate]
      @criteria      = param[:criteria]
      @value         = param[:value]
      @maximum       = param[:maximum]
      @input_title   = param[:input_title]
      @input_message = param[:input_message]
      @error_title   = param[:error_title]
      @error_message = param[:error_message]
      @error_type    = param[:error_type]
      @ignore_blank  = param[:ignore_blank]
      @dropdown      = param[:dropdown]
      @show_input    = param[:show_input]
      @show_error    = param[:show_error]
    end

    #
    # Calclate the DV record that specifies the data validation criteria and options
    # for a range of cells..
    #    cells             # Aref of cells to which DV applies.
    #    validate          # Type of data validation.
    #    criteria          # Validation criteria.
    #    value             # Value/Source/Minimum formula.
    #    maximum           # Maximum formula.
    #    input_title       # Title of input message.
    #    input_message     # Text of input message.
    #    error_title       # Title of error message.
    #    error_message     # Text of input message.
    #    error_type        # Error dialog type.
    #    ignore_blank      # Ignore blank cells.
    #    dropdown          # Display dropdown with list.
    #    input_box         # Display input box.
    #    error_box         # Display error box.
    #
    def dv_record  # :nodoc:
      record          = 0x01BE       # Record identifier

      flags           = 0x00000000   # DV option flags.

      ime_mode        = 0            # IME input mode for far east fonts.
      str_lookup      = 0            # See below.

      # Set the string lookup flag for 'list' validations with a string array.
      str_lookup = @validate == 3 && @value.respond_to?(:to_ary) ? 1 : 0

      # The dropdown flag is stored as a negated value.
      no_dropdown = @dropdown ? 0 : 1

      # Set the required flags.
      flags |= @validate
      flags |= @error_type   << 4
      flags |= str_lookup    << 7
      flags |= @ignore_blank << 8
      flags |= no_dropdown   << 9
      flags |= ime_mode      << 10
      flags |= @show_input   << 18
      flags |= @show_error   << 19
      flags |= @criteria     << 20

      # Pack the DV cell data.
      dv_data = @cells.inject([@cells.size].pack('v')) do |result, range|
        result + [range[0], range[2], range[1], range[3]].pack('vvvv')
      end

      # Pack the record.
      data   = [flags].pack('V')     +
        pack_dv_string(@input_title,   32 ) +
        pack_dv_string(@error_title,   32 ) +
        pack_dv_string(@input_message, 255) +
        pack_dv_string(@error_message, 255) +
        pack_dv_formula(@value)             +
        pack_dv_formula(@maximum)           +
        dv_data

      header = [record, data.bytesize].pack('vv')

      header + data
    end

    def self.factory(parser, date_1904, *args)
      # Check for a valid number of args.
      return -1 if args.size != 5 && args.size != 3

      # The final hashref contains the validation parameters.
      param = args.pop

      # 'validate' is a required parameter.
      return -3 unless param.has_key?(:validate)

      # Make the last row/col the same as the first if not defined.
      row1, col1, row2, col2 = args
      row2, col2 = row1, col1 unless row2

      # List of valid input parameters.
      obj = DataValidation.new
      valid_parameter = obj.valid_parameter_of_data_validation

      # Check for valid input parameters.
      param.each_key { |param_key| return -3 unless valid_parameter.has_key?(param_key) }

      # Map alternative parameter names 'source' or 'minimum' to 'value'.
      param[:value] = param[:source]  if param[:source]
      param[:value] = param[:minimum] if param[:minimum]

      # Check for valid validation types.
      unless obj.valid_validation_type.has_key?(param[:validate].downcase)
        return -3
      else
        param[:validate] = obj.valid_validation_type[param[:validate].downcase]
      end

      # No action is required for validation type 'any'.
      # TODO: we should perhaps store 'any' for message only validations.
      return 0 if param[:validate] == 0

      # The list and custom validations don't have a criteria so we use a default
      # of 'between'.
      if param[:validate] == 3 || param[:validate] == 7
        param[:criteria]  = 'between'
        param[:maximum]   = nil
      end

      # 'criteria' is a required parameter.
      unless param.has_key?(:criteria)
        #           carp "Parameter 'criteria' is required in data_validation()";
        return -3
      end

      # Check for valid criteria types.
      unless obj.valid_criteria_type.has_key?(param[:criteria].downcase)
        return -3
      else
        param[:criteria] = obj.valid_criteria_type[param[:criteria].downcase]
      end

      # 'Between' and 'Not between' criteria require 2 values.
      if param[:criteria] == 0 || param[:criteria] == 1
        unless param.has_key?(:maximum)
          return -3
        end
      else
        param[:maximum] = nil
      end

      # Check for valid error dialog types.
      if not param.has_key?(:error_type)
        param[:error_type] = 0
      elsif not obj.valid_error_type.has_key?(param[:error_type].downcase)
        return -3
      else
        param[:error_type] = obj.valid_error_type[param[:error_type].downcase]
      end

      # Convert date/times value if required.
      if param[:validate] == 4 || param[:validate] == 5
        if param[:value] =~ /T/
          param[:value] = obj.convert_date_time(param[:value], date_1904) || raise("invalid :value: #{param[:value]}")
        end
        if param[:maximum] && param[:maximum] =~ /T/
          param[:maximum] = obj.convert_date_time(param[:maximum], date_1904) || raise("invalid :maximum: #{param[:maximum]}")
        end
      end

      # Set some defaults if they haven't been defined by the user.
      param[:ignore_blank]  = 1 unless param[:ignore_blank]
      param[:dropdown]      = 1 unless param[:dropdown]
      param[:show_input]    = 1 unless param[:show_input]
      param[:show_error]    = 1 unless param[:show_error]

      # These are the cells to which the validation is applied.
      param[:cells] = [[row1, col1, row2, col2]]

      # A (for now) undocumented parameter to pass additional cell ranges.
      if param.has_key?(:other_cells)
        param[:cells].push(param[:other_cells])
      end

      DataValidation.new(parser, param)
    end

    #
    # Pack the strings used in the input and error dialog captions and messages.
    # Captions are limited to 32 characters. Messages are limited to 255 chars.
    #
    def pack_dv_string(string, max_length)   #:nodoc:
      # The default empty string is "\0".
      string = ruby_18 { "\0" } || ruby_19 { "\0".encode('BINARY') } unless string && string != ''

      # Excel limits DV captions to 32 chars and messages to 255.
      string = string[0 .. max_length-1] if string.bytesize > max_length

      ruby_19 { string = convert_to_ascii_if_ascii(string) }

      # Handle utf8 strings
      if is_utf8?(string)
        str_length = string.gsub(/[^\Wa-zA-Z_\d]/, ' ').bytesize   # jlength
        string = utf8_to_16le(string)
        encoding = 1
      else
        str_length = string.bytesize
        encoding = 0
      end

      ruby_18 { [str_length, encoding].pack('vC') + string } ||
      ruby_19 { [str_length, encoding].pack('vC') + string.force_encoding('BINARY') }
    end

    #
    # Pack the formula used in the DV record. This is the same as an cell formula
    # with some additional header information. Note, DV formulas in Excel use
    # relative addressing (R1C1 and ptgXxxN) however we use the Formula.pm's
    # default absolute addressing (A1 and ptgXxx).
    #
    def pack_dv_formula(formula)   #:nodoc:
      unused      = 0x0000

      # Return a default structure for unused formulas.
      return [0, unused].pack('vv') unless formula && formula != ''

      # Pack a list array ref as a null separated string.
      formula   = %!"#{formula.join("\0")}"! if formula.respond_to?(:to_ary)

      # Strip the = sign at the beginning of the formula string
      formula = formula.to_s unless formula.respond_to?(:to_str)

      # In order to raise formula errors from the point of view of the calling
      # program we use an eval block and re-raise the error from here.
      #
      tokens = @parser.parse_formula(formula.sub(/^=/, ''))   # ????

      #       if ($@) {
      #           $@ =~ s/\n$//;  # Strip the \n used in the Formula.pm die()
      #           croak $@;       # Re-raise the error
      #       }
      #       else {
      #           # TODO test for non valid ptgs such as Sheet2!A1
      #       }

      # Force 2d ranges to be a reference class.
      tokens.each do |t|
        t.sub!(/_range2d/, "_range2dR")
        t.sub!(/_name/, "_nameR")
      end

      # Parse the tokens into a formula string.
      formula = @parser.parse_tokens(tokens)

      [formula.length, unused].pack('vv') + formula
    end

    def valid_parameter_of_data_validation
      {
        :validate          => 1,
        :criteria          => 1,
        :value             => 1,
        :source            => 1,
        :minimum           => 1,
        :maximum           => 1,
        :ignore_blank      => 1,
        :dropdown          => 1,
        :show_input        => 1,
        :input_title       => 1,
        :input_message     => 1,
        :show_error        => 1,
        :error_title       => 1,
        :error_message     => 1,
        :error_type        => 1,
        :other_cells       => 1
      }
    end

    def valid_validation_type
      {
        'any'             => 0,
        'any value'       => 0,
        'whole number'    => 1,
        'whole'           => 1,
        'integer'         => 1,
        'decimal'         => 2,
        'list'            => 3,
        'date'            => 4,
        'time'            => 5,
        'text length'     => 6,
        'length'          => 6,
        'custom'          => 7
      }
    end

    def valid_criteria_type
      {
        'between'                     => 0,
        'not between'                 => 1,
        'equal to'                    => 2,
        '='                           => 2,
        '=='                          => 2,
        'not equal to'                => 3,
        '!='                          => 3,
        '<>'                          => 3,
        'greater than'                => 4,
        '>'                           => 4,
        'less than'                   => 5,
        '<'                           => 5,
        'greater than or equal to'    => 6,
        '>='                          => 6,
        'less than or equal to'       => 7,
        '<='                          => 7
      }
    end

    def valid_error_type
      {
        'stop'        => 0,
        'warning'     => 1,
        'information' => 2
      }
    end
  end
end

end
