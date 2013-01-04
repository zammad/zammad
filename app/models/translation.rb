class Translation < ApplicationModel
  before_create :set_initial

  def self.translate(locale, string)

    # translate string
    record = Translation.where( :locale => locale, :source => string ).first
    return record.target if record

    # fallback lookup in en
    record = Translation.where( :locale => 'en', :source => string ).first
    return record.target if record

    return string
  end

  private
    def set_initial
      self.target_initial = self.target
    end
end
