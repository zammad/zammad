# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Integration::GitLabController < Integration::IssueTrackerController
  private

  def integration_type
    'gitlab'
  end

  def integration_client
    ::GitLab.new(
      endpoint:   unmasked_params[:endpoint],
      api_token:  unmasked_params[:api_token],
      verify_ssl: unmasked_params[:verify_ssl],
    )
  end
end
