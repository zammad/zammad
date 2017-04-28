# encoding: utf-8
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)

# clear old caches to start from scratch
Cache.clear

# this is the __ordered__ list of seed files
# extend only if needed - try to add your changes
# to the matching one of the existing files
seeds = %w(settings user_nr_1 signatures roles permissions groups links ticket_state_types ticket_states ticket_priorities ticket_article_types ticket_article_senders macros community_user_resources overviews channels report_profiles chats networks object_manager_attributes schedulers triggers karma_activities)

# loop and require all seedfiles
# files will get executed automatically
seeds.each do |seed|
  # we use require relative here since
  # - we the seeds file to get loaded only once
  # - we want to require it relative to the current path
  require_relative "seeds/#{seed}.rb"
end

# reset primary key sequences
DbHelper.import_post

# install locales and translations
Locale.create_if_not_exists(
  locale: 'en-us',
  alias: 'en',
  name: 'English (United States)',
)
Locale.sync
Translation.sync

Calendar.init_setup

# install all packages in auto_install
Package.auto_install
