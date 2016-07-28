# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class UserAccessTokenController < ApplicationController
  before_action :authentication_check

  def index
    tokens = Token.where(action: 'api', persistent: true, user_id: current_user.id).order('updated_at DESC, label ASC')
    token_list = []
    tokens.each { |token|
      attributes = token.attributes
      attributes.delete('persistent')
      attributes.delete('name')
      token_list.push attributes
    }
    model_index_render_result(token_list)
  end

  def create
    if Setting.get('api_token_access') == false
      raise Exceptions::UnprocessableEntity, 'API token access disabled!'
    end
    if params[:label].empty?
      raise Exceptions::UnprocessableEntity, 'Need label!'
    end
    token = Token.create(
      action:     'api',
      label:      params[:label],
      persistent: true,
      user_id:    current_user.id,
    )
    render json: {
      name: token.name,
    }, status: :ok
  end

  def destroy
    token = Token.find_by(action: 'api', user_id: current_user.id, id: params[:id])
    raise Exceptions::UnprocessableEntity, 'Unable to find api token!' if !token
    token.destroy
    render json: {}, status: :ok
  end

end
