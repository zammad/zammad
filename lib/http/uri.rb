# Monkey-patch HTTP::URI
class HTTP::URI
  def port
    443 if https?
  end
end
