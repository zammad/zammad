class TopicSource < ActiveRecord::Base
	self.primary_keys = :topic_id, :platform

	belongs_to :topic, inverse_of: :topic_sources

	validates :platform, presence: true
end