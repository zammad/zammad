# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
class GettingStartedController < ApplicationController

=begin

Resource:
GET /api/v1/getting_started

Response:
{
  "master_user": 1,
  "groups": [
    {
      "name": "group1",
      "active":true
    },
    {
      "name": "group2",
      "active":true
    }
  ]
}

Test:
curl http://localhost/api/v1/getting_started -v -u #{login}:#{password}

=end

  def index

    # check if first user already exists
    return if setup_done_response

    # check it auto wizard is already done
    return if auto_wizard_enabled_response

    # if master user already exists, we need to be authenticated
    if setup_done
      return if !authentication_check
    end

    # return result
    render json: {
      setup_done:            setup_done,
      import_mode:           Setting.get('import_mode'),
      import_backend:        Setting.get('import_backend'),
      system_online_service: Setting.get('system_online_service'),
    }
  end

  def auto_wizard_admin

    # check if system setup is already done
    return if setup_done_response

    # check it auto wizard is enabled
    if !AutoWizard.enabled?
      render json: {
        auto_wizard: false,
      }
      return
    end

    # verify auto wizard file
    auto_wizard_data = AutoWizard.data
    if auto_wizard_data.blank?
      render json: {
        auto_wizard:         true,
        auto_wizard_success: false,
        message:             'Invalid auto wizard file.',
      }
      return
    end

    # verify auto wizard token
    if auto_wizard_data['Token'] && auto_wizard_data['Token'] != params[:token]
      render json: {
        auto_wizard:         true,
        auto_wizard_success: false,
      }
      return
    end

    # execute auto wizard
    auto_wizard_admin = AutoWizard.setup
    if !auto_wizard_admin
      render json: {
        auto_wizard:         true,
        auto_wizard_success: false,
        message:             'Error during execution of auto wizard.',
      }
      return
    end

    # set current session user
    current_user_set(auto_wizard_admin)

    # set system init to done
    Setting.set('system_init_done', true)

    render json: {
      auto_wizard:         true,
      auto_wizard_success: true,
    }
  end

  def base

    # check admin permissions
    permission_check('admin.wizard')

    # validate url
    messages = {}
    settings = {}
    if !Setting.get('system_online_service')
      if !params[:url] || params[:url] !~ %r{^(http|https)://.+?$}
        messages[:url] = 'A URL looks like http://zammad.example.com'
      end

      # split url in http_type and fqdn
      if params[:url]
        if params[:url] =~ %r{^(http|https)://(.+?)(:.+?|/.+?|)$}
          settings[:http_type] = $1
          settings[:fqdn] = $2
        else
          messages[:url] = 'A URL looks like http://zammad.example.com'
        end
      end
    end

    # validate organization
    if params[:organization].blank?
      messages[:organization] = 'Invalid!'
    else
      settings[:organization] = params[:organization]
    end

    # validate image
    if params[:logo] && params[:logo] =~ /^data:image/i
      file = StaticAssets.data_url_attributes(params[:logo])
      if !file[:content] || !file[:mime_type]
        messages[:logo] = 'Unable to process image upload.'
      end
    end

    # add locale_default
    if params[:locale_default].present?
      settings[:locale_default] = params[:locale_default]
    end

    # add timezone_default
    if params[:timezone_default].present?
      settings[:timezone_default] = params[:timezone_default]
    end

    if messages.present?
      render json: {
        result:   'invalid',
        messages: messages,
      }
      return
    end

    # save image
    if params[:logo] && params[:logo] =~ /^data:image/i

      # data:image/png;base64
      file = StaticAssets.data_url_attributes(params[:logo])

      # store image 1:1
      StaticAssets.store_raw(file[:content], file[:mime_type])
    end

    if params[:logo_resize] && params[:logo_resize] =~ /^data:image/i

      # data:image/png;base64
      file = StaticAssets.data_url_attributes(params[:logo_resize])

      # store image 1:1
      settings[:product_logo] = StaticAssets.store(file[:content], file[:mime_type])
    end

    # set changed settings
    settings.each do |key, value|
      Setting.set(key, value)
    end

    render json: {
      result:   'ok',
      settings: settings,
    }
  end

  private

  def auto_wizard_enabled_response
    return false if !AutoWizard.enabled?

    render json: {
      auto_wizard: true
    }
    true
  end

  def setup_done
    #return false
    count = User.all.count()
    done = true
    if count <= 2
      done = false
    end
    done
  end

  def setup_done_response
    return false if !setup_done

    groups = Group.where(active: true)
    addresses = EmailAddress.where(active: true)

    render json: {
      setup_done:            true,
      import_mode:           Setting.get('import_mode'),
      import_backend:        Setting.get('import_backend'),
      system_online_service: Setting.get('system_online_service'),
      addresses:             addresses,
      groups:                groups,
      config:                config_to_update,
      channel_driver:        {
        email: EmailHelper.available_driver,
      },
    }
    true
  end

  def config_to_update
    {
      product_logo: Setting.get('product_logo')
    }
  end

end
