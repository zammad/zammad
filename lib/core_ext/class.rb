class Class
  def to_app_model
    name = self.to_s.downcase
    name.gsub( /::/, '_' )
  end
end
