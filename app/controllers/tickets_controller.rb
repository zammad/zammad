# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TicketsController < ApplicationController
  include CreatesTicketArticles
  include ClonesTicketArticleAttachments
  include ChecksUserAttributesByCurrentUserPermission
  include CanPaginate

  prepend_before_action -> { authorize! }, only: %i[create import_example import_start ticket_customer ticket_history ticket_related ticket_recent ticket_merge ticket_split]
  prepend_before_action :authentication_check

  # GET /api/v1/tickets
  def index
    paginate_with(max: 100)

    tickets = TicketPolicy::ReadScope.new(current_user).resolve
                                     .reorder(id: :asc)
                                     .offset(pagination.offset)
                                     .limit(pagination.limit)

    if response_expand?
      list = tickets.map(&:attributes_with_association_names)
      render json: list, status: :ok
      return
    end

    if response_full?
      assets = {}
      item_ids = []
      tickets.each do |item|
        item_ids.push item.id
        assets = item.assets(assets)
      end
      render json: {
        record_ids: item_ids,
        assets:     assets,
      }, status: :ok
      return
    end

    render json: tickets
  end

  # GET /api/v1/tickets/1
  def show
    ticket = Ticket.find(params[:id])
    authorize!(ticket)

    auto_assign_ticket(ticket)

    if response_expand?
      result = ticket.attributes_with_association_names
      render json: result, status: :ok
      return
    end

    if response_full?
      full = Ticket.full(params[:id])
      render json: full
      return
    end

    if response_all?
      render json: Ticket::AssetsAll.new(current_user, ticket).all_assets
      return
    end

    render json: ticket
  end

  def auto_assign_ticket(ticket)
    return if params[:auto_assign].blank?

    ticket.auto_assign(current_user)
  end

  # POST /api/v1/tickets
  def create
    ticket = nil

    Transaction.execute do # rubocop:disable Metrics/BlockLength
      customer = {}
      if params[:customer].instance_of?(ActionController::Parameters)
        customer = params[:customer]
        params.delete(:customer)
      end

      if (shared_draft_id = params[:shared_draft_id])
        shared_draft = Ticket::SharedDraftStart.find_by id: shared_draft_id

        if shared_draft && (shared_draft.group_id.to_s != params[:group_id]&.to_s || !shared_draft.group.shared_drafts?)
          raise Exceptions::UnprocessableEntity, __('Shared draft cannot be selected for this ticket.')
        end

        shared_draft&.destroy
      end

      # Prevent direct access to checklist via API
      # Otherwise users may get unauthorized access to checklists of other tickets
      params.delete(:checklist)
      params.delete(:checklist_id)

      clean_params = Ticket.association_name_to_id_convert(params)

      # overwrite params
      if !current_user.permissions?('ticket.agent')
        %i[owner owner_id customer customer_id preferences].each do |key|
          clean_params.delete(key)
        end
        clean_params[:customer_id] = current_user.id
      end

      # The parameter :customer_id is 'abused' in cases where it is not an integer, but a string like
      #   'guess:customers.email@domain.cm' which implies that the customer should be looked up.
      if clean_params[:customer_id].is_a?(String) && clean_params[:customer_id] =~ %r{^guess:(.+?)$}
        email_address = $1
        email_address_validation = EmailAddressValidation.new(email_address)
        if !email_address_validation.valid?
          render json: { error: "Invalid email '#{email_address}' of customer" }, status: :unprocessable_entity
          return
        end
        local_customer = User.find_by(email: email_address.downcase)
        if !local_customer
          role_ids = Role.signup_role_ids
          local_customer = User.create(
            firstname: '',
            lastname:  '',
            email:     email_address,
            password:  '',
            active:    true,
            role_ids:  role_ids,
          )
        end
        clean_params[:customer_id] = local_customer.id
      end

      # try to create customer if needed
      if clean_params[:customer_id].blank? && customer.present?
        check_attributes_by_current_user_permission(customer)
        clean_customer = User.association_name_to_id_convert(customer)
        local_customer = nil
        if !local_customer && clean_customer[:id].present?
          local_customer = User.find_by(id: clean_customer[:id])
        end
        if !local_customer && clean_customer[:email].present?
          local_customer = User.find_by(email: clean_customer[:email].downcase)
        end
        if !local_customer && clean_customer[:login].present?
          local_customer = User.find_by(login: clean_customer[:login].downcase)
        end
        if !local_customer
          role_ids = Role.signup_role_ids
          local_customer = User.new(clean_customer)
          local_customer.role_ids = role_ids
          local_customer.save!
        end
        clean_params[:customer_id] = local_customer.id
      end

      clean_params = Ticket.param_cleanup(clean_params, true)
      clean_params[:screen] = 'create_middle'
      ticket = Ticket.new(clean_params)
      authorize!(ticket, :create?)

      # create ticket
      ticket.save!

      # create tags if given
      if params[:tags].present?
        tags = params[:tags].split(',').map(&:strip)
        tags.each do |tag|
          next if !::Tag.tag_allowed?(name: tag, user_id: UserInfo.current_user_id)

          ticket.tag_add(tag)
        end
      end

      # This mentions handling is used by custom API calls only
      # Mentions created in UI are handled by Ticket::Article#check_mentions
      if params[:mentions].present?
        authorize!(ticket, :create_mentions?)

        Array(params[:mentions]).each do |user_id|
          Mention.subscribe! ticket, User.find(user_id)
        end
      end

      # create article if given
      if params[:article]
        article_create(ticket, params[:article])
      end

      # create links (e. g. in case of ticket split)
      # links: {
      #   Ticket: {
      #     parent: [ticket_id1, ticket_id2, ...]
      #     normal: [ticket_id1, ticket_id2, ...]
      #     child: [ticket_id1, ticket_id2, ...]
      #   },
      # }
      if params[:links].present?
        link = params[:links].permit!.to_h
        raise Exceptions::UnprocessableEntity, __('Invalid link structure') if !link.is_a? Hash

        link.each do |target_object, link_types_with_object_ids|
          raise Exceptions::UnprocessableEntity, __('Invalid link structure (Object)') if !link_types_with_object_ids.is_a? Hash

          link_types_with_object_ids.each do |link_type, object_ids|
            raise Exceptions::UnprocessableEntity, __('Invalid link structure (Object → LinkType)') if !object_ids.is_a? Array

            object_ids.each do |local_object_id|
              link = Link.add(
                link_type:                link_type,
                link_object_target:       target_object,
                link_object_target_value: local_object_id,
                link_object_source:       'Ticket',
                link_object_source_value: ticket.id,
              )
            end
          end
        end
      end
    end

    if response_expand?
      result = ticket.reload.attributes_with_association_names
      render json: result, status: :created
      return
    end

    if response_full?
      full = Ticket.full(ticket.id)
      render json: full, status: :created
      return
    end

    if response_all?
      render json: Ticket::AssetsAll.new(current_user, ticket.reload).all_assets, status: :created
      return
    end

    render json: ticket.reload.attributes_with_association_ids, status: :created
  end

  # PUT /api/v1/tickets/1
  def update
    ticket = Ticket.find(params[:id])
    authorize!(ticket, :follow_up?)

    # Prevent direct access to checklist via API
    # Otherwise users may get unauthorized access to checklists of other tickets
    params.delete(:checklist)
    params.delete(:checklist_id)

    clean_params = Ticket.association_name_to_id_convert(params)
    clean_params = Ticket.param_cleanup(clean_params, true)

    # only apply preferences changes (keep not updated keys/values)
    clean_params = ticket.param_preferences_merge(clean_params)
    clean_params[:screen] = 'edit'

    # disable changes on ticket number
    clean_params.delete('number')

    # overwrite params
    if !current_user.permissions?('ticket.agent')
      %i[owner owner_id customer customer_id organization organization_id preferences].each do |key|
        clean_params.delete(key)
      end
    end

    ticket.with_lock do
      ticket.update!(clean_params)
      if params[:article].present?
        if (shared_draft_id = params[:article][:shared_draft_id])
          shared_draft = Ticket::SharedDraftZoom.find_by id: shared_draft_id

          if shared_draft && shared_draft.ticket != ticket
            raise Exceptions::UnprocessableEntity, __('Shared draft cannot be selected for this ticket.')
          end

          shared_draft&.destroy
        end

        article_create(ticket, params[:article])
      end
    end

    if response_expand?
      result = ticket.reload.attributes_with_association_names
      render json: result, status: :ok
      return
    end

    if response_full?
      full = Ticket.full(params[:id])
      render json: full, status: :ok
      return
    end

    if response_all?
      render json: Ticket::AssetsAll.new(current_user, ticket.reload).all_assets, status: :ok
      return
    end

    render json: ticket.reload.attributes_with_association_ids, status: :ok
  end

  # DELETE /api/v1/tickets/1
  def destroy
    ticket = Ticket.find(params[:id])
    authorize!(ticket)

    ticket.destroy!

    head :ok
  end

  # GET /api/v1/ticket_customer
  # GET /api/v1/tickets_customer
  def ticket_customer

    # return result
    result = Ticket::ScreenOptions.list_by_customer(
      current_user: current_user,
      customer_id:  params[:customer_id],
      limit:        15,
    )
    render json: result
  end

  # GET /api/v1/ticket_history/1
  def ticket_history

    # get ticket data
    ticket = Ticket.find(params[:id])
    authorize!(ticket, :show?)

    # get history of ticket
    render json: ticket.history_get(true)
  end

  # GET /api/v1/ticket_related/1
  def ticket_related

    ticket = Ticket.find(params[:ticket_id])
    assets = ticket.assets({})

    tickets = TicketPolicy::ReadScope.new(current_user).resolve
                                     .where(
                                       customer_id: ticket.customer_id,
                                       state_id:    Ticket::State.by_category(:open).select(:id),
                                     )
                                     .where.not(id: ticket.id)
                                     .reorder(created_at: :desc)
                                     .limit(6)

    # if we do not have open related tickets, search for any tickets
    tickets ||= TicketPolicy::ReadScope.new(current_user).resolve
                                       .where(customer_id: ticket.customer_id)
                                       .where.not(state_id: Ticket::State.by_category_ids(:merged))
                                       .where.not(id: ticket.id)
                                       .reorder(created_at: :desc)
                                       .limit(6)

    # get related assets
    ticket_ids_by_customer = []
    tickets.each do |ticket_list|
      ticket_ids_by_customer.push ticket_list.id
      assets = ticket_list.assets(assets)
    end

    ticket_ids_recent_viewed = []
    recent_views = RecentView.list(current_user, 8, 'Ticket')
    recent_views.each do |recent_view|
      next if recent_view.object.name != 'Ticket'
      next if recent_view.o_id == ticket.id

      ticket_ids_recent_viewed.push recent_view.o_id
      recent_view_ticket = Ticket.find(recent_view.o_id)
      assets = recent_view_ticket.assets(assets)
    end

    # return result
    render json: {
      assets:                   assets,
      ticket_ids_by_customer:   ticket_ids_by_customer,
      ticket_ids_recent_viewed: ticket_ids_recent_viewed,
    }
  end

  # GET /api/v1/ticket_recent
  def ticket_recent
    ticket_ids = RecentView.list(current_user, 10, Ticket.name).map(&:o_id)
    tickets    = ticket_ids.map { |elem| Ticket.lookup(id: elem) }
    assets     = ApplicationModel::CanAssets.reduce(tickets)

    render json: {
      assets:                   assets,
      ticket_ids_recent_viewed: ticket_ids
    }
  end

  # PUT /api/v1/ticket_merge/1/1
  def ticket_merge

    # check target ticket
    target_ticket = Ticket.find_by(number: params[:target_ticket_number])
    if !target_ticket
      render json: {
        result:  'failed',
        message: __('The target ticket number could not be found.'),
      }
      return
    end

    # check source ticket
    source_ticket = Ticket.find_by(id: params[:source_ticket_id])
    if !source_ticket
      render json: {
        result:  'failed',
        message: __('The source ticket could not be found.'),
      }
      return
    end

    # merge ticket
    Service::Ticket::Merge.new(current_user:).execute(source_ticket:, target_ticket:)

    # return result
    render json: {
      result:        'success',
      target_ticket: target_ticket.attributes,
      source_ticket: source_ticket.attributes,
    }
  end

  # GET /api/v1/ticket_split
  def ticket_split
    ticket = Ticket.find(params[:ticket_id])
    authorize!(ticket, :show?)
    assets = ticket.assets({})

    article = Ticket::Article.find(params[:article_id])
    authorize!(article.ticket, :show?)
    assets = article.assets(assets)

    render json: {
      assets:      assets,
      attachments: article_attachments_clone(article),
    }
  end

  # GET /api/v1/ticket_create
  def ticket_create

    # get attributes to update
    attributes_to_change = Ticket::ScreenOptions.attributes_to_change(
      view:         'ticket_create',
      screen:       'create_middle',
      current_user: current_user,
    )
    render json: attributes_to_change
  end

  # GET /api/v1/tickets/search
  def search
    model_search_render(Ticket, params)
  end

  # GET /api/v1/ticket_stats
  def stats

    if !params[:user_id] && !params[:organization_id]
      raise __('Need user_id or organization_id as param')
    end

    # return result
    render json: Ticket::Stats.new(current_user: current_user, user_id: params[:user_id], organization_id: params[:organization_id], assets: {}).list_stats
  end

  # @path    [GET] /tickets/import_example
  #
  # @summary          Download of example CSV file.
  # @notes            The requester have 'admin' permissions to be able to download it.
  # @example          curl -u #{login}:#{password} http://localhost:3000/api/v1/tickets/import_example
  #
  # @response_message 200 File download.
  # @response_message 403 Forbidden / Invalid session.
  def import_example
    csv_string = Ticket.csv_example(
      col_sep: ',',
    )
    send_data(
      csv_string,
      filename:    'example.csv',
      type:        'text/csv',
      disposition: 'attachment'
    )

  end

  # @path    [POST] /tickets/import
  #
  # @summary          Starts import.
  # @notes            The requester have 'admin' permissions to be create a new import.
  # @example          curl -u #{login}:#{password} -F 'file=@/path/to/file/tickets.csv' 'https://your.zammad/api/v1/tickets/import?try=true'
  # @example          curl -u #{login}:#{password} -F 'file=@/path/to/file/tickets.csv' 'https://your.zammad/api/v1/tickets/import'
  #
  # @response_message 201 Import started.
  # @response_message 403 Forbidden / Invalid session.
  def import_start
    if Setting.get('import_mode') != true
      raise __('Tickets can only be imported if system is in import mode.')
    end

    string = params[:data]
    if string.blank? && params[:file].present?
      string = params[:file].read.force_encoding('utf-8')
    end
    raise Exceptions::UnprocessableEntity, __('No source data submitted!') if string.blank?

    result = Ticket.csv_import(
      string:       string,
      parse_params: {
        col_sep: params[:col_sep] || ',',
      },
      try:          params[:try],
    )
    render json: result, status: :ok
  end
end
