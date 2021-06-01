# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ColorValidator < ActiveModel::EachValidator
  REGEXP = {
    RGB: %r{^rgb\((((((((1?[1-9]?\d)|10\d|(2[0-4]\d)|25[0-5]),\s?)){2}|((((1?[1-9]?\d)|10\d|(2[0-4]\d)|25[0-5])\s)){2})((1?[1-9]?\d)|10\d|(2[0-4]\d)|25[0-5]))|((((([1-9]?\d(\.\d+)?)|100|(\.\d+))%,\s?){2}|((([1-9]?\d(\.\d+)?)|100|(\.\d+))%\s){2})(([1-9]?\d(\.\d+)?)|100|(\.\d+))%))\)$}i,
    HSL: %r{^hsl\(((((([12]?[1-9]?\d)|[12]0\d|(3[0-6]\d))(\.\d+)?)|(\.\d+))(deg)?|(0|0?\.\d+)turn|(([0-6](\.\d+)?)|(\.\d+))rad)((,\s?(([1-9]?\d(\.\d+)?)|100|(\.\d+))%){2}|(\s(([1-9]?\d(\.\d+)?)|100|(\.\d+))%){2})\)$}i,
    HEX: %r{^#([\da-f]{3}){1,2}$}i
  }.freeze

  def validate_each(record, attribute, value)
    return if color?(value)

    record.errors[attribute] << (options[:message] || 'is not a color. Only Hex, RGB and HSL colors are supported.')
  end

  def color?(value)
    sanitized_value = value.to_s.strip.gsub(', ', ',')

    REGEXP.values.any? { |regexp| regexp.match? sanitized_value }
  end
end
