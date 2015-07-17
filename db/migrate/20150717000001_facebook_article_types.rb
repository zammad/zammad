class FacebookArticleTypes < ActiveRecord::Migration
  def up
    facebook_at      = Ticket::Article::Type.find_by( name: 'facebook' )
    facebook_at.name = 'facebook feed post'
    facebook_at.save

    Ticket::Article::Type.create(
      name:          'facebook feed comment',
      communication: true,
      updated_by_id: 1,
      created_by_id: 1
    )
  end
end
