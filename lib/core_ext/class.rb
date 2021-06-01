# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Class
  def to_app_model_url
    @to_app_model_url ||= begin
      to_s.gsub(%r{::}, '_')
          .gsub(%r{([A-Z]+)([A-Z][a-z])}, '\1_\2')
          .gsub(%r{([a-z\d])([A-Z])}, '\1_\2')
          .tr('-', '_')
          .downcase
    end
  end

  def to_app_model
    @to_app_model ||= to_s.gsub(%r{::}, '').to_sym
  end
end
