# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class GettingStartedController < ApplicationController

=begin

Resource:
GET /api/v1/getting_started.json

Response:
{
  "master_user": 1,
  "groups": [
    {
      "name": "group1",
      "active":true
    },
    {
      "name": "group2",
      "active":true
    }
  ]
}

Test:
curl http://localhost/api/v1/getting_started.json -v -u #{login}:#{password}

=end

  def index

    # check if first user already exists
    master_user = 0
    count = User.all.count()
    if count <= 2
      master_user = 1
    end

    # if master user already exists, we need to be authenticated
    if master_user == 0
      return if !authentication_check
    end

    # get all groups
    groups = Group.where( :active => true )

    # return result
    render :json => {
      :master_user => master_user,
      :groups      => groups,
    }
  end
end
