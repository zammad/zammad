# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Ticket::Selector::Sql < Ticket::Selector::Base
  VALID_OPERATORS = [
    'has changed',
    'has reached',
    'has reached warning',
    'is',
    'is not',
    'contains',
    %r{contains (not|all|one|all not|one not)},
    'today',
    %r{(after|before) \(absolute\)},
    %r{(within next|within last|after|before|till|from) \(relative\)},
    'is in working time',
    'is not in working time',
    'starts with',        # keep for compatibility with old conditions
    'ends with',          # keep for compatibility with old conditions
    'matches regex',
    'does not match regex',

    # Operators with multiple values
    'starts with one of',
    'ends with one of',
    'is any of',
    'is none of',
  ].freeze

  attr_accessor :final_query, :final_bind_params, :final_tables, :changed_attributes

  def get
    @final_query        = []
    @final_bind_params  = []
    @final_tables       = []
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
    Array(final_query).join(' AND ')
  end

  def tables_sql
    return '' if final_tables.blank?

    " #{final_tables.join(' ')}"
  end

  def run(block, level)
    if block.key?(:conditions)
      run_block(block, level)
    else
      query, bind_params, tables = condition_sql(block)
      @final_bind_params                   += bind_params
      @final_tables                        |= tables
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
    bind_params                     = []
    like                            = Rails.application.config.db_like
    attribute_table, attribute_name = block_condition[:name].split('.')

    # get tables to join
    return if !attribute_name
    return if !attribute_table

    sql_helper = SqlHelper.new(object: Ticket)
    if attribute_table && attribute_table != 'execution_time' && tables.exclude?(attribute_table) && !(attribute_table == 'ticket' && attribute_name != 'mention_user_ids') && !(attribute_table == 'ticket' && attribute_name == 'mention_user_ids' && block_condition[:pre_condition] == 'not_set') && !(attribute_table == 'article' && attribute_name == 'action')
      case attribute_table
      when 'customer'
        tables         |= ['INNER JOIN users customers ON tickets.customer_id = customers.id']
        sql_helper      = SqlHelper.new(object: User, table_name: 'customers')
      when 'organization'
        tables         |= ['LEFT JOIN organizations ON tickets.organization_id = organizations.id']
        sql_helper      = SqlHelper.new(object: Organization)
      when 'owner'
        tables         |= ['INNER JOIN users owners ON tickets.owner_id = owners.id']
        sql_helper      = SqlHelper.new(object: User, table_name: 'owners')
      when 'article'
        tables         |= ['INNER JOIN ticket_articles articles ON tickets.id = articles.ticket_id']
        sql_helper      = SqlHelper.new(object: Ticket::Article)
      when 'ticket_state'
        tables         |= ['INNER JOIN ticket_states ON tickets.state_id = ticket_states.id']
        sql_helper      = SqlHelper.new(object: Ticket::State)
      when 'ticket'
        if attribute_name == 'mention_user_ids'
          tables |= ["LEFT JOIN mentions ON tickets.id = mentions.mentionable_id AND mentions.mentionable_type = 'Ticket'"]
        end
      else
        raise "invalid selector #{attribute_table}, #{attribute_name}"
      end
    end

    validate_operator! block_condition

    validate_pre_condition_blank! block_condition

    validate_pre_condition_values! block_condition

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
    #

    if attribute_table == 'article' && options.key?(:article_id) && options[:article_id].blank? && attribute_name != 'action'
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

    elsif block_condition[:operator] == 'has reached'
      query << if time_based_trigger?(block_condition, warning: false)
                 '1 = 1'
               else
                 '1 = 0'
               end

    elsif block_condition[:operator] == 'has reached warning'
      query << if time_based_trigger?(block_condition, warning: true)
                 '1 = 1'
               else
                 '1 = 0'
               end

    elsif attribute_table == 'ticket' && attribute_name == 'action'
      check = options[:ticket_action] == block_condition[:value] ? 1 : 0

      query << if update_action_requires_changed_attributes?(block_condition, check)
                 '1 = 0'
               elsif block_condition[:operator] == 'is'
                 "1 = #{check}"
               else
                 "0 = #{check}" # is not
               end

    elsif attribute_table == 'article' && attribute_name == 'action'
      check = options[:article_id] ? 1 : 0

      query << if block_condition[:operator] == 'is'
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
    elsif block_condition[:operator] == 'starts with'
      query << "#{attribute} #{like} (?)"
      bind_params.push "#{block_condition[:value]}%"
    elsif block_condition[:operator] == 'starts with one of'
      block_condition[:value] = Array.wrap(block_condition[:value])

      sub_query = []
      block_condition[:value].each do |value|
        sub_query << "#{attribute} #{like} (?)"
        bind_params.push "#{value}%"
      end
      query << "(#{sub_query.join(' OR ')})" if sub_query.present?
    elsif block_condition[:operator] == 'ends with'
      query << "#{attribute} #{like} (?)"
      bind_params.push "%#{block_condition[:value]}"
    elsif block_condition[:operator] == 'ends with one of'
      block_condition[:value] = Array.wrap(block_condition[:value])

      sub_query = []
      block_condition[:value].each do |value|
        sub_query << "#{attribute} #{like} (?)"
        bind_params.push "%#{value}"
      end
      query << "(#{sub_query.join(' OR ')})" if sub_query.present?
    elsif block_condition[:operator] == 'is any of'
      block_condition[:value] = Array.wrap(block_condition[:value])

      block_condition[:value] = block_condition[:value].empty? ? [''] : block_condition[:value]

      sub_query = []
      block_condition[:value].each do |value|
        sub_query << "#{attribute} IN (?)"
        bind_params.push value
      end

      query << "(#{sub_query.join(' OR ')})" if sub_query.present?
    elsif block_condition[:operator] == 'is none of'
      block_condition[:value] = Array.wrap(block_condition[:value])

      block_condition[:value] = block_condition[:value].empty? ? [''] : block_condition[:value]

      sub_query = []
      block_condition[:value].each do |value|
        sub_query << "#{attribute} NOT IN (?)"
        bind_params.push value
      end

      query << "(#{sub_query.join(' AND ')})" if sub_query.present?
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
            block_condition[:value] = Array.wrap(block_condition[:value])

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
            block_condition[:value] = Array.wrap(block_condition[:value])

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
      bind_params.push "%#{block_condition[:value]}%"
    elsif block_condition[:operator] == 'contains not'
      query << "#{attribute} NOT #{like} (?)"
      bind_params.push "%#{block_condition[:value]}%"
    elsif block_condition[:operator] == 'matches regex'
      query << sql_helper.regex_match(attribute, negated: false)
      bind_params.push block_condition[:value]
    elsif block_condition[:operator] == 'does not match regex'
      query << sql_helper.regex_match(attribute, negated: true)
      bind_params.push block_condition[:value]
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
      elsif sql_helper.containable?(attribute_name)
        query << sql_helper.array_contains_all(attribute_name, block_condition[:value])
      end
    elsif block_condition[:operator] == 'contains one'
      if attribute_name == 'tags' && attribute_table == 'ticket'
        tables |= ["LEFT JOIN tags ON tickets.id = tags.o_id LEFT JOIN tag_objects ON tag_objects.id = tags.tag_object_id AND tag_objects.name = 'Ticket' LEFT JOIN tag_items ON tag_items.id = tags.tag_item_id"]
        query << 'tag_items.name IN (?)'

        bind_params.push block_condition[:value]
      elsif sql_helper.containable?(attribute_name)
        query << sql_helper.array_contains_one(attribute_name, block_condition[:value])
      end
    elsif block_condition[:operator] == 'contains all not'
      if attribute_name == 'tags' && attribute_table == 'ticket'
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
      elsif sql_helper.containable?(attribute_name)
        query << sql_helper.array_contains_all(attribute_name, block_condition[:value], negated: true)
      end
    elsif block_condition[:operator] == 'contains one not'
      if attribute_name == 'tags' && attribute_table == 'ticket'
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
      elsif sql_helper.containable?(attribute_name)
        query << sql_helper.array_contains_one(attribute_name, block_condition[:value], negated: true)
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

    [query, bind_params, tables]
  end

  def range(selector)
    selector[:value].to_i.send(selector[:range].pluralize)
  rescue
    raise 'unknown selector'
  end

  def validate_operator!(condition)
    if condition[:operator].blank?
      raise "Invalid condition, operator missing #{condition.inspect}"
    end

    return true if self.class.valid_operator? condition[:operator]

    raise "Invalid condition, operator '#{condition[:operator]}' is invalid #{condition.inspect}"
  end

  def time_based_trigger?(condition, warning:)
    case [condition[:name], options[:ticket_action]]
    in 'ticket.pending_time', 'reminder_reached'
      true
    in 'ticket.escalation_at', 'escalation'
      !warning
    in 'ticket.escalation_at', 'escalation_warning'
      warning
    else
      false
    end
  end

  # validate pre_condition values
  def validate_pre_condition_values!(condition)
    return if ['has changed', 'has reached', 'has reached warning'].include? condition[:operator]
    return if condition[:pre_condition].blank?
    return if %w[not_set current_user. specific].any? { |elem| condition[:pre_condition].start_with? elem }

    raise InvalidCondition, "Invalid condition pre_condition not set #{condition}!"
  end

  # validate value / allow blank but only if pre_condition exists and is not specific
  def validate_pre_condition_blank!(condition)
    return if ['has changed', 'has reached', 'has reached warning', 'is any of', 'is none of'].include? condition[:operator]

    if (condition[:operator] != 'today' && !condition.key?(:value)) ||
       (condition[:value].instance_of?(Array) && condition[:value].respond_to?(:blank?) && condition[:value].blank?) ||
       (condition[:operator].start_with?('contains') && condition[:value].respond_to?(:blank?) && condition[:value].blank?)
      raise InvalidCondition, "Invalid condition pre_condition nil #{condition}!" if condition[:pre_condition].nil?
      raise InvalidCondition, "Invalid condition pre_condition blank #{condition}!" if condition[:pre_condition].respond_to?(:blank?) && condition[:pre_condition].blank?
      raise InvalidCondition, "Invalid condition pre_condition specific #{condition}!" if condition[:pre_condition] == 'specific'
    end
  end

  def update_action_requires_changed_attributes?(condition, check)
    condition[:value] == 'update' && check && options[:changes_required] && changed_attributes.blank?
  end

  def self.valid_operator?(operator)
    VALID_OPERATORS.any? { |elem| operator.match? elem }
  end

  def valid?
    ticket_count, _tickets = Ticket.selectors(selector, **options.merge(limit: 1, execution_time: true, ticket_id: 1, access: 'ignore'))
    !ticket_count.nil?
  rescue
    false
  end
end
