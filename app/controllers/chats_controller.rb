# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class ChatsController < ApplicationController
  before_action :authentication_check

  def index
    deny_if_not_role(Z_ROLENAME_ADMIN)
    chat_ids = []
    assets = {}
    Chat.order(:id).each {|chat|
      chat_ids.push chat.id
      assets = chat.assets(assets)
    }
    setting = Setting.find_by(name: 'chat')
    assets = setting.assets(assets)
    render json: {
      chat_ids: chat_ids,
      assets: assets,
    }
  end

  def show
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_show_render(Chat, params)
  end

  def create
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_create_render(Chat, params)
  end

  def update
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_update_render(Chat, params)
  end

  def destroy
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_destory_render(Chat, params)
  end
end
