
module V8

  class StackTrace
    include Enumerable

    def initialize(native)
      @context = V8::Context.current
      @native = native
    end

    def length
      @context.enter do
        @native ? @native.GetFrameCount() : 0
      end
    end

    def each
      return unless @native
      @context.enter do
        for i in 0..length - 1
          yield V8::StackFrame.new(@native.GetFrame(i), @context)
        end
      end
    end

    def to_s
      @native ? map(&:to_s).join("\n") : ""
    end
  end

  class StackFrame

    def initialize(native, context)
      @context = context
      @native = native
    end

    def script_name
      @context.enter do
        @context.to_ruby(@native.GetScriptName())
      end
    end

    def function_name
      @context.enter do
        @context.to_ruby(@native.GetFunctionName())
      end
    end

    def line_number
      @context.enter do
        @native.GetLineNumber()
      end
    end

    def column
      @context.enter do
        @native.GetColumn()
      end
    end

    def eval?
      @context.enter do
        @native.IsEval()
      end
    end

    def constructor?
      @context.enter do
        @native.IsConstructor()
      end
    end

    def to_s
      @context.enter do
        "at " + if !function_name.empty?
          "#{function_name} (#{script_name}:#{line_number}:#{column})"
        else
          "#{script_name}:#{line_number}:#{column}"
        end
      end
    end
  end
end