# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class FormController < ApplicationController

  def config
    return if !enabled?

    api_path  = Rails.configuration.api_path
    http_type = Setting.get('http_type')
    fqdn      = Setting.get('fqdn')

    endpoint = "#{http_type}://#{fqdn}#{api_path}/form_submit"

    config = {
      enabled:  Setting.get('form_ticket_create'),
      endpoint: endpoint,
    }

    if params[:test] && current_user && current_user.permissions?('admin.channel_formular')
      config[:enabled] = true
    end

    render json: config, status: :ok
  end

  def submit
    return if !enabled?

    # validate input
    errors = {}
    if !params[:name] || params[:name].empty?
      errors['name'] = 'required'
    end
    if !params[:email] || params[:email].empty?
      errors['email'] = 'required'
    end
    if params[:email] !~ /@/
      errors['email'] = 'invalid'
    end
    if params[:email] =~ /(>|<|\||\!|"|§|'|\$|%|&|\(|\)|\?|\s)/
      errors['email'] = 'invalid'
    end
    if !params[:title] || params[:title].empty?
      errors['title'] = 'required'
    end
    if !params[:body] || params[:body].empty?
      errors['body'] = 'required'
    end

    # realtime verify
    if !errors['email']
      begin
        checker = EmailVerifier::Checker.new(params[:email])
        checker.connect
        if !checker.verify
          errors['email'] = "Unable to send to '#{params[:email]}'"
        end
      rescue => e
        message = e.to_s
        Rails.logger.info "Can't verify email #{params[:email]}: #{message}"

        # ignore 450, graylistings
        if message !~ /450/
          errors['email'] = message
        end
      end
    end

    if errors && !errors.empty?
      render json: {
        errors: errors
      }, status: :ok
      return
    end

    name = params[:name].strip
    email = params[:email].strip.downcase

    customer = User.find_by(email: email)
    if !customer
      role_ids = Role.signup_role_ids
      customer = User.create(
        firstname: name,
        lastname: '',
        email: email,
        password: '',
        active: true,
        role_ids: role_ids,
        updated_by_id: 1,
        created_by_id: 1,
      )
    end

    # set current user
    UserInfo.current_user_id = customer.id

    ticket = Ticket.create(
      group_id: 1,
      customer_id: customer.id,
      title: params[:title],
      state_id: Ticket::State.find_by(name: 'new').id,
      priority_id: Ticket::Priority.find_by(name: '2 normal').id,
    )
    article = Ticket::Article.create(
      ticket_id: ticket.id,
      type_id: Ticket::Article::Type.find_by(name: 'web').id,
      sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
      body: params[:body],
      subject: params[:title],
      internal: false,
    )

    if params[:file]
      params[:file].each { |file|
        Store.add(
          object: 'Ticket::Article',
          o_id: article.id,
          data: File.read(file.tempfile),
          filename: file.original_filename,
          preferences: {
            'Mime-Type' => file.content_type,
          }
        )
      }
    end

    UserInfo.current_user_id = 1

    result = {
      ticket: {
        id: ticket.id,
        number: ticket.number
      }
    }
    render json: result, status: :ok
  end

  private

  def enabled?
    return true if params[:test] && current_user && current_user.permissions?('admin.channel_formular')
    return true if Setting.get('form_ticket_create')
    response_access_deny
    false
  end

end
