class Translation < ApplicationModel
  before_create :set_initial

  def self.translate(locale, string)

    # translate string
    records = Translation.where( :locale => locale, :source => string )
    records.each {|record|
      return record.target if record.source == string
    }

    # fallback lookup in en
    records = Translation.where( :locale => 'en', :source => string )
    records.each {|record|
      return record.target if record.source == string
    }

    return string
  end

  private
    def set_initial
      self.target_initial = self.target
    end
end
