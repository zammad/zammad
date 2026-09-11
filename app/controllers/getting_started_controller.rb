# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
    return render json: authorized_setup_response if setup_done?

    return render json: { auto_wizard: true } if AutoWizard.enabled?

    render json: setup_pending_payload
  end

  def auto_wizard_admin
    return render json: authorized_setup_response if setup_done?

    begin
      auto_wizard_admin = Service::System::RunAutoWizard.execute(token: params[:token])
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
      result = Service::System::SetSystemInformation.execute(data: args)

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

  # The system counts as set up once there is a user besides the system user and
  # the first admin.
  def setup_done?
    User.count > 2
  end

  # Both actions answer a set-up system from here, so the migration window and the
  # authorization live in one place and cannot diverge between them.
  def authorized_setup_response
    return migration_payload if import_running?

    authorize_wizard_payload!

    setup_done_payload
  end

  # The setup done payload carries the group configuration and the complete list
  # of sender addresses, which the dedicated endpoints field-scope respectively
  # deny, so it belongs to a user who may run the wizard.
  def authorize_wizard_payload!
    authentication_check
    current_user.permissions!('admin.wizard')
  end

  # Import mode is on from the start of a migration until it succeeds, and an
  # import refuses to start once the setup is done (Import::Helper), so the window
  # covers a whole migration and does not open on an installed system. It is not
  # bounded in time, though: import mode survives a failure -- Import::OTRS::Async
  # rescues and returns, and the sequencer backends unset it as their final step
  # only -- so an installation can stay in it indefinitely.
  #
  # The admin count deliberately plays no part here: the importers assign the
  # Admin role to imported users, so a migration acquires admins while it runs.
  # Neither does system_init_done alone, which is not monotonic -- it is reset by
  # Service::System::CheckSetup when it is set without an admin being present.
  def import_running?
    Setting.get('import_mode') && !Setting.get('system_init_done')
  end

  # A migration is started anonymously from the installer and imports users, which
  # pushes the user count past the setup_done? threshold while it runs, so the
  # progress screens have to keep working without a user. They read nothing but
  # import_mode and import_backend, so this window carries no wizard data at all,
  # for any caller: it cannot be relied on to close, and a user who needs the
  # group or email address list has the dedicated endpoints for it.
  def migration_payload
    setup_pending_payload.merge(setup_done: true)
  end

  def setup_done_payload
    {
      setup_done:            true,
      import_mode:           Setting.get('import_mode'),
      import_backend:        Setting.get('import_backend'),
      system_online_service: Setting.get('system_online_service'),
      addresses:             EmailAddress.where(active: true),
      groups:                Group.where(active: true),
      config:                config_to_update,
      channel_driver:        {
        email: EmailHelper.available_driver,
      },
    }
  end

  def setup_pending_payload
    {
      setup_done:            false,
      import_mode:           Setting.get('import_mode'),
      import_backend:        Setting.get('import_backend'),
      system_online_service: Setting.get('system_online_service'),
    }
  end

  def config_to_update
    {
      product_logo: Setting.get('product_logo')
    }
  end
end
