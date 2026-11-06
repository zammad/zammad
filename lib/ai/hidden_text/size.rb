# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The font sizes of a message's inline styles in pixels, for the browser's default font of 16 pixels.
module AI::HiddenText::Size
  module_function

  ABSOLUTE = { 'px' => 1.0, 'pt' => 4.0 / 3, 'pc' => 16.0, 'in' => 96.0, 'cm' => 96 / 2.54, 'mm' => 96 / 25.4, 'q' => 96 / 101.6 }.freeze

  KEYWORDS = {
    'xx-small' => 9.0, 'x-small' => 10.0, 'small' => 13.0, 'medium' => 16.0, 'large' => 18.0, 'x-large' => 24.0,
    'xx-large' => 32.0, 'xxx-large' => 48.0
  }.freeze

  RELATIVE_KEYWORDS = { 'larger' => 1.2, 'smaller' => 1 / 1.2 }.freeze

  # @param value [String, nil] such as "12px", "0.5em" or "small"
  # @param inherited [Float, nil] the parent's size, in pixels; nil where the check cannot tell it
  # @return [Float, nil] the size in pixels: the inherited one where the element sets none; nil for one the check does
  #   not read — a computed size, a size of the view, one the browser ignores — or one relative to a size it cannot tell
  def font_pixels(value, inherited:)
    return inherited if value.blank? || AI::HiddenText::INHERITED.include?(value)
    return KEYWORDS.fetch(value) if KEYWORDS.key?(value)
    return KEYWORDS.fetch('medium') if value == 'initial'
    return inherited && (inherited * RELATIVE_KEYWORDS.fetch(value)) if RELATIVE_KEYWORDS.key?(value)

    number, unit = value.match(%r{\A\+?(\d+\.?\d*|\.\d+)([a-z%]*)\z})&.captures
    return 0.0 if unit == '' && number.to_f.zero?

    factor = number && unit_pixels(unit, inherited)
    factor && (number.to_f * factor)
  end

  # @return [Float, nil] nil for a unit the check does not read, such as one of the view, for a number without one,
  #   which only a zero may be, and for a unit relative to a size the check cannot tell
  def unit_pixels(unit, base)
    return ABSOLUTE.fetch(unit) if ABSOLUTE.key?(unit)
    return 16.0 if unit == 'rem'
    return if base.nil?

    case unit
    when 'em' then base
    when '%' then base / 100
    when 'ex', 'ch' then base / 2
    end
  end
end
