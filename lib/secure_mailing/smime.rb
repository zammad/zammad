class SecureMailing::SMIME < SecureMailing::Backend

  def self.active?
    Setting.get('smime_integration')
  end
end
