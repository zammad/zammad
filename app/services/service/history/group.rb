# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Create a list of grouped history records by given interval and issuer for a
# given object.
#
# An entry in the list contains the following information:
# - created_at: The timestamp when the group was created.
# - records:    The records that were grouped by the given interval.
#
# The created_at timestamp is the start of the interval rounded to seconds.
#
# A record contains the following information:
# - issuer: The issuer who created the record.
# - events: The events triggered by the issuer.
#
# For the events, see Service::History::List. (The issuer is removed in the
# event, to avoid redundancy.)
#
# Example:
# Service::History::Group.new(current_user:).execute(object: ticket)
# # => [
# #      {
# #        created_at: ActiveRecord::DateTime,
# #        records:    [
# #          {
# #            issuer: User,
# #            events: [
# #              {
# #                created_at: ActiveRecord::DateTime,
# #                action:     'created',
# #                object:     Ticket,
# #                attribute:  nil,
# #                changes:    { from: nil, to: nil }
# #              },
# #            ]
# #          }
# #        ]
# #      }
# #    ]
class Service::History::Group < Service::BaseWithCurrentUser
  def execute(object:, interval: 15.seconds)
    list = Service::History::List
      .new(current_user:)
      .execute(object:)

    group_by_time_and_issuer(list, interval)
  end

  private

  # Group records by given interval and issuers
  def group_by_time_and_issuer(list, interval)
    list
      .group_by { |record| [record[:created_at].to_i / interval, record[:issuer]] }
      .map do |(_, issuer), records|
        {
          created_at: records.first[:created_at],
          issuer:     issuer,
          events:     records.map { |record| record.except(:issuer) }
        }
      end
      .group_by { |record| record[:created_at].to_i / interval }
      .map do |_, grouped_records|
        {
          created_at: grouped_records.first[:created_at],
          records:    grouped_records.map { |record| record.slice(:issuer, :events) }
        }
      end
  end
end
