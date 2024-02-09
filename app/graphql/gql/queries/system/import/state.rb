# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class System::Import::State < BaseQuery
    description 'Fetch system import state'

    type Gql::Types::ImportJobType, null: true

    def self.authorize(...)
      true
    end

    def resolve
      begin
        status = Service::System::Import::CheckStatus.new.execute
      rescue Service::System::Import::Run::ExecuteError => e
        return build_error(e.message)
      end

      return status if status.is_a?(ImportJob)

      transform_otrs_status(status)
    end

    private

    def build_error(message, name = 'Import::None')
      {
        name:        name,
        result:      {
          error: message
        },
        started_at:  nil,
        finished_at: nil
      }
    end

    def transform_otrs_status(status)
      return build_error(status[:message] || __('The OTRS import failed.'), 'Import::Otrs') if status[:result] == 'error'

      started_at = status.present? ? DateTime.now : nil
      finished_at = status[:result] == 'import_done' ? DateTime.now : nil

      data = status[:data] || {}
      data.deep_transform_keys! { |key| key.to_s.eql?('done') ? :sum : key }

      if data.present?
        data[:Configuration] = {
          sum:   1,
          total: 1,
        }
      end

      {
        name:        'Import::Otrs',
        result:      data,
        started_at:  started_at,
        finished_at: finished_at
      }
    end
  end
end
