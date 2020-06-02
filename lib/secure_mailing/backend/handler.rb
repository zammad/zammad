class SecureMailing::Backend::Handler

  def self.process(*args)
    new(*args).process
  end
end
