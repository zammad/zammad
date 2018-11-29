module Clearbit
  module Enrichment extend self
    autoload :Company, 'clearbit/enrichment/company'
    autoload :News, 'clearbit/enrichment/news'
    autoload :Person, 'clearbit/enrichment/person'
    autoload :PersonCompany, 'clearbit/enrichment/person_company'

    def find(values)
      if values.key?(:domain)
        result = Company.find(values)

        if result && result.pending?
          Pending.new
        else
          PersonCompany.new(company: result)
        end
      else
        PersonCompany.find(values)
      end
    end
  end
end
