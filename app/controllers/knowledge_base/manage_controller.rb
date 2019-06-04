# Copyright (C) 2012-2017 Zammad Foundation, http://zammad-foundation.org/
class KnowledgeBase::ManageController < KnowledgeBase::BaseController
  prepend_before_action { permission_check('admin.knowledge_base') }
  skip_before_action :ensure_editor_or_reader
  skip_before_action :ensure_editor

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
    kb_locale = kb.kb_locales.find params[:kb_locale_id]

    KnowledgeBase::MenuItemUpdateAction
      .new(kb_locale, params[:menu_items])
      .perform!

    render json: { assets: ApplicationModel::CanAssets.reduce(kb_locale.menu_items.reload, {}) }
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
