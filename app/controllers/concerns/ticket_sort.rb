module TicketSort
  extend ActiveSupport::Concern

  def ticket_sort(query)
    offset = 0
    per_page = 100

    if params[:page] && params[:per_page]
      offset = (params[:page].to_i - 1) * params[:per_page].to_i
      per_page = params[:per_page].to_i
    end

    if per_page > 100
      per_page = 100
    end

    access_condition = Ticket.access_condition(current_user, 'read')
    tickets = Ticket.where(access_condition).where(query).order(id: 'ASC').offset(offset).limit(per_page)

    if params[:expand]
      list = []
      tickets.each { |ticket|
        list.push ticket.attributes_with_association_names
      }
      render json: list, status: :ok
      return
    end

    if params[:full]
      assets = {}
      item_ids = []
      tickets.each { |item|
        item_ids.push item.id
        assets = item.assets(assets)
      }
      render json: {
        record_ids: item_ids,
        assets: assets,
      }, status: :ok
      return
    end

    render json: tickets
  end
end
