class Topic < ActiveRecord::Base
	has_many :topic_sources, dependent: :destroy
	accepts_nested_attributes_for :topic_sources

	validates :name, :feed_size, presence: true
end