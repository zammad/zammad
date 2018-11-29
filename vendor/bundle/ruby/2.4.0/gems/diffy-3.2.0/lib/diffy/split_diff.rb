module Diffy
  class SplitDiff
    def initialize(left, right, options = {})
      @format = options[:format] || Diffy::Diff.default_format

      formats = Format.instance_methods(false).map { |x| x.to_s }
      unless formats.include?(@format.to_s)
        fail ArgumentError, "Format #{format.inspect} is not a valid format"
      end

      @diff = Diffy::Diff.new(left, right, options).to_s(@format)
      @left_diff, @right_diff = split
    end

    %w(left right).each do |direction|
      define_method direction do
        instance_variable_get("@#{direction}_diff")
      end
    end

    private

    def split
      [split_left, split_right]
    end

    def split_left
      case @format
      when :color
        @diff.gsub(/\033\[32m\+(.*)\033\[0m\n/, '')
      when :html, :html_simple
        @diff.gsub(%r{\s+<li class="ins"><ins>(.*)</ins></li>}, '')
      when :text
        @diff.gsub(/^\+(.*)\n/, '')
      end
    end

    def split_right
      case @format
      when :color
        @diff.gsub(/\033\[31m\-(.*)\033\[0m\n/, '')
      when :html, :html_simple
        @diff.gsub(%r{\s+<li class="del"><del>(.*)</del></li>}, '')
      when :text
        @diff.gsub(/^-(.*)\n/, '')
      end
    end
  end
end
