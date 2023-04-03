# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Ticket::Selector::Sql < Ticket::Selector::Base
  attr_accessor :final_query, :final_bind_params, :final_tables, :final_tables_query

  def get
    @final_query        = []
    @final_bind_params  = []
    @final_tables       = []
    @final_tables_query = []
    @final_query        = run(selector, 0)
    [query_sql, final_bind_params, tables_sql]
  rescue InvalidCondition => e
    Rails.logger.error "Ticket::Selector.get->InvalidCondition: #{e}"
    nil
  rescue => e
    Rails.logger.error "Ticket::Selector.get->default: #{e}"
    raise e
  end

  def query_sql
    [
      final_tables_query.join(' AND ').presence,
      final_query.presence,
    ].compact.join(' AND ')
  end

  def tables_sql
    return '' if final_tables.blank?

    ", #{final_tables.join(', ')}"
  end

  def run(block, level)
    if block.key?(:conditions)
      run_block(block, level)
    else
      query, bind_params, tables, tables_query = condition_sql(block)
      @final_bind_params                   += bind_params
      @final_tables                        |= tables
      @final_tables_query                  |= tables_query
      query
    end
  end

  def run_block(block, level)
    block_query = []
    block[:conditions].each do |sub_block|
      block_query << run(sub_block, level + 1)
    end

    block_query = block_query.compact
    return if block_query.blank?

    return "NOT(#{block_query.join(' AND ')})" if block[:operator] == 'NOT'

    "(#{block_query.join(" #{block[:operator]} ")})"
  end

  def condition_sql(block_condition)
    current_user = options[:current_user]
    current_user_id = UserInfo.current_user_id
    if current_user
      current_user_id = current_user.id
    end

    raise InvalidCondition, "No block condition #{block_condition.inspect}" if block_condition.blank?
    raise InvalidCondition, "No block condition name #{block_condition.inspect}" if block_condition[:name].blank?

    # remember query and bind params
    query                           = []
    tables                          = []
    tables_query                    = []
    bind_params                     = []
    like                            = Rails.application.config.db_like
    attribute_table, attribute_name = block_condition[:name].split('.')

    # get tables to join
    return if !attribute_name
    return if !attribute_table

    if attribute_table && attribute_table != 'execution_time' && tables.exclude?(attribute_table) && !(attribute_table == 'ticket' && attribute_name != 'mention_user_ids') && !(attribute_table == 'ticket' && attribute_name == 'mention_user_ids' && block_condition[:pre_condition] == 'not_set')
      case attribute_table
      when 'customer'
        tables         |= ['users customers']
        tables_query   |= ['tickets.customer_id = customers.id']
      when 'organization'
        tables         |= ['organizations']
        tables_query   |= ['tickets.organization_id = organizations.id']
      when 'owner'
        tables         |= ['users owners']
        tables_query   |= ['tickets.owner_id = owners.id']
      when 'article'
        tables         |= ['ticket_articles articles']
        tables_query   |= ['tickets.id = articles.ticket_id']
      when 'ticket_state'
        tables         |= ['ticket_states']
        tables_query   |= ['tickets.state_id = ticket_states.id']
      when 'ticket'
        if attribute_name == 'mention_user_ids'
          tables       |= ['mentions']
          tables_query |= ["tickets.id = mentions.mentionable_id AND mentions.mentionable_type = 'Ticket'"]
        end
      else
        raise "invalid selector #{attribute_table}, #{attribute_name}"
      end
    end

    # validation
    raise "Invalid block_condition, operator missing #{block_condition.inspect}" if !block_condition[:operator]
    raise "Invalid block_condition, operator #{block_condition[:operator]} is invalid #{block_condition.inspect}" if !block_condition[:operator].match?(%r{^(has changed|is|is\snot|contains|contains\s(not|all|one|all\snot|one\snot)|today|(after|before)\s\(absolute\)|(within\snext|within\slast|after|before|till|from)\s\(relative\))|(is\sin\sworking\stime|is\snot\sin\sworking\stime)$})

    # validate value / allow blank but only if pre_condition exists and is not specific
    if block_condition[:operator] != 'has changed' && ((block_condition[:operator] != 'today' && !block_condition.key?(:value)) ||
       (block_condition[:value].instance_of?(Array) && block_condition[:value].respond_to?(:blank?) && block_condition[:value].blank?) ||
       (block_condition[:operator].start_with?('contains') && block_condition[:value].respond_to?(:blank?) && block_condition[:value].blank?))
      raise InvalidCondition, "Invalid condition pre_condition nil #{block_condition}!" if block_condition[:pre_condition].nil?
      raise InvalidCondition, "Invalid condition pre_condition blank #{block_condition}!" if block_condition[:pre_condition].respond_to?(:blank?) && block_condition[:pre_condition].blank?
      raise InvalidCondition, "Invalid condition pre_condition specific #{block_condition}!" if block_condition[:pre_condition] == 'specific'
    end

    # validate pre_condition values
    raise InvalidCondition, "Invalid condition pre_condition not set #{block_condition}!" if block_condition[:operator] != 'has changed' && block_condition[:pre_condition] && block_condition[:pre_condition] !~ %r{^(not_set|current_user\.|specific)}

    # get attributes
    attribute = "#{ActiveRecord::Base.connection.quote_table_name("#{attribute_table}s")}.#{ActiveRecord::Base.connection.quote_column_name(attribute_name)}"

    # magic block_condition
    if attribute_table == 'ticket' && attribute_name == 'out_of_office_replacement_id'
      attribute = "#{ActiveRecord::Base.connection.quote_table_name("#{attribute_table}s")}.#{ActiveRecord::Base.connection.quote_column_name('owner_id')}"
    end

    if attribute_table == 'ticket' && attribute_name == 'tags'
      block_condition[:value] = block_condition[:value].split(',').collect(&:strip)
    end

    #
    # checks
    #

    if attribute_table == 'article' && options.key?(:article_id) && options[:article_id].blank?
      query << '1 = 0'
    elsif block_condition[:operator].include?('in working time')
      raise __('Please enable execution_time feature to use it (currently only allowed for triggers and schedulers)') if !options[:execution_time]

      biz = Calendar.lookup(id: block_condition[:value])&.biz
      query << if biz.present? && attribute_name == 'calendar_id' && ((block_condition[:operator] == 'is in working time' && !biz.in_hours?(Time.zone.now)) || (block_condition[:operator] == 'is not in working time' && biz.in_hours?(Time.zone.now)))
                 '1 = 0'
               else
                 '1 = 1'
               end

    elsif block_condition[:operator] == 'has changed'
      query << if changed_attributes[ block_condition[:name] ]
                 '1 = 1'
               else
                 '1 = 0'
               end

    elsif attribute_table == 'ticket' && attribute_name == 'action'
      check = options[:ticket_action] == block_condition[:value] ? 1 : 0

      query << if block_condition[:value] == 'update' && check && changed_attributes.blank?
                 '1 = 0'
               elsif block_condition[:operator] == 'is'
                 "1 = #{check}"
               else
                 "0 = #{check}" # is not
               end

    # because of no grouping support we select not_set by sub select for mentions
    elsif attribute_table == 'ticket' && attribute_name == 'mention_user_ids'
      if block_condition[:pre_condition] == 'not_set'
        query << if block_condition[:operator] == 'is'
                   "(SELECT 1 FROM mentions mentions_sub WHERE mentions_sub.mentionable_type = 'Ticket' AND mentions_sub.mentionable_id = tickets.id) IS NULL"
                 else
                   "1 = (SELECT 1 FROM mentions mentions_sub WHERE mentions_sub.mentionable_type = 'Ticket' AND mentions_sub.mentionable_id = tickets.id)"
                 end
      else
        query << if block_condition[:operator] == 'is'
                   'mentions.user_id IN (?)'
                 else
                   'mentions.user_id NOT IN (?)'
                 end
        if block_condition[:pre_condition] == 'current_user.id'
          bind_params.push current_user_id
        else
          bind_params.push block_condition[:value]
        end
      end
    elsif block_condition[:operator] == 'is'
      if block_condition[:pre_condition] == 'not_set'
        if attribute_name.match?(%r{^(created_by|updated_by|owner|customer|user)_id})
          query << "(#{attribute} IS NULL OR #{attribute} IN (?))"
          bind_params.push 1
        else
          query << "#{attribute} IS NULL"
        end
      elsif block_condition[:pre_condition] == 'current_user.id'
        raise "Use current_user.id in block_condition, but no current_user is set #{block_condition.inspect}" if !current_user_id

        query << "#{attribute} IN (?)"
        if attribute_name == 'out_of_office_replacement_id'
          bind_params.push User.find(current_user_id).out_of_office_agent_of.pluck(:id)
        else
          bind_params.push current_user_id
        end
      elsif block_condition[:pre_condition] == 'current_user.organization_id'
        raise "Use current_user.id in block_condition, but no current_user is set #{block_condition.inspect}" if !current_user_id

        query << "#{attribute} IN (?)"
        user = User.find_by(id: current_user_id)
        bind_params.push user.all_organization_ids
      else
        # rubocop:disable Style/IfInsideElse, Metrics/BlockNesting
        if block_condition[:value].nil?
          query << "#{attribute} IS NULL"
        else
          if attribute_name == 'out_of_office_replacement_id'
            query << "#{attribute} IN (?)"
            bind_params.push User.find(block_condition[:value]).out_of_office_agent_of.pluck(:id)
          else
            if block_condition[:value].class != Array
              block_condition[:value] = [block_condition[:value]]
            end
            query << if block_condition[:value].include?('')
                       "(#{attribute} IN (?) OR #{attribute} IS NULL)"
                     else
                       "#{attribute} IN (?)"
                     end
            bind_params.push block_condition[:value]
          end
        end
        # rubocop:enable Style/IfInsideElse, Metrics/BlockNesting
      end
    elsif block_condition[:operator] == 'is not'
      if block_condition[:pre_condition] == 'not_set'
        if attribute_name.match?(%r{^(created_by|updated_by|owner|customer|user)_id})
          query << "(#{attribute} IS NOT NULL AND #{attribute} NOT IN (?))"
          bind_params.push 1
        else
          query << "#{attribute} IS NOT NULL"
        end
      elsif block_condition[:pre_condition] == 'current_user.id'
        query << "(#{attribute} IS NULL OR #{attribute} NOT IN (?))"
        if attribute_name == 'out_of_office_replacement_id'
          bind_params.push User.find(current_user_id).out_of_office_agent_of.pluck(:id)
        else
          bind_params.push current_user_id
        end
      elsif block_condition[:pre_condition] == 'current_user.organization_id'
        query << "(#{attribute} IS NULL OR #{attribute} NOT IN (?))"
        user = User.find_by(id: current_user_id)
        bind_params.push user.organization_id
      else
        # rubocop:disable Style/IfInsideElse, Metrics/BlockNesting
        if block_condition[:value].nil?
          query << "#{attribute} IS NOT NULL"
        else
          if attribute_name == 'out_of_office_replacement_id'
            bind_params.push User.find(block_condition[:value]).out_of_office_agent_of.pluck(:id)
            query << "(#{attribute} IS NULL OR #{attribute} NOT IN (?))"
          else
            if block_condition[:value].class != Array
              block_condition[:value] = [block_condition[:value]]
            end
            query << if block_condition[:value].include?('')
                       "(#{attribute} IS NOT NULL AND #{attribute} NOT IN (?))"
                     else
                       "(#{attribute} IS NULL OR #{attribute} NOT IN (?))"
                     end
            bind_params.push block_condition[:value]
          end
        end
        # rubocop:enable Style/IfInsideElse, Metrics/BlockNesting
      end
    elsif block_condition[:operator] == 'contains'
      query << "#{attribute} #{like} (?)"
      value = "%#{block_condition[:value]}%"
      bind_params.push value
    elsif block_condition[:operator] == 'contains not'
      query << "#{attribute} NOT #{like} (?)"
      value = "%#{block_condition[:value]}%"
      bind_params.push value
    elsif block_condition[:operator] == 'contains all'
      if attribute_table == 'ticket' && attribute_name == 'tags'
        query << "? = (
                                              SELECT
                                                COUNT(*)
                                              FROM
                                                tag_objects,
                                                tag_items,
                                                tags
                                              WHERE
                                                tickets.id = tags.o_id AND
                                                tag_objects.id = tags.tag_object_id AND
                                                tag_objects.name = 'Ticket' AND
                                                tag_items.id = tags.tag_item_id AND
                                                tag_items.name IN (?)
                                            )"
        bind_params.push block_condition[:value].count
        bind_params.push block_condition[:value]
      elsif Ticket.column_names.include?(attribute_name)
        query << SqlHelper.new(object: Ticket).array_contains_all(attribute_name, block_condition[:value])
      end
    elsif block_condition[:operator] == 'contains one' && attribute_table == 'ticket'
      if attribute_name == 'tags'
        tables |= %w[tag_objects tag_items tags]
        query << "
          tickets.id = tags.o_id AND
          tag_objects.id = tags.tag_object_id AND
          tag_objects.name = 'Ticket' AND
          tag_items.id = tags.tag_item_id AND
          tag_items.name IN (?)"

        bind_params.push block_condition[:value]
      elsif Ticket.column_names.include?(attribute_name)
        query << SqlHelper.new(object: Ticket).array_contains_one(attribute_name, block_condition[:value])
      end
    elsif block_condition[:operator] == 'contains all not' && attribute_table == 'ticket'
      if attribute_name == 'tags'
        query << "0 = (
                        SELECT
                          COUNT(*)
                        FROM
                          tag_objects,
                          tag_items,
                          tags
                        WHERE
                          tickets.id = tags.o_id AND
                          tag_objects.id = tags.tag_object_id AND
                          tag_objects.name = 'Ticket' AND
                          tag_items.id = tags.tag_item_id AND
                          tag_items.name IN (?)
                      )"
        bind_params.push block_condition[:value]
      elsif Ticket.column_names.include?(attribute_name)
        query << SqlHelper.new(object: Ticket).array_contains_all(attribute_name, block_condition[:value], negated: true)
      end
    elsif block_condition[:operator] == 'contains one not' && attribute_table == 'ticket'
      if attribute_name == 'tags'
        query << "(
                    SELECT
                      COUNT(*)
                    FROM
                      tag_objects,
                      tag_items,
                      tags
                    WHERE
                      tickets.id = tags.o_id AND
                      tag_objects.id = tags.tag_object_id AND
                      tag_objects.name = 'Ticket' AND
                      tag_items.id = tags.tag_item_id AND
                      tag_items.name IN (?)
                  ) BETWEEN 0 AND 0"
        bind_params.push block_condition[:value]
      elsif Ticket.column_names.include?(attribute_name)
        query << SqlHelper.new(object: Ticket).array_contains_one(attribute_name, block_condition[:value], negated: true)
      end
    elsif block_condition[:operator] == 'today'
      Time.use_zone(Setting.get('timezone_default_sanitized').presence) do
        day_start = Time.zone.now.beginning_of_day.utc
        day_end   = Time.zone.now.end_of_day.utc

        query << "#{attribute} BETWEEN ? AND ?"
        bind_params.push day_start
        bind_params.push day_end
      end
    elsif block_condition[:operator] == 'before (absolute)'
      query << "#{attribute} <= ?"
      bind_params.push block_condition[:value]
    elsif block_condition[:operator] == 'after (absolute)'
      query << "#{attribute} >= ?"
      bind_params.push block_condition[:value]
    elsif block_condition[:operator] == 'within last (relative)'
      query << "#{attribute} BETWEEN ? AND ?"
      time = range(block_condition).ago
      bind_params.push time
      bind_params.push Time.zone.now
    elsif block_condition[:operator] == 'within next (relative)'
      query << "#{attribute} BETWEEN ? AND ?"
      time = range(block_condition).from_now
      bind_params.push Time.zone.now
      bind_params.push time
    elsif block_condition[:operator] == 'before (relative)'
      query << "#{attribute} <= ?"
      time = range(block_condition).ago
      bind_params.push time
    elsif block_condition[:operator] == 'after (relative)'
      query << "#{attribute} >= ?"
      time = range(block_condition).from_now
      bind_params.push time
    elsif block_condition[:operator] == 'till (relative)'
      query << "#{attribute} <= ?"
      time = range(block_condition).from_now
      bind_params.push time
    elsif block_condition[:operator] == 'from (relative)'
      query << "#{attribute} >= ?"
      time = range(block_condition).ago
      bind_params.push time
    else
      raise "Invalid operator '#{block_condition[:operator]}' for '#{block_condition[:value].inspect}'"
    end

    [query, bind_params, tables, tables_query]
  end

  def range(selector)
    selector[:value].to_i.send(selector[:range].pluralize)
  rescue
    raise 'unknown selector'
  end
end
