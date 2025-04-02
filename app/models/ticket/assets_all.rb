# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Ticket::AssetsAll
  attr_accessor :user, :ticket

  def initialize(user, ticket)
    @user = user
    @ticket = ticket
  end

  def all_assets(assets = {})
    attributes_to_change = get_attributes_to_change(assets)

    all_assets = compile_assets(attributes_to_change[:assets])

    response(all_assets, attributes_to_change)
  end

  private

  def compile_assets(assets)
    ticket.assets(assets)

    assets = ApplicationModel::CanAssets.reduce([ticket, articles, mentions].flatten, assets)
    assets = Link.reduce_assets(assets, links)

    if (draft = ticket.shared_draft) && Ticket::SharedDraftZoomPolicy.new(user, draft).show?
      assets = draft.assets(assets)
    end

    if Setting.get('checklist') && user.permissions?('ticket.agent')
      ticket.checklist&.assets(assets)

      ticket.referencing_checklists
        .includes(:ticket)
        .each do |elem|
          elem.assets(assets)
          elem.ticket.assets(assets) if elem.ticket.authorized_asset?
        end
    end

    assets
  end

  def response(assets, attributes_to_change)
    {
      ticket_id:          ticket.id,
      ticket_article_ids: articles.pluck(:id),
      assets:             assets,
      links:              links,
      tags:               tags,
      mentions:           mentions.pluck(:id),
      time_accountings:   time_accountings,
      form_meta:          attributes_to_change[:form_meta],
    }
  end

  def get_attributes_to_change(assets)
    Ticket::ScreenOptions.attributes_to_change(
      current_user: user,
      ticket:       ticket,
      screen:       'edit',
      assets:       assets,
    )
  end

  def articles
    @articles ||= ticket.articles.filter { |elem| Ticket::ArticlePolicy.new(user, elem).show? }
  end

  def links
    @links ||= Link.list(
      link_object:       'Ticket',
      link_object_value: ticket.id,
      user:              user,
    )
  end

  def tags
    @tags ||= ticket.tag_list
  end

  def time_accountings
    @time_accountings = ticket
      .ticket_time_accounting
      .map { |row| row.slice(:id, :ticket_id, :ticket_article_id, :time_unit, :type_id) }
  end

  def mentions
    @mentions ||= ticket.mentions
  end
end
