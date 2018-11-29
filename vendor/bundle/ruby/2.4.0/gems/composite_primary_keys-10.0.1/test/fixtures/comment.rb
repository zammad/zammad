class Comment < ActiveRecord::Base
  belongs_to :person, :polymorphic => true
  belongs_to :hack

  enum :shown => [ :true, :false ]
end

