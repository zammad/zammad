# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase::ManageController < KnowledgeBase::BaseController
  def init
    render json: assets
  end

  def activate
    update_activity true
  end

  def deactivate
    update_activity false
  end

  def server_snippets
    kb = KnowledgeBase.find params[:id]

    if kb.custom_address.blank?
      raise Exceptions::UnprocessableEntity, 'Please submit custom address before generating the snippet'
    end

    render json: {
      address:      kb.custom_address,
      address_type: kb.custom_address_uri.host.present? ? 'domain' : 'path',
      snippets:     {
        nginx:  KnowledgeBase::ServerSnippetNginx.new(kb).render,
        apache: KnowledgeBase::ServerSnippetApache.new(kb).render
      }
    }
  end

  def update_menu_items
    kb = KnowledgeBase.find params[:id]

    affected_items = KnowledgeBase::MenuItemUpdateAction.update_using_params! kb, params_for_permission[:menu_items_sets]

    render json: { assets: ApplicationModel::CanAssets.reduce(affected_items || [], {}) }
  end

  def destroy
    KnowledgeBase.find(params[:id]).full_destroy!
    render json: { status: :ok }
  end

  private

  def update_activity(status)
    kb = KnowledgeBase.find params[:id]
    kb.update! active: status
    render json: kb.assets({})
  end

  def assets
    %w[
      KnowledgeBase
      KnowledgeBase::Locale
      KnowledgeBase::MenuItem
    ].each_with_object({}) do |model, assets|
      model.constantize.find_in_batches do |group|
        assets = ApplicationModel::CanAssets.reduce(group, assets)
      end
    end
  end

  def klass
    KnowledgeBase
  end

  def params_for_permission
    params.permit!
  end
end
