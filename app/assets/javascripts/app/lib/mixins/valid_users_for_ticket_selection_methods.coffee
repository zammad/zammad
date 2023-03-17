App.ValidUsersForTicketSelectionMethods =
  validUsersForTicketSelection: ->
    items = $('.content.active .main .table').find('[name="bulk"]:checked')

    # we want to display all users for which we can assign the tickets directly
    # for this we need to get the groups of all selected tickets
    # after we got those we need to check which users are available in all groups
    # users that are not in all groups can't get the tickets assigned
    ticket_ids       = _.map(items, (el) -> $(el).val() )
    ticket_group_ids = _.map(App.Ticket.findAll(ticket_ids), (ticket) -> ticket.group_id)
    users            = @usersInGroups(ticket_group_ids)

    # get the list of possible groups for the current user
    # from the TicketOverviewCollection
    # (filled for e.g. the TicketCreation or TicketZoom assignment)
    # and order them by name
    group_ids     = _.keys(@formMeta?.dependencies?.group_id)
    groups        = App.Group.findAll(group_ids)
    groups_sorted = _.sortBy(groups, (group) -> group.name)
    # get the number of visible users per group
    # from the TicketOverviewCollection
    # (filled for e.g. the TicketCreation or TicketZoom assignment)
    for group in groups
      group.valid_users_count = @formMeta?.dependencies?.group_id?[group.id]?.owner_id.length || 0

    {
      users: users
      groups: groups_sorted
    }

  usersInGroups: (group_ids) ->
    ids_by_group = _.chain(@formMeta?.dependencies?.group_id)
      .pick(group_ids)
      .values()
      .map( (e) -> e.owner_id)
      .value()

    # Underscore's intersection doesn't work when chained
    ids_in_all_groups = _.intersection(ids_by_group...)

    users = App.User.findAll(ids_in_all_groups)
    _.sortBy(users, (user) -> user.firstname)
