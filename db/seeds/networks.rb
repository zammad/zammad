network = Network.create_if_not_exists(
  id: 1,
  name: 'base',
)

Network::Category::Type.create_if_not_exists(
  id: 1,
  name: 'Announcement',
)
Network::Category::Type.create_if_not_exists(
  id: 2,
  name: 'Idea',
)
Network::Category::Type.create_if_not_exists(
  id: 3,
  name: 'Question',
)
Network::Category::Type.create_if_not_exists(
  id: 4,
  name: 'Bug Report',
)

Network::Privacy.create_if_not_exists(
  id: 1,
  name: 'logged in',
  key: 'loggedIn',
)
Network::Privacy.create_if_not_exists(
  id: 2,
  name: 'logged in and moderator',
  key: 'loggedInModerator',
)
Network::Category.create_if_not_exists(
  id: 1,
  name: 'Announcements',
  network_id: network.id,
  network_category_type_id: Network::Category::Type.find_by(name: 'Announcement').id,
  network_privacy_id: Network::Privacy.find_by(name: 'logged in and moderator').id,
  allow_comments: true,
)
Network::Category.create_if_not_exists(
  id: 2,
  name: 'Questions',
  network_id: network.id,
  allow_comments: true,
  network_category_type_id: Network::Category::Type.find_by(name: 'Question').id,
  network_privacy_id: Network::Privacy.find_by(name: 'logged in').id,
)
Network::Category.create_if_not_exists(
  id: 3,
  name: 'Ideas',
  network_id: network.id,
  network_category_type_id: Network::Category::Type.find_by(name: 'Idea').id,
  network_privacy_id: Network::Privacy.find_by(name: 'logged in').id,
  allow_comments: true,
)
Network::Category.create_if_not_exists(
  id: 4,
  name: 'Bug Reports',
  network_id: network.id,
  network_category_type_id: Network::Category::Type.find_by(name: 'Bug Report').id,
  network_privacy_id: Network::Privacy.find_by(name: 'logged in').id,
  allow_comments: true,
)
item = Network::Item.create(
  title: 'Example Announcement',
  body: 'Some announcement....',
  network_category_id: Network::Category.find_by(name: 'Announcements').id,
)
Network::Item::Comment.create(
  network_item_id: item.id,
  body: 'Some comment....',
)
item = Network::Item.create(
  title: 'Example Question?',
  body: 'Some questions....',
  network_category_id: Network::Category.find_by(name: 'Questions').id,
)
Network::Item::Comment.create(
  network_item_id: item.id,
  body: 'Some comment....',
)
item = Network::Item.create(
  title: 'Example Idea',
  body: 'Some idea....',
  network_category_id: Network::Category.find_by(name: 'Ideas').id,
)
Network::Item::Comment.create(
  network_item_id: item.id,
  body: 'Some comment....',
)
item = Network::Item.create(
  title: 'Example Bug Report',
  body: 'Some bug....',
  network_category_id: Network::Category.find_by(name: 'Bug Reports').id,
)
Network::Item::Comment.create(
  network_item_id: item.id,
  body: 'Some comment....',
)
