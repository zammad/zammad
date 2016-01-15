class Class
  def to_app_model_url
    camel_cased_word = to_s
    camel_cased_word.gsub(/::/, '_')
                    .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                    .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                    .tr('-', '_')
                    .downcase
  end

  def to_app_model
    camel_cased_word = to_s
    camel_cased_word.gsub(/::/, '').to_sym
  end
end
