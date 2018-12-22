class Class
  def to_app_model_url
    @to_app_model_url ||= begin
      to_s.gsub(/::/, '_')
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .tr('-', '_')
          .downcase
    end
  end

  def to_app_model
    @to_app_model ||= to_s.gsub(/::/, '').to_sym
  end
end
