# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Report::Base

  # :object
  # :type created|updated
  # :attribute
  # :value_from
  # :value_to
  # :start
  # :end
  # :selector
  def self.history_count(params)

    history_object = History::Object.lookup(name: params[:object])

    query, bind_params, tables = Ticket.selector2sql(params[:selector])

    # created
    if params[:type] == 'created'
      history_type = History::Type.lookup(name: 'created')
      return History.select('histories.o_id').joins('INNER JOIN tickets ON tickets.id = histories.o_id')
                    .where(
                      'histories.created_at >= ? AND histories.created_at <= ? AND histories.history_object_id = ? AND histories.history_type_id = ?', params[:start], params[:end], history_object.id, history_type.id
                    )
                    .where(query, *bind_params).joins(tables).count
    end

    # updated
    if params[:type] == 'updated'
      history_type      = History::Type.lookup(name: 'updated')
      history_attribute = History::Attribute.lookup(name: params[:attribute])

      result = nil
      if !history_attribute || !history_type
        result = 0
      elsif params[:id_not_from] && params[:id_to]
        result = History.select('histories.o_id').joins('INNER JOIN tickets ON tickets.id = histories.o_id')
                        .where(query, *bind_params).joins(tables)
                        .where(
                          'histories.created_at >= ? AND histories.created_at <= ? AND histories.history_object_id = ? AND histories.history_type_id = ? AND histories.history_attribute_id IN (?) AND histories.id_from NOT IN (?) AND histories.id_to IN (?)',
                          params[:start],
                          params[:end],
                          history_object.id,
                          history_type.id,
                          history_attribute.id,
                          params[:id_not_from],
                          params[:id_to],
                        ).count
      elsif params[:id_from] && params[:id_not_to]
        result = History.select('histories.o_id').joins('INNER JOIN tickets ON tickets.id = histories.o_id')
                        .where(query, *bind_params).joins(tables)
                        .where(
                          'histories.created_at >= ? AND histories.created_at <= ? AND histories.history_object_id = ? AND histories.history_type_id = ? AND histories.history_attribute_id IN (?) AND histories.id_from IN (?) AND histories.id_to NOT IN (?)',
                          params[:start],
                          params[:end],
                          history_object.id,
                          history_type.id,
                          history_attribute.id,
                          params[:id_from],
                          params[:id_not_to],
                        ).count
      elsif params[:value_from] && params[:value_not_to]
        result = History.joins('INNER JOIN tickets ON tickets.id = histories.o_id')
                        .where(query, *bind_params).joins(tables)
                        .where(
                          'histories.created_at >= ? AND histories.created_at <= ? AND histories.history_object_id = ? AND histories.history_type_id = ? AND histories.history_attribute_id IN (?) AND histories.value_from IN (?) AND histories.value_to NOT IN (?)',
                          params[:start],
                          params[:end],
                          history_object.id,
                          history_type.id,
                          history_attribute.id,
                          params[:value_from],
                          params[:value_not_to],
                        ).count
      elsif params[:value_to]
        result = History.select('histories.o_id').joins('INNER JOIN tickets ON tickets.id = histories.o_id')
                        .where(query, *bind_params).joins(tables)
                        .where(
                          'histories.created_at >= ? AND histories.created_at <= ? AND histories.history_object_id = ? AND histories.history_type_id = ? AND histories.history_attribute_id IN (?) AND histories.value_to IN (?)',
                          params[:start],
                          params[:end],
                          history_object.id,
                          history_type.id,
                          history_attribute.id,
                          params[:value_to],
                        ).count
      elsif params[:id_to]
        result = History.select('histories.o_id').joins('INNER JOIN tickets ON tickets.id = histories.o_id')
                        .where(query, *bind_params).joins(tables)
                        .where(
                          'histories.created_at >= ? AND histories.created_at <= ? AND histories.history_object_id = ? AND histories.history_type_id = ? AND histories.history_attribute_id IN (?) AND histories.id_to IN (?)',
                          params[:start],
                          params[:end],
                          history_object.id,
                          history_type.id,
                          history_attribute.id,
                          params[:id_to],
                        ).count
      end

      return result if !result.nil?

      raise "UNKOWN params (#{params.inspect})!"
    end
    raise "UNKOWN :type (#{params[:type]})!"
  end

  # :object
  # :type created|updated
  # :attribute
  # :value_from
  # :value_to
  # :start
  # :end
  # :condition
  def self.history(data)

    history_object = History::Object.lookup(name: data[:object])

    query, bind_params, tables = Ticket.selector2sql(data[:selector])

    count = 0
    ticket_ids = []

    # created
    if data[:type] == 'created'
      history_type = History::Type.lookup(name: 'created')
      histories = History.select('histories.o_id').joins('INNER JOIN tickets ON tickets.id = histories.o_id')
                         .where(
                           'histories.created_at >= ? AND histories.created_at <= ? AND histories.history_object_id = ? AND histories.history_type_id = ?', data[:start], data[:end], history_object.id, history_type.id
                         )
                         .where(query, *bind_params).joins(tables)
      histories.each do |history|
        count += 1
        ticket_ids.push history.o_id
      end
      return {
        count:      count,
        ticket_ids: ticket_ids,
      }
    end

    # updated
    if data[:type] == 'updated'
      history_type      = History::Type.lookup(name: 'updated')
      history_attribute = History::Attribute.lookup(name: data[:attribute])
      if !history_attribute || !history_type
        count = 0
      else
        if data[:id_not_from] && data[:id_to]
          histories = History.select('histories.o_id').joins('INNER JOIN tickets ON tickets.id = histories.o_id')
                             .where(query, *bind_params).joins(tables)
                             .where(
                               'histories.created_at >= ? AND histories.created_at <= ? AND histories.history_object_id = ? AND histories.history_type_id = ? AND histories.history_attribute_id IN (?) AND histories.id_from NOT IN (?) AND histories.id_to IN (?)',
                               data[:start],
                               data[:end],
                               history_object.id,
                               history_type.id,
                               history_attribute.id,
                               data[:id_not_from],
                               data[:id_to],
                             )
        elsif data[:id_from] && data[:id_not_to]
          histories = History.select('histories.o_id').joins('INNER JOIN tickets ON tickets.id = histories.o_id')
                             .where(query, *bind_params).joins(tables)
                             .where(
                               'histories.created_at >= ? AND histories.created_at <= ? AND histories.history_object_id = ? AND histories.history_type_id = ? AND histories.history_attribute_id IN (?) AND histories.id_from IN (?) AND histories.id_to NOT IN (?)',
                               data[:start],
                               data[:end],
                               history_object.id,
                               history_type.id,
                               history_attribute.id,
                               data[:id_from],
                               data[:id_not_to],
                             )
        elsif data[:value_from] && data[:value_not_to]
          histories = History.joins('INNER JOIN tickets ON tickets.id = histories.o_id')
                             .where(query, *bind_params).joins(tables)
                             .where(
                               'histories.created_at >= ? AND histories.created_at <= ? AND histories.history_object_id = ? AND histories.history_type_id = ? AND histories.history_attribute_id IN (?) AND histories.value_from IN (?) AND histories.value_to NOT IN (?)',
                               data[:start],
                               data[:end],
                               history_object.id,
                               history_type.id,
                               history_attribute.id,
                               data[:value_from],
                               data[:value_not_to],
                             )
        elsif data[:value_to]
          histories = History.select('histories.o_id').joins('INNER JOIN tickets ON tickets.id = histories.o_id')
                             .where(query, *bind_params).joins(tables)
                             .where(
                               'histories.created_at >= ? AND histories.created_at <= ? AND histories.history_object_id = ? AND histories.history_type_id = ? AND histories.history_attribute_id IN (?) AND histories.value_to IN (?)',
                               data[:start],
                               data[:end],
                               history_object.id,
                               history_type.id,
                               history_attribute.id,
                               data[:value_to],
                             )
        elsif data[:id_to]
          histories = History.select('histories.o_id').joins('INNER JOIN tickets ON tickets.id = histories.o_id')
                             .where(query, *bind_params).joins(tables)
                             .where(
                               'histories.created_at >= ? AND histories.created_at <= ? AND histories.history_object_id = ? AND histories.history_type_id = ? AND histories.history_attribute_id IN (?) AND histories.id_to IN (?)',
                               data[:start],
                               data[:end],
                               history_object.id,
                               history_type.id,
                               history_attribute.id,
                               data[:id_to],
                             )
        end
        histories.each do |history|
          count += 1
          ticket_ids.push history.o_id
        end
      end
      return {
        count:      count,
        ticket_ids: ticket_ids,
      }
    end
    raise "UNKOWN :type (#{data[:type]})!"
  end

  # :type
  # :start
  # :end
  # :condition
  def self.time_average(data)
    query, bind_params, tables = Ticket.selector2sql(data[:condition])
    ticket_list = Ticket.where('tickets.created_at >= ? AND tickets.created_at <= ?', data[:start], data[:end])
                        .where(query, *bind_params).joins(tables)
    tickets = 0
    time_total = 0
    ticket_list.each do |ticket|
      timestamp = ticket[ data[:type].to_sym ]
      next if !timestamp

      #          puts 'FR:' + first_response.to_s
      #          puts 'CT:' + ticket.created_at.to_s
      diff = timestamp - ticket.created_at
      #puts 'DIFF:' + diff.to_s
      time_total = time_total + diff
      tickets += 1
    end
    if time_total.zero? || tickets.zero?
      tickets = -0.001
    else
      tickets = time_total / tickets / 60
      tickets = tickets.to_i
    end
    {
      count: tickets,
    }
  end

  # :type
  # :start
  # :end
  # :condition
  def self.time_min(data)
    query, bind_params, tables = Ticket.selector2sql(data[:condition])
    ticket_list = Ticket.where('tickets.created_at >= ? AND tickets.created_at <= ?', data[:start], data[:end])
                        .where(query, *bind_params).joins(tables)
    time_min = 0
    ticket_ids = []
    ticket_list.each do |ticket|
      timestamp = ticket[ data[:type].to_sym ]
      next if !timestamp

      ticket_ids.push ticket.id
      #          puts 'FR:' + first_response.to_s
      #          puts 'CT:' + ticket.created_at.to_s
      diff = timestamp - ticket.created_at
      #puts 'DIFF:' + diff.to_s
      if !time_min
        time_min = diff
      end
      if diff < time_min
        time_min = diff
      end
    end
    tickets = if time_min.zero?
                -0.001
              else
                (time_min / 60).to_i
              end
    {
      count:      tickets,
      ticket_ids: ticket_ids,
    }
  end

  # :type
  # :start
  # :end
  # :condition
  def self.time_max(data)
    query, bind_params, tables = Ticket.selector2sql(data[:condition])
    ticket_list = Ticket.where('tickets.created_at >= ? AND tickets.created_at <= ?', data[:start], data[:end])
                        .where(query, *bind_params).joins(tables)
    time_max = 0
    ticket_ids = []
    ticket_list.each do |ticket|
      timestamp = ticket[ data[:type].to_sym ]
      next if !timestamp

      ticket_ids.push ticket.id
      #        puts "#{data[:type].to_s} - #{timestamp} - #{ticket.inspect}"
      #          puts 'FR:' + ticket.first_response.to_s
      #          puts 'CT:' + ticket.created_at.to_s
      diff = timestamp - ticket.created_at
      #puts 'DIFF:' + diff.to_s
      if !time_max
        time_max = diff
      end
      if diff > time_max
        time_max = diff
      end
    end
    tickets = if time_max.zero?
                -0.001
              else
                (time_max / 60).to_i
              end
    {
      count:      tickets,
      ticket_ids: ticket_ids,
    }
  end

  def self.ticket_condition(ticket_id, condition)
    ticket = Ticket.lookup( id: ticket_id )
    condition.each do |key, value|
      if ticket[key.to_sym] != value
        return false
      end
    end
    true
  end

end
