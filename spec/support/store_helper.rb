# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module ZammadStoreHelper
  # Add attachment to Store
  #
  # @param id [Integer] ID of the owner object
  # @param object_name [String] class name of the owner object
  # @param filename [String] filename (including path) to file to use as a test.
  #
  def attach(id:, object_name: 'UploadCache', filename: 'test/data/image/1x1.png')
    Store.add(
      object:        object_name,
      o_id:          id,
      data:          File.binread(Rails.root.join(filename)),
      filename:      Pathname.new(filename).basename,
      preferences:   {},
      created_by_id: 1,
    )
  end
end

RSpec.configure do |config|
  config.include ZammadStoreHelper
end
