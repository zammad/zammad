# Monkey-patch HTTP::URI
class HTTP::URI
  def port
    443 if self.https?
  end
end
