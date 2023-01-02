# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module MonitoringHelper
  class Status
    INCLUDE_CLASSES = [User, Group, Overview, Ticket, Ticket::Article, TextModule, Taskbar, ObjectManager::Attribute, KnowledgeBase::Category, KnowledgeBase::Answer].freeze

    def fetch_status
      {
        counts:          counts,
        last_created_at: last_created_at,
        last_login:      last_login,
        agents:          agents_count,
        storage:         storage
      }
    end

    private

    def last_login
      User
        .where.not(last_login: nil)
        .order(last_login: :desc)
        .first
        &.last_login
    end

    def agents_count
      User.with_permissions('ticket.agent').count
    end

    def counts
      INCLUDE_CLASSES.each_with_object({}) do |elem, memo|
        memo[elem.table_name] = elem.count
      end
    end

    def last_created_at
      INCLUDE_CLASSES.each_with_object({}) do |elem, memo|
        memo[elem.table_name] = elem.last&.created_at
      end
    end

    def storage
      return if ActiveRecord::Base.connection_db_config.configuration_hash[:adapter] != 'postgresql'

      sql = 'SELECT SUM(CAST(coalesce(size, \'0\') AS INTEGER)) FROM stores'

      stored = ActiveRecord::Base.connection.exec_query(sql).first&.dig('sum')

      return if !stored

      {
        kB: stored / 1024,
        MB: stored / 1024 / 1024,
        GB: stored / 1024 / 1024 / 1024,
      }
    end
  end
end
