require 'rails/observers/active_model/active_model'

module ActiveRecord
  class Base
    extend ActiveModel::Observing::ClassMethods
    include ActiveModel::Observing
  end
end
