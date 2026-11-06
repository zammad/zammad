# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The colours of a message's inline styles in the common notations — names, hex, rgb() and hsl() — and their contrast.
#   Any other notation is not read, so that the check counts it as unknown.
module AI::HiddenText::Color
  module_function

  FUNCTION = %r{\A(rgba?|hsla?)\((.*)\)\z}

  # A number, as an angle or a percentage too.
  NUMBER = %r{\A[+-]?(?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?(?:%|deg)?\z}

  # Larger numbers are no colour a message means, and reading one, such as 1e999, overflows the maths.
  MAX_NUMBER = 1e6

  # @param value [String]
  # @return [Array(Integer, Integer, Integer, Float), nil] red, green, blue and opacity; nil for a notation not read here
  def parse(value)
    value = value.to_s.strip.downcase
    return [0, 0, 0, 0.0] if value == 'transparent'
    return hex(AI::HiddenText::ColorNames::NAMED[value]) if AI::HiddenText::ColorNames::NAMED.key?(value)
    return hex(value.delete_prefix('#')) if value.start_with?('#')

    match = value.match(FUNCTION)
    function(match[1], arguments(match[2])) if match
  end

  def hex(digits)
    return if !digits.match?(%r{\A(?:\h{3,4}|\h{6}|\h{8})\z})

    digits   = digits.chars.map { |digit| digit * 2 }.join if digits.length <= 4
    channels = digits.scan(%r{\h\h}).map { |pair| pair.to_i(16) }

    [*channels.first(3), (channels[3] || 255) / 255.0]
  end

  # The arguments of a colour function, its opacity last.
  def arguments(text)
    text.tr('/,', '  ').split
  end

  def function(name, parts)
    return if parts.size < 3 || parts.size > 4
    return if parts.any? { |part| !part.match?(NUMBER) || part.to_f.abs > MAX_NUMBER }

    alpha = parts[3] ? number(parts[3], percent: 1) : 1.0
    rgb   = if name.start_with?('rgb')
              parts.first(3).map { |part| number(part, percent: 255) }
            else
              hsl(number(parts[0]), number(parts[1]) / 100, number(parts[2]) / 100)
            end

    [*rgb.map { |channel| channel.clamp(0, 255).round }, alpha.clamp(0.0, 1.0)]
  end

  # @param percent [Numeric] what 100% stands for
  def number(text, percent: 100)
    text.end_with?('%') ? text.to_f * percent / 100 : text.to_f
  end

  def hsl(hue, saturation, lightness)
    chroma = (1 - ((2 * lightness) - 1).abs) * saturation

    [0, 8, 4].map do |offset|
      k = (offset + (hue / 30.0)) % 12
      (lightness - (chroma / 2 * [[k - 3, 9 - k, 1].min, -1].max)) * 255
    end
  end

  # As WCAG defines the contrast of two colours.
  def contrast(first, second)
    lighter, darker = [luminance(first), luminance(second)].sort.reverse

    (lighter + 0.05) / (darker + 0.05)
  end

  def luminance(rgb)
    red, green, blue = rgb.map do |channel|
      value = channel / 255.0
      value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055)**2.4
    end

    (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
  end
end
