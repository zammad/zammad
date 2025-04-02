# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Service::Channel::Whatsapp
  class Create < Base
    def initialize(params:)
      super()

      @params = params
    end

    def execute
      ActiveRecord::Base.transaction do
        ::Channel.create!(
          area: area,
          **attributes_hash
        ).tap { |channel| add_metadata(channel:, initial: true) }
      end
    end
  end
end
