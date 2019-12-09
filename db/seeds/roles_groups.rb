RoleGroup.create_if_not_exists(role: Role.find_by(name: 'Agent'), group: Group.find_by(name: 'Incoming'))
