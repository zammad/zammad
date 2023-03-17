# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Rszr
  # https://github.com/zammad/zammad/issues/4347
  #
  # This method detects if Rszr needs autorotate flag to correctly handle photos orientation
  #
  # < 1.9 imlib2 versions need autorotate flag.
  # >= 1.9 imlib2 versions handle autorotate and autorotate flag causes issues.
  #
  # As of January 2023, major LTS Linux distributions include older imlib2
  # Even after latest distributions switch to newer imlib2, we will need this to support older distros for a while
  #
  # This file will be removed along with config/initializers/rszr.rb
  # When all supported Linux distributions update to >= 1.9 imlib2
  def self.needs_autorotate_fix?
    sample_path  = Rails.root.join 'lib/core_ext/rszr.jpg'
    sample_image = Rszr::Image.load sample_path

    sample_image.height != 25
  rescue Rszr::LoadError
    true  # Platform with outdated imlib2, handle gracefully.
  end
end
