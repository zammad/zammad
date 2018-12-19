class Capybara::Node::Element

  # This is an extension to each node to check if the element
  # is moving or in a fixed position. This is especially helpful
  # for animated elements that cause flanky tests.
  # NOTE: In CI env a special sleep is performed between checks
  # because animations can be slow.
  #
  # @param [Integer] checks the number of performed movement checks
  #
  # @example
  #  find('.clues-close').in_fixed_postion.click
  # => waits till clues moved to final position and performs click afterwards
  #
  # @raise [RuntimeError] raised in case the element is
  #   still moving after max number of checks was passed
  #
  # @return [Capybara::Node::Element] the element/node
  def in_fixed_postion(checks: 100)

    previous = native.location
    (checks + 1).times do |check|
      raise "Element still moving after #{checks} checks" if check == checks

      current = native.location
      sleep 0.2 if ENV['CI']
      break if previous == current

      previous = current
    end

    self
  end
end
