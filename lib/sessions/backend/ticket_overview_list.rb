# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Backend::TicketOverviewList < Sessions::Backend::Base

  def self.reset(user_id)
    Cache.write("TicketOverviewPull::#{user_id}", { needed: true })
  end

  def initialize(user, asset_lookup, client = nil, client_id = nil, ttl = 7) # rubocop:disable Lint/MissingSuper
    @user                 = user
    @client               = client
    @client_id            = client_id
    @ttl                  = ttl
    @asset_lookup         = asset_lookup
    @last_index_lists     = nil
    @last_overview        = {}
    @last_overview_change = nil
    @last_ticket_change   = nil
    @last_full_fetch      = nil
  end

  def self.overview_history_append(overview, user_id)
    key = "TicketOverviewHistory::#{user_id}"
    history = Cache.read(key) || []

    history.prepend overview
    history.uniq!
    if history.count > 4
      history.pop
    end

    Cache.write(key, history)
  end

  def self.overview_history_get(user_id)
    Cache.read("TicketOverviewHistory::#{user_id}")
  end

  def load

    # get whole collection
    index_and_lists = nil
    local_overview_changed = overview_changed?
    if !@last_index_lists || !@last_full_fetch || @last_full_fetch < (Time.zone.now.to_i - 60) || local_overview_changed

      # check if min one ticket has changed
      return if !ticket_changed?(true) && !local_overview_changed

      index_and_lists  = Ticket::Overviews.index(@user)
      @last_full_fetch = Time.zone.now.to_i
    else

      # check if min one ticket has changed
      return if !ticket_changed? && !local_overview_changed

      index_and_lists_local = Ticket::Overviews.index(@user, Sessions::Backend::TicketOverviewList.overview_history_get(@user.id))

      # compare index_and_lists_local to index_and_lists_local
      # return if no changes

      index_and_lists = []
      @last_index_lists.each do |last_index|
        found_in_particular_index = false
        index_and_lists_local.each do |local_index|
          next if local_index[:overview][:id] != last_index[:overview][:id]

          index_and_lists.push local_index
          found_in_particular_index = true
          break
        end
        next if found_in_particular_index == true

        index_and_lists.push last_index
      end
    end

    # no data exists
    return if index_and_lists.blank?

    # no change exists
    return if @last_index_lists == index_and_lists

    # remember last state
    @last_index_lists = index_and_lists

    index_and_lists
  end

  def local_to_run?
    return false if !@time_now

    return true if pull_overview?

    false
  end

  def pull_overview?
    result = Cache.read("TicketOverviewPull::#{@user.id}")
    Cache.delete("TicketOverviewPull::#{@user.id}") if result
    return true if result

    false
  end

  def push
    return if !to_run? && !local_to_run?

    @time_now = Time.zone.now.to_i

    # load current data
    index_and_lists = load
    return if !index_and_lists

    # push overview index
    indexes = []
    index_and_lists.each do |index|
      overview = Overview.lookup(id: index[:overview][:id])
      next if !overview

      meta = {
        name:  overview.name,
        prio:  overview.prio,
        link:  overview.link,
        count: index[:count],
      }
      indexes.push meta
    end
    if @client
      @client.log "push overview_index for user #{@user.id}"
      @client.send(
        event: 'ticket_overview_index',
        data:  indexes,
      )
    end

    @time_now = Time.zone.now.to_i

    # push overviews
    results = []
    assets  = AssetsSet.new
    index_and_lists.each do |data|

      # do not deliver unchanged lists
      next if @last_overview[data[:overview][:id]] == [data[:tickets], data[:overview]]

      @last_overview[data[:overview][:id]] = [data[:tickets], data[:overview]]

      overview = Overview.lookup(id: data[:overview][:id])
      next if !overview

      if asset_needed?(overview)
        assets = asset_push(overview, assets)
      end
      data[:tickets].each do |ticket_meta|
        next if !asset_needed_by_updated_at?('Ticket', ticket_meta[:id], ticket_meta[:updated_at])

        ticket = Ticket.lookup(id: ticket_meta[:id])
        next if !ticket

        assets = asset_push(ticket, assets)
      end

      data[:assets] = assets.to_h

      if @client
        @client.log "push overview_list #{overview.link} for user #{@user.id}"

        # send update to browser
        @client.send(
          event: 'ticket_overview_list',
          data:  data,
        )
      else
        result = {
          event: 'ticket_overview_list',
          data:  data,
        }
        results.push result
      end

      assets.flush
    end
    return results if !@client

    nil
  end

  def overview_changed?

    # check if min one overview has changed
    last_overview_change = Overview.latest_change
    return false if last_overview_change == @last_overview_change

    @last_overview_change = last_overview_change

    true
  end

  def ticket_changed?(reset = false)

    # check if min one ticket has changed
    last_ticket_change = Ticket.latest_change
    return false if last_ticket_change == @last_ticket_change

    @last_ticket_change = last_ticket_change if reset

    true
  end

end
