# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'ticket'

module Import
  module OTRS
    class Ticket
      include Import::Helper
      include Import::OTRS::Helper

      MAPPING = {
        Changed:       :updated_at,
        Created:       :created_at,
        TicketNumber:  :number,
        QueueID:       :group_id,
        StateID:       :state_id,
        PriorityID:    :priority_id,
        Title:         :title,
        TicketID:      :id,
        FirstResponse: :first_response_at,
        #FirstResponseTimeDestinationDate: :first_response_escalation_at,
        #FirstResponseInMin: :first_response_in_min,
        #FirstResponseDiffInMin: :first_response_diff_in_min,
        Closed:        :close_at,
        #SoltutionTimeDestinationDate: :close_escalation_at,
        #CloseTimeInMin: :close_in_min,
        #CloseTimeDiffInMin: :close_diff_in_min,
      }.freeze

      def initialize(ticket)
        fix(ticket)
        import(ticket)
      end

      private

      def import(ticket)
        Import::OTRS::ArticleCustomerFactory.import(ticket['Articles'])

        create_or_update(map(ticket))

        Import::OTRS::ArticleFactory.import(ticket['Articles'])
        Import::OTRS::HistoryFactory.import(ticket['History'])
      end

      def create_or_update(ticket)
        return if updated?(ticket)

        create(ticket)
      end

      def updated?(ticket)
        @local_ticket = ::Ticket.find_by(id: ticket[:id])
        return false if !@local_ticket

        log "update Ticket.find_by(id: #{ticket[:id]})"
        @local_ticket.update!(ticket)
        true
      end

      def create(ticket)
        log "add Ticket.find_by(id: #{ticket[:id]})"
        @local_ticket    = ::Ticket.new(ticket)
        @local_ticket.id = ticket[:id]
        @local_ticket.save
        reset_primary_key_sequence('tickets')
      rescue ActiveRecord::RecordNotUnique
        log "Ticket #{ticket[:id]} is handled by another thead, skipping."
      end

      def map(ticket)
        ensure_map(default_map(ticket))
      end

      def ensure_map(mapped)
        return mapped if mapped[:title]

        mapped[:title] = '**EMPTY**'
        mapped
      end

      def default_map(ticket)
        {
          owner_id:      owner_id(ticket),
          customer_id:   customer_id(ticket),
          created_by_id: created_by_id(ticket),
          updated_by_id: 1,
        }
          .merge(from_mapping(ticket))
          .merge(dynamic_fields(ticket))
      end

      def dynamic_fields(ticket)
        result = {}
        ticket.each_key do |key|

          key_string = key.to_s

          next if !key_string.start_with?('DynamicField_')

          dynamic_field_name = key_string[13, key_string.length]

          next if Import::OTRS::DynamicFieldFactory.skip_field?( dynamic_field_name )

          dynamic_field_name = Import::OTRS::DynamicField.convert_name(dynamic_field_name)

          result[dynamic_field_name.to_sym] = ticket[key_string]
        end
        result
      end

      def owner_id(ticket)
        default = 1
        owner   = ticket['Owner']

        return default if !owner

        user = user_lookup(owner)

        return user.id if user

        default
      end

      def customer_id(ticket)
        default  = 1
        customer = ticket['CustomerUserID']

        return default if !customer

        user = user_lookup(customer)
        return user.id if user

        first_customer_id = first_customer_id(ticket['Articles'])
        return first_customer_id if first_customer_id

        default
      end

      def created_by_id(ticket)
        default = 1
        return ticket['CreateBy'] if ticket['CreateBy'].to_i != default
        return default if ticket['Articles'].blank?
        return default if ticket['Articles'].first['SenderType'] != 'customer'

        customer_id(ticket)
      end

      def user_lookup(login)
        ::User.find_by(login: login.downcase)
      end

      def first_customer_id(articles)
        user_id = nil
        articles.each do |article|
          next if article['SenderType'] != 'customer'
          next if article['From'].blank?

          user = Import::OTRS::ArticleCustomer.find(article)
          break if !user

          user_id = user.id
          break
        end
        user_id
      end

      # cleanup invalid values
      def fix(ticket)
        utf8_encode(ticket)
        fix_timestamps(ticket)
        fix_close_time(ticket)
      end

      def fix_timestamps(ticket)
        ticket.each do |key, value|
          next if value != '0000-00-00 00:00:00'

          ticket[key] = nil
        end
      end

      # fix OTRS 3.1 bug, no close time if ticket is created
      def fix_close_time(ticket)
        return if ticket['StateType'] != 'closed'
        return if ticket['Closed']
        return if ticket['Closed'].present?

        ticket['Closed'] = ticket['Created']
      end
    end
  end
end
