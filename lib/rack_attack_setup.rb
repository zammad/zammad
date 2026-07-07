# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class RackAttackSetup
  def self.setup
    RackAttackSetup::FormEndpoint.setup
    RackAttackSetup::PublicEndpoint.setup
  end

  # This method checks if the request path matches the throttle path.
  # Rails allows paths to have a format extension (e.g. .json)
  # This would allow an attacker to bypass the throttle by adding a format extension to the path.
  # In this method, the format extension is removed from the path before comparing it to the throttled path.
  #
  # https://github.com/zammad/zammad/issues/6199
  def self.path_matches?(request_path, throttle_path)
    request_path_without_format = request_path.sub(%r{\.[^/]+$}, '')
    request_path_without_format == throttle_path || request_path_without_format.start_with?("#{throttle_path}/")
  end

  # Normalize to protect against rate limit bypasses.
  def self.normalize_param(param)
    param.to_s.downcase.gsub(%r{\s+}, '')
  end
end
