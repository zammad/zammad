# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Rszr do
  context 'when loading in image' do
    it 'orientation is detected correctly' do
      sample_path  = Rails.root.join 'lib/core_ext/rszr.jpg'
      sample_image = Rszr::Image.load sample_path

      expect(sample_image.height).to be 25
    end
  end
end
