# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Integration::GitHubController < Integration::IssueTrackerController
  private

  def integration_type
    'github'
  end

  def integration_client
    ::GitHub.new(
      endpoint:  unmasked_params[:endpoint],
      api_token: unmasked_params[:api_token],
    )
  end
end
