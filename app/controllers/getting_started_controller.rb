# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class GettingStartedController < ApplicationController
  prepend_before_action -> { authorize! }, only: [:base]

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

    # if admin user already exists, we need to be authenticated
    return if setup_done && !authentication_check

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

    begin
      auto_wizard_admin = Service::System::RunAutoWizard.new.execute(token: params[:token])
    rescue Service::System::RunAutoWizard::AutoWizardNotEnabledError
      return render json: {
        auto_wizard: false,
      }
    rescue Service::System::RunAutoWizard::AutoWizardExecutionError => e
      return render json: {
        auto_wizard:         true,
        auto_wizard_success: false,
        message:             e.message,
      }
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
    args = params.slice(:url, :locale_default, :timezone_default, :organization)

    %i[logo logo_resize].each do |key|
      data = params[key]

      next if !data&.match? %r{^data:image}i

      file = ImageHelper.data_url_attributes(data)

      args[key] = file[:content] if file
    end

    begin
      set_system_information_service = Service::System::SetSystemInformation.new(data: args)
      result = set_system_information_service.execute

      render json: {
        result:   'ok',
        settings: result,
      }
    rescue Exceptions::MissingAttribute, Exceptions::InvalidAttribute => e
      render json: {
        result:   'invalid',
        messages: { e.attribute => e.message }
      }
    end
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
    # return false
    count = User.count
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
