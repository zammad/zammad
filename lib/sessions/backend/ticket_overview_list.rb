class Sessions::Backend::TicketOverviewList < Sessions::Backend::Base

  def self.reset(user_id)
    Cache.write("TicketOverviewPull::#{user_id}", { needed: true })
  end

  def initialize(user, asset_lookup, client = nil, client_id = nil, ttl = 8)
    @user                 = user
    @client               = client
    @client_id            = client_id
    @ttl                  = ttl
    @asset_lookup         = asset_lookup
    @last_change          = nil
    @last_overview        = {}
    @last_overview_change = nil
    @last_ticket_change   = nil
  end

  def load

    # get whole collection
    index_and_lists = Ticket::Overviews.index(@user)

    # no data exists
    return if index_and_lists.blank?

    # no change exists
    return if @last_change == index_and_lists

    # remember last state
    @last_change = index_and_lists

    index_and_lists
  end

  def local_to_run?
    return false if !@time_now

    result = Cache.get("TicketOverviewPull::#{@user.id}")
    Cache.delete("TicketOverviewPull::#{@user.id}") if result
    return true if result

    false
  end

  def push
    return if !to_run? && !local_to_run?

    @time_now = Time.zone.now.to_i

    # check if min one ticket or overview has changed
    last_overview_change = Overview.latest_change
    last_ticket_change = Ticket.latest_change
    return if last_ticket_change == @last_ticket_change && last_overview_change == @last_overview_change

    @last_overview_change = last_overview_change
    @last_ticket_change = last_ticket_change

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
    index_and_lists.each do |data|

      # do not deliver unchanged lists
      next if @last_overview[data[:overview][:id]] == [data[:tickets], data[:overview]]

      @last_overview[data[:overview][:id]] = [data[:tickets], data[:overview]]

      assets = {}
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
      data[:assets] = assets

      if !@client
        result = {
          event: 'ticket_overview_list',
          data:  data,
        }
        results.push result
      else
        @client.log "push overview_list #{overview.link} for user #{@user.id}"

        # send update to browser
        @client.send(
          event: 'ticket_overview_list',
          data:  data,
        )
      end
    end
    return results if !@client

    nil
  end

end
