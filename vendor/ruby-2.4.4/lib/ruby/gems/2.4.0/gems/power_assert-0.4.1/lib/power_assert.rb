# power_assert.rb
#
# Copyright (C) 2014-2016 Kazuki Tsujimoto, All rights reserved.

begin
  captured = false
  TracePoint.new(:return, :c_return) do |tp|
    captured = true
    unless tp.binding and tp.return_value
      raise
    end
  end.enable { __id__ }
  raise unless captured
rescue
  raise LoadError, 'Fully compatible TracePoint API required'
end

require 'power_assert/version'
require 'power_assert/configuration'
require 'power_assert/enable_tracepoint_events'
require 'ripper'

module PowerAssert
  class << self
    def start(assertion_proc_or_source, assertion_method: nil, source_binding: TOPLEVEL_BINDING)
      if respond_to?(:clear_global_method_cache, true)
        clear_global_method_cache
      end
      yield Context.new(assertion_proc_or_source, assertion_method, source_binding)
    end

    private

    if defined?(RubyVM)
      def clear_global_method_cache
        eval('using PowerAssert.const_get(:Empty)', TOPLEVEL_BINDING)
      end
    end
  end

  module Empty
  end
  private_constant :Empty

  class InspectedValue
    def initialize(value)
      @value = value
    end

    def inspect
      @value
    end
  end
  private_constant :InspectedValue

  class SafeInspectable
    def initialize(value)
      @value = value
    end

    def inspect
      inspected = @value.inspect
      if Encoding.compatible?(Encoding.default_external, inspected)
        inspected
      else
        begin
          "#{inspected.encode(Encoding.default_external)}(#{inspected.encoding})"
        rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
          inspected.force_encoding(Encoding.default_external)
        end
      end
    rescue => e
      "InspectionFailure: #{e.class}: #{e.message.each_line.first}"
    end
  end
  private_constant :SafeInspectable

  class Context
    Value = Struct.new(:name, :value, :column)
    Ident = Struct.new(:type, :name, :column)

    TARGET_CALLER_DIFF = {return: 5, c_return: 4}
    TARGET_INDEX_OFFSET = 2

    attr_reader :message_proc

    def initialize(assertion_proc_or_source, assertion_method, source_binding)
      if assertion_proc_or_source.kind_of?(Proc)
        @assertion_proc = assertion_proc_or_source
        @line = nil
      else
        @assertion_proc = source_binding.eval "Proc.new {#{assertion_proc_or_source}}"
        @line = assertion_proc_or_source
      end
      path = nil
      lineno = nil
      methods = nil
      refs = nil
      method_ids = nil
      return_values = []
      @base_caller_length = -1
      @assertion_method_name = assertion_method.to_s
      @message_proc = -> {
        raise RuntimeError, 'call #yield at first' if @base_caller_length < 0
        @message ||= build_assertion_message(@line || '', methods || [], return_values, refs || [], @assertion_proc.binding).freeze
      }
      @proc_local_variables = @assertion_proc.binding.eval('local_variables').map(&:to_s)
      target_thread = Thread.current
      @trace_call = TracePoint.new(:call, :c_call) do |tp|
        next if @base_caller_length < 0
        locs = caller_locations
        if locs.length >= @base_caller_length+TARGET_INDEX_OFFSET and Thread.current == target_thread
          idx = -(@base_caller_length+TARGET_INDEX_OFFSET)
          path = locs[idx].path
          lineno = locs[idx].lineno
          @line ||= open(path).each_line.drop(lineno - 1).first
          idents = extract_idents(Ripper.sexp(@line))
          methods, refs = idents.partition {|i| i.type == :method }
          method_ids = methods.map(&:name).map(&:to_sym).each_with_object({}) {|i, h| h[i] = true }
          @trace_call.disable
        end
      end
      trace_alias_method = PowerAssert.configuration._trace_alias_method
      @trace = TracePoint.new(:return, :c_return) do |tp|
        method_id = SUPPORT_ALIAS_METHOD                      ? tp.callee_id :
                    trace_alias_method && tp.event == :return ? tp.binding.eval('::Kernel.__callee__') :
                                                                tp.method_id
        next if method_ids and ! method_ids[method_id]
        next if tp.event == :c_return and
                not (lineno == tp.lineno and path == tp.path)
        next unless tp.binding # workaround for ruby 2.2
        locs = tp.binding.eval('::Kernel.caller_locations')
        current_diff = locs.length - @base_caller_length
        if current_diff <= TARGET_CALLER_DIFF[tp.event] and Thread.current == target_thread
          idx = -(@base_caller_length+TARGET_INDEX_OFFSET)
          if path == locs[idx].path and lineno == locs[idx].lineno
            val = PowerAssert.configuration.lazy_inspection ?
              tp.return_value :
              InspectedValue.new(SafeInspectable.new(tp.return_value).inspect)
            return_values << Value[method_id.to_s, val, nil]
          end
        end
      end
    end

    def yield
      @trace_call.enable do
        do_yield(&@assertion_proc)
      end
    end

    def message
      @message_proc.()
    end

    private

    def do_yield
      @trace.enable do
        @base_caller_length = caller_locations.length
        yield
      end
    end

    def build_assertion_message(line, methods, return_values, refs, proc_binding)
      set_column(methods, return_values)
      ref_values = refs.map {|i| Value[i.name, proc_binding.eval(i.name), i.column] }
      vals = (return_values + ref_values).find_all(&:column).sort_by(&:column).reverse
      if vals.empty?
        return line
      end
      fmt = (0..vals[0].column).map {|i| vals.find {|v| v.column == i } ? "%<#{i}>s" : ' '  }.join
      lines = []
      lines << line.chomp
      lines << sprintf(fmt, vals.each_with_object({}) {|v, h| h[v.column.to_s.to_sym] = '|' }).chomp
      vals.each do |i|
        inspected_vals = vals.each_with_object({}) do |j, h|
          h[j.column.to_s.to_sym] = [SafeInspectable.new(i.value).inspect, '|', ' '][i.column <=> j.column]
        end
        lines << encoding_safe_rstrip(sprintf(fmt, inspected_vals))
      end
      lines.join("\n")
    end

    def set_column(methods, return_values)
      methods = methods.dup
      return_values.each do |val|
        idx = methods.index {|method| method.name == val.name }
        if idx
          val.column = methods.delete_at(idx).column
        end
      end
    end

    def encoding_safe_rstrip(str)
      str.rstrip
    rescue ArgumentError, Encoding::CompatibilityError
      enc = str.encoding
      if enc.ascii_compatible?
        str.b.rstrip.force_encoding(enc)
      else
        str
      end
    end

    def extract_idents(sexp)
      tag, * = sexp
      case tag
      when :arg_paren, :assoc_splat, :fcall, :hash, :method_add_block, :string_literal
        extract_idents(sexp[1])
      when :assign, :massign
        extract_idents(sexp[2])
      when :assoclist_from_args, :bare_assoc_hash, :dyna_symbol, :paren, :string_embexpr,
        :regexp_literal, :xstring_literal
        sexp[1].flat_map {|s| extract_idents(s) }
      when :assoc_new, :command, :dot2, :dot3, :string_content
        sexp[1..-1].flat_map {|s| extract_idents(s) }
      when :unary
        handle_columnless_ident([], sexp[1], extract_idents(sexp[2]))
      when :binary
        handle_columnless_ident(extract_idents(sexp[1]), sexp[2], extract_idents(sexp[3]))
      when :call
        if sexp[3] == :call
          handle_columnless_ident(extract_idents(sexp[1]), :call, [])
        else
          [sexp[1], sexp[3]].flat_map {|s| extract_idents(s) }
        end
      when :array
        sexp[1] ? sexp[1].flat_map {|s| extract_idents(s) } : []
      when :command_call
        [sexp[1], sexp[4], sexp[3]].flat_map {|s| extract_idents(s) }
      when :aref
        handle_columnless_ident(extract_idents(sexp[1]), :[], extract_idents(sexp[2]))
      when :method_add_arg
        idents = extract_idents(sexp[1])
        if idents.empty?
          # idents may be empty(e.g. ->{}.())
          extract_idents(sexp[2])
        else
          idents[0..-2] + extract_idents(sexp[2]) + [idents[-1]]
        end
      when :args_add_block
        _, (tag, ss0, *ss1), _ = sexp
        if tag == :args_add_star
          (ss0 + ss1).flat_map {|s| extract_idents(s) }
        else
          sexp[1].flat_map {|s| extract_idents(s) }
        end
      when :vcall
        _, (tag, name, (_, column)) = sexp
        if tag == :@ident
          [Ident[@proc_local_variables.include?(name) ? :ref : :method, name, column]]
        else
          []
        end
      when :program
        _, ((tag0, (tag1, (tag2, (tag3, mname, _)), _), (tag4, _, ss))) = sexp
        if tag0 == :method_add_block and tag1 == :method_add_arg and tag2 == :fcall and
            (tag3 == :@ident or tag3 == :@const) and mname == @assertion_method_name and (tag4 == :brace_block or tag4 == :do_block)
          ss.flat_map {|s| extract_idents(s) }
        else
          _, (s, *) = sexp
          extract_idents(s)
        end
      when :var_ref
        _, (tag, ref_name, (_, column)) = sexp
        case tag
        when :@kw
          if ref_name == 'self'
            [Ident[:ref, 'self', column]]
          else
            []
          end
        when :@const, :@cvar, :@ivar, :@gvar
          [Ident[:ref, ref_name, column]]
        else
          []
        end
      when :@ident, :@const
        _, method_name, (_, column) = sexp
        [Ident[:method, method_name, column]]
      else
        []
      end
    end

    def str_indices(str, re, offset, limit)
      idx = str.index(re, offset)
      if idx and idx <= limit
        [idx, *str_indices(str, re, idx + 1, limit)]
      else
        []
      end
    end

    MID2SRCTXT = {
      :[] => '[',
      :+@ => '+',
      :-@ => '-',
      :call => '('
    }

    def handle_columnless_ident(left_idents, mid, right_idents)
      left_max = left_idents.max_by(&:column)
      right_min = right_idents.min_by(&:column)
      bg = left_max ? left_max.column + left_max.name.length : 0
      ed = right_min ? right_min.column - 1 : @line.length - 1
      mname = mid.to_s
      srctxt = MID2SRCTXT[mid] || mname
      re = /
        #{'\b' if /\A\w/ =~ srctxt}
        #{Regexp.escape(srctxt)}
        #{'\b' if /\w\z/ =~ srctxt}
      /x
      indices = str_indices(@line, re, bg, ed)
      if left_idents.empty? and right_idents.empty?
        left_idents + right_idents
      elsif left_idents.empty?
        left_idents + right_idents + [Ident[:method, mname, indices.last]]
      else
        left_idents + right_idents + [Ident[:method, mname, indices.first]]
      end
    end
  end
  private_constant :Context
end
