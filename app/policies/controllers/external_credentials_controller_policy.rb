# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::ExternalCredentialsControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! :index, to: 'admin'
  default_permit! -> { "admin.channel_#{provider_name}" }

  private

  def provider_name
    @provider_name ||= begin
      if record.params[:id].present? && ExternalCredential.exists?(record.params[:id])
        ExternalCredential.find(record.params[:id]).name
      else
        record.params[:provider] || record.params[:name]
      end
    end
  end
end
