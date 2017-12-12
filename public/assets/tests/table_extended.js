// initial list
test('table new - initial list', function() {
  App.i18n.set('de-de')

  $('#table').append('<hr><h1>table with data</h1><div id="table-new1"></div>')
  var el = $('#table-new1')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note 1',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note 2',
      active:     false,
      created_at: '2014-06-10T10:17:34.000Z',
    },
  ], {clear: true})

  var table = new App.ControllerTable({
    el:                 el,
    overviewAttributes: ['name', 'created_at', 'active'],
    model:              App.TicketPriority,
    objects:            App.TicketPriority.search({sortBy:'name', order: 'ASC'}),
    checkbox:           false,
    radio:              false,
  })
  //equal(el.find('table').length, 0, 'row count')
  //table.render()
  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 0, 'check row 3')

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'noChanges')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       'Priority',
      note:       'some note 1',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'fullRender.lenghtChanged')
  equal(result[1], 2)
  equal(result[2], 1)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), 'Priorität', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 0, 'check row 2')

  App.TicketPriority.refresh([], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'emptyList')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Keine Einträge', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 0, 'check row 1')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note 1',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note 2',
      active:     false,
      created_at: '2014-06-10T10:17:34.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'fullRender')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 0, 'check row 3')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note 1',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note 2',
      active:     false,
      created_at: '2014-06-10T10:17:34.000Z',
    },
    {
      id:         3,
      name:       '3 high',
      note:       'some note 3',
      active:     false,
      created_at: '2014-06-10T10:17:38.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'fullRender.contentRemoved')
  equal(result[1][0], undefined)
  equal(result[2][0], 2)
  equal(result[2][1], undefined)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '3 hoch', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td').length, 0, 'check row 4')

  result = table.update({sync: true, orderDirection: 'DESC', orderBy: 'name'})
  equal(result[0], 'fullRender.contentChanged')
  equal(result[1], 0)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '3 hoch', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '1 niedrig', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td').length, 0, 'check row 4')

  result = table.update({sync: true, orderDirection: 'ASC', orderBy: 'name'})
  equal(result[0], 'fullRender.contentChanged')
  equal(result[1], 0)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '3 hoch', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td').length, 0, 'check row 4')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note 1',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         3,
      name:       '3 high',
      note:       'some note 3',
      active:     false,
      created_at: '2014-06-10T10:17:38.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'fullRender.contentRemoved')
  equal(result[1][0], 1)
  equal(result[1][1], undefined)
  notOk(result[1][1])

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '3 hoch', 'check row 3')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 0, 'check row 3')

  result = table.update({sync: true, overviewAttributes: ['name', 'created_at']})
  equal(result[0], 'fullRender.overviewAttributesChanged')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th').length, 2, 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 2, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 2, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '3 hoch', 'check row 3')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 0, 'check row 3')

  App.TicketPriority.refresh([], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'emptyList')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Keine Einträge', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 0, 'check row 1')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note 1',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         3,
      name:       '3 high',
      note:       'some note 3',
      active:     false,
      created_at: '2014-06-10T10:17:38.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'}), overviewAttributes: ['name'], orderBy: 'created_at', orderDirection: 'DESC'})
  equal(result[0], 'fullRender')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th').length, 1, 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 1, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 1, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '3 hoch', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 0, 'check row 3')

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'}), overviewAttributes: ['name'], orderBy: 'created_at', orderDirection: 'ASC'})
  equal(result[0], 'fullRender.overviewAttributesChanged')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th').length, 1, 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 1, 'check row 2')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '3 hoch', 'check row 3')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 1, 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 0, 'check row 3')

  $('#table').append('<hr><h1>table group by with data</h1><div id="table-new2"></div>')
  var el = $('#table-new2')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T10:17:30.000Z',
    },
    {
      id:         3,
      name:       '3 high',
      note:       'some other note',
      active:     true,
      created_at: '2014-06-10T10:17:38.000Z',
    },
  ], {clear: true})

  var table = new App.ControllerTable({
    el:                 el,
    overviewAttributes: ['name', 'created_at', 'active'],
    model:              App.TicketPriority,
    objects:            App.TicketPriority.search({sortBy:'name', order: 'ASC'}),
    checkbox:           false,
    radio:              false,
    groupBy:            'note',
  })

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 1, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), 'some note', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '1 niedrig', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '2 normal', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td').length, 1, 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td:first').text().trim(), 'some other note', 'check row 3')
  equal(el.find('tbody > tr:nth-child(5) > td:first').text().trim(), '3 hoch', 'check row 5')
  equal(el.find('tbody > tr:nth-child(5) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 5')
  equal(el.find('tbody > tr:nth-child(5) > td:nth-child(3)').text().trim(), 'true', 'check row 5')
  equal(el.find('tbody > tr:nth-child(6) > td').length, 0, 'check row 6')

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'noChanges')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T10:17:30.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'fullRender.contentRemoved')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 1, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), 'some note', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '1 niedrig', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '2 normal', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td').length, 0, 'check row 6')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T10:17:30.000Z',
    },
    {
      id:         3,
      name:       '3 high',
      note:       'some other note',
      active:     true,
      created_at: '2014-06-10T10:17:38.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'fullRender.contentRemoved')
  equal(result[1][0], undefined)
  equal(result[2][0], 3)
  equal(result[2][1], 4)
  equal(result[2][2], undefined)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 1, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), 'some note', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '1 niedrig', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '2 normal', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td').length, 1, 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td:first').text().trim(), 'some other note', 'check row 3')
  equal(el.find('tbody > tr:nth-child(5) > td:first').text().trim(), '3 hoch', 'check row 5')
  equal(el.find('tbody > tr:nth-child(5) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 5')
  equal(el.find('tbody > tr:nth-child(5) > td:nth-child(3)').text().trim(), 'true', 'check row 5')
  equal(el.find('tbody > tr:nth-child(6) > td').length, 0, 'check row 6')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T10:17:30.000Z',
    },
    {
      id:         3,
      name:       '3 high',
      note:       'some other note',
      active:     true,
      created_at: '2014-06-10T10:17:38.000Z',
    },
    {
      id:         4,
      name:       '4 high',
      note:       'some other note',
      active:     true,
      created_at: '2014-06-10T10:17:39.000Z',
    },
    {
      id:         5,
      name:       '5 high',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T10:17:39.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'fullRender.contentRemoved')
  equal(result[1][0], undefined)
  equal(result[2][0], 3)
  equal(result[2][1], 6)
  equal(result[2][2], undefined)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 1, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), 'some note', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '1 niedrig', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '2 normal', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td').length, 3, 'check row 4')
  equal(el.find('tbody > tr:nth-child(4) > td:first').text().trim(), '5 high', 'check row 4')
  equal(el.find('tbody > tr:nth-child(4) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 4')
  equal(el.find('tbody > tr:nth-child(4) > td:nth-child(3)').text().trim(), 'true', 'check row 4')
  equal(el.find('tbody > tr:nth-child(5) > td').length, 1, 'check row 5')
  equal(el.find('tbody > tr:nth-child(5) > td:first').text().trim(), 'some other note', 'check row 5')
  equal(el.find('tbody > tr:nth-child(6) > td:first').text().trim(), '3 hoch', 'check row 6')
  equal(el.find('tbody > tr:nth-child(6) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 6')
  equal(el.find('tbody > tr:nth-child(6) > td:nth-child(3)').text().trim(), 'true', 'check row 6')
  equal(el.find('tbody > tr:nth-child(7) > td').length, 3, 'check row 7')
  equal(el.find('tbody > tr:nth-child(7) > td:first').text().trim(), '4 high', 'check row 7')
  equal(el.find('tbody > tr:nth-child(7) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 7')
  equal(el.find('tbody > tr:nth-child(7) > td:nth-child(3)').text().trim(), 'true', 'check row 7')
  equal(el.find('tbody > tr:nth-child(8) > td').length, 0, 'check row 8')

  $('#table').append('<hr><h1>table with large data</h1><div id="table-new3"></div>')
  var el = $('#table-new3')

  var objects = [];
  var created_at = Date.parse('2014-06-10T11:17:34.000Z')

  for (i = 0; i < 1000; i++) {
    local_created_at = new Date(created_at - (1000 * 60 * 60 * 24 * i)).toISOString()
    item = {
      id:         i,
      name:       i + ' prio',
      note:       'some note',
      active:     true,
      created_at: local_created_at,
    }
    objects.push(item)
  }

  App.TicketPriority.refresh(objects.reverse(), {clear: true})

  var table = new App.ControllerTable({
    tableId:            'large_table_test',
    el:                 el,
    overviewAttributes: ['name', 'created_at', 'active'],
    model:              App.TicketPriority,
    objects:            App.TicketPriority.all(),
    checkbox:           false,
    radio:              false,
    ttt: true
  })

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '999 prio', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '15.09.2011', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '998 prio', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '16.09.2011', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '997 prio', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '17.09.2011', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr').length, 150)
  equal(el.find('tbody > tr:nth-child(151) > td').length, 0)

  equal(el.find('.js-tableHead[data-column-key="name"] .js-sort .icon').length, 0)
  el.find('.js-tableHead[data-column-key="name"] .js-sort').click()

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '0 prio', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '1 prio', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '09.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '10 prio', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '31.05.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr').length, 150)
  equal(el.find('tbody > tr:nth-child(151) > td').length, 0)

  equal(el.find('.js-tableHead[data-column-key="name"] .js-sort .icon.icon-arrow-up').length, 1)
  equal(el.find('.js-tableHead[data-column-key="name"] .js-sort .icon.icon-arrow-down').length, 0)
  el.find('.js-tableHead[data-column-key="name"] .js-sort').click()

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '999 prio', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '15.09.2011', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '998 prio', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '16.09.2011', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '997 prio', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '17.09.2011', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr').length, 150)
  equal(el.find('tbody > tr:nth-child(151) > td').length, 0)

  equal(el.find('.js-tableHead[data-column-key="name"] .js-sort .icon.icon-arrow-down').length, 1)
  equal(el.find('.js-tableHead[data-column-key="name"] .js-sort .icon.icon-arrow-up').length, 0)
  equal(el.find('.js-tableHead[data-column-key="created_at"] .js-sort .icon').length, 0)
  el.find('.js-tableHead[data-column-key="created_at"] .js-sort').click()

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '999 prio', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '15.09.2011', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '998 prio', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '16.09.2011', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '997 prio', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '17.09.2011', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr').length, 150)
  equal(el.find('tbody > tr:nth-child(151) > td').length, 0)

  equal(el.find('.js-tableHead[data-column-key="name"] .js-sort .icon').length, 0)
  equal(el.find('.js-tableHead[data-column-key="created_at"] .js-sort .icon.icon-arrow-down').length, 0)
  equal(el.find('.js-tableHead[data-column-key="created_at"] .js-sort .icon.icon-arrow-up').length, 1)
  el.find('.js-tableHead[data-column-key="created_at"] .js-sort').click()

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '0 prio', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '1 prio', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '09.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '2 prio', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '08.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr').length, 150)
  equal(el.find('tbody > tr:nth-child(151) > td').length, 0)

  equal(el.find('.js-tableHead[data-column-key="name"] .js-sort .icon').length, 0)
  equal(el.find('.js-tableHead[data-column-key="created_at"] .js-sort .icon.icon-arrow-down').length, 1)
  equal(el.find('.js-tableHead[data-column-key="created_at"] .js-sort .icon.icon-arrow-up').length, 0)

  objects = App.TicketPriority.all().reverse()
  objects.shift()
  objects.shift()

  result = table.update({sync: true, objects: objects})
  equal(result[0], 'fullRender.contentRemoved')
  equal(result[1][0], 1)
  equal(result[1][1], 0)
  equal(result[2][0], 148)
  equal(result[2][1], 149)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '2 prio', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '08.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '3 prio', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '07.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '4 prio', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '06.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr:nth-child(149) > td:first').text().trim(), '150 prio', 'check row 3')
  equal(el.find('tbody > tr:nth-child(149) > td:nth-child(2)').text().trim(), '11.01.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(149) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr:nth-child(150) > td:first').text().trim(), '151 prio', 'check row 3')
  equal(el.find('tbody > tr:nth-child(150) > td:nth-child(2)').text().trim(), '10.01.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(150) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr').length, 150)
  equal(el.find('tbody > tr:nth-child(151) > td').length, 0)

  equal(el.find('.js-tableHead[data-column-key="name"] .js-sort .icon').length, 0)
  equal(el.find('.js-tableHead[data-column-key="created_at"] .js-sort .icon.icon-arrow-down').length, 1)
  equal(el.find('.js-tableHead[data-column-key="created_at"] .js-sort .icon.icon-arrow-up').length, 0)
  el.find('.js-tableHead[data-column-key="created_at"] .js-sort').click()

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '999 prio', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '15.09.2011', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '998 prio', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '16.09.2011', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '997 prio', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '17.09.2011', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr').length, 150)
  equal(el.find('tbody > tr:nth-child(151) > td').length, 0)

  equal(el.find('.js-tableHead[data-column-key="name"] .js-sort .icon').length, 0)
  equal(el.find('.js-tableHead[data-column-key="created_at"] .js-sort .icon.icon-arrow-down').length, 0)
  equal(el.find('.js-tableHead[data-column-key="created_at"] .js-sort .icon.icon-arrow-up').length, 1)

  el.find('.js-tableHead[data-column-key="created_at"] .js-sort').click()

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '2 prio', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '08.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '3 prio', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '07.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '4 prio', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '06.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr:nth-child(149) > td:first').text().trim(), '150 prio', 'check row 3')
  equal(el.find('tbody > tr:nth-child(149) > td:nth-child(2)').text().trim(), '11.01.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(149) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr:nth-child(150) > td:first').text().trim(), '151 prio', 'check row 3')
  equal(el.find('tbody > tr:nth-child(150) > td:nth-child(2)').text().trim(), '10.01.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(150) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr').length, 150)
  equal(el.find('tbody > tr:nth-child(151) > td').length, 0)

  $('#table').append('<hr><h1>table with now data</h1><div id="table-new4"></div>')
  var el = $('#table-new4')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
  ], {clear: true})

  var table = new App.ControllerTable({
    el:                 el,
    overviewAttributes: ['name', 'created_at', 'active'],
    model:              App.TicketPriority,
    objects:            App.TicketPriority.search({sortBy:'name', order: 'ASC'}),
    checkbox:           false,
    radio:              false,
  })

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3)
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 0)

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T10:17:30.000Z',
    },

  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'fullRender.contentRemoved')
  equal(result[1][0], undefined)
  equal(result[2][0], 1)
  equal(result[2][1], undefined)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3)
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3)
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 0)

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T10:17:30.000Z',
    },
    {
      id:         3,
      name:       '3 high',
      note:       'some note 3',
      active:     true,
      created_at: '2014-06-10T10:17:38.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'fullRender.contentRemoved')
  equal(result[1][0], undefined)
  equal(result[2][0], 2)
  equal(result[2][1], undefined)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3)
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3)
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3)
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '3 hoch')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '10.06.2014')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true')
  equal(el.find('tbody > tr:nth-child(4) > td').length, 0)

  App.TicketPriority.refresh([
    {
      id:         3,
      name:       '3 high',
      note:       'some note 3',
      active:     true,
      created_at: '2014-06-10T10:17:38.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T10:17:30.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'fullRender.contentRemoved')
  equal(result[1][0], 0)
  equal(result[1][1], undefined)
  equal(result[2][0], undefined)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3)
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '2 normal')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3)
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '3 hoch')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 0)

  App.TicketPriority.refresh([
    {
      id:         2,
      name:       '2 normal',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T10:17:30.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'fullRender.lenghtChanged')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3)
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '2 normal')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 0)

  App.TicketPriority.refresh([], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'emptyList')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Keine Einträge', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 0, 'check row 1')

  App.TicketPriority.refresh([
    {
      id:         2,
      name:       '2 normal',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T10:17:30.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'fullRender')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3)
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '2 normal')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 0)

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T10:17:30.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'fullRender.contentRemoved')
  equal(result[1][0], undefined)
  equal(result[2][0], 0)
  equal(result[2][1], undefined)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3)
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3)
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 0)

  App.TicketPriority.refresh([
    {
      id:         2,
      name:       '2 normal',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T10:17:30.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'fullRender.lenghtChanged')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3)
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '2 normal')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 0)

  $('#table').append('<hr><h1>table with large data and pager</h1><div id="table-new5"></div>')
  var el = $('#table-new5')

  var objects = [];
  var created_at = Date.parse('2014-06-10T11:17:34.000Z')

  for (i = 0; i < 151; i++) {
    local_created_at = new Date(created_at - (1000 * 60 * 60 * 24 * i)).toISOString()
    item = {
      id:         i,
      name:       i + ' prio',
      note:       'some note',
      active:     true,
      created_at: local_created_at,
    }
    objects.push(item)
  }

  App.TicketPriority.refresh(objects, {clear: true})

  var table = new App.ControllerTable({
    tableId:            'large_table_test_pager',
    el:                 el,
    overviewAttributes: ['name', 'created_at', 'active'],
    model:              App.TicketPriority,
    objects:            App.TicketPriority.all(),
    checkbox:           false,
    radio:              false,
    ttt: true
  })

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '0 prio', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '1 prio', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '09.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '2 prio', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '08.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr').length, 150)
  equal(el.find('tbody > tr:nth-child(151) > td').length, 0)

  equal(el.find('.js-pager').first().find('.js-page').length, 2)
  equal(el.find('.js-pager').first().find('.js-page.is-selected').length, 1)
  equal(el.find('.js-pager').first().find('.js-page.is-selected').text(), '1')
  el.find('.js-pager').first().find('.js-page:nth-child(2)').click()

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '150 prio', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '11.01.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr').length, 1)
  equal(el.find('tbody > tr:nth-child(2) > td').length, 0)

  objects = [
    {
      id:         500,
      name:       '500 prio',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T10:17:30.000Z',
    },
  ]

  App.TicketPriority.refresh(objects)

  result = table.update({sync: true, objects: App.TicketPriority.all()})
  equal(result[0], 'fullRender.contentRemoved')
  equal(result[1][0], undefined)
  equal(result[2][0], 1)
  equal(result[2][1], undefined)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '150 prio', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '11.01.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '500 prio', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr').length, 2)
  equal(el.find('tbody > tr:nth-child(3) > td').length, 0)

  objects = App.TicketPriority.all()
  objects.splice(2,1)
  result = table.update({sync: true, objects: objects})
  equal(result[0], 'fullRender.lenghtChanged')
  //equal(result[1][0], 1)
  //equal(result[1][1], undefined)
  //equal(result[2][0], undefined)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '500 prio', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr').length, 1)
  equal(el.find('tbody > tr:nth-child(2) > td').length, 0)

  objects.splice(2,1)
  result = table.update({sync: true, objects: objects})

  equal(result[0], 'fullRender.lenghtChanged')
  //equal(result[0], 'fullRender.contentRemoved')
  //equal(result[1][0], 1)
  //equal(result[1][1], undefined)
  //equal(result[2][0], undefined)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '0 prio', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '1 prio', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '09.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '4 prio', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '06.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr').length, 150)
  equal(el.find('tbody > tr:nth-child(151) > td').length, 0)

  equal(el.find('.js-pager').first().find('.js-page').length, 0)

  objects = [
    {
      id:         500,
      name:       '500 prio',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T10:17:30.000Z',
    },
  ]
  App.TicketPriority.refresh(objects)

  objects = App.TicketPriority.all()

  result = table.update({sync: true, objects: objects})
  equal(result[0], 'fullRender.contentRemoved')

  equal(el.find('.js-pager').first().find('.js-page').length, 2)
  equal(el.find('.js-pager').first().find('.js-page.is-selected').length, 1)
  equal(el.find('.js-pager').first().find('.js-page.is-selected').text(), '1')
  el.find('.js-pager').first().find('.js-page:nth-child(2)').click()

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '150 prio', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '11.01.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '500 prio', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr').length, 2)
  equal(el.find('tbody > tr:nth-child(3) > td').length, 0)

  equal(el.find('.js-pager').first().find('.js-page').length, 2)
  equal(el.find('.js-pager').first().find('.js-page.is-selected').length, 1)
  equal(el.find('.js-pager').first().find('.js-page.is-selected').text(), '2')
  el.find('.js-pager').first().find('.js-page:nth-child(1)').click()

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '0 prio', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '1 prio', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '09.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '2 prio', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '08.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr').length, 150)
  equal(el.find('tbody > tr:nth-child(151) > td').length, 0)

  equal(el.find('.js-pager').first().find('.js-page').length, 2)
  equal(el.find('.js-pager').first().find('.js-page.is-selected').length, 1)
  equal(el.find('.js-pager').first().find('.js-page.is-selected').text(), '1')

  objects.splice(2,2)

  result = table.update({sync: true, objects: objects})
  equal(result[0], 'fullRender.contentRemoved')

  equal(el.find('.js-pager').first().find('.js-page').length, 0)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '0 prio', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '1 prio', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '09.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '4 prio', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '06.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr').length, 150)
  equal(el.find('tbody > tr:nth-child(151) > td').length, 0)

  objects = [
    {
      id:         501,
      name:       '501 prio',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T10:17:30.000Z',
    },
  ]
  App.TicketPriority.refresh(objects)
  objects = App.TicketPriority.all()

  result = table.update({sync: true, objects: objects})
  equal(result[0], 'fullRender.contentRemoved')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '0 prio', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '1 prio', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '09.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '2 prio', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '08.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr').length, 150)
  equal(el.find('tbody > tr:nth-child(151) > td').length, 0)

  equal(el.find('.js-pager').first().find('.js-page').length, 2)
  equal(el.find('.js-pager').first().find('.js-page.is-selected').length, 1)
  equal(el.find('.js-pager').first().find('.js-page.is-selected').text(), '1')

  $('#table').append('<hr><h1>table with data 7</h1><div id="table-new7"></div>')
  var el = $('#table-new7')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note 1',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note 2',
      active:     false,
      created_at: '2014-06-10T10:17:34.000Z',
    },
    {
      id:         3,
      name:       '3 high',
      note:       'some note 3',
      active:     false,
      created_at: '2014-06-10T10:17:38.000Z',
    },
  ], {clear: true})

  var table = new App.ControllerTable({
    el:                 el,
    overviewAttributes: ['name', 'created_at', 'active'],
    model:              App.TicketPriority,
    objects:            App.TicketPriority.search({sortBy:'name', order: 'ASC'}),
    checkbox:           false,
    radio:              false,
  })
  //equal(el.find('table').length, 0, 'row count')
  //table.render()
  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '3 hoch', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td').length, 0, 'check row 3')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note',
      active:     true,
      created_at: '2014-06-12T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note 2',
      active:     false,
      created_at: '2014-06-10T10:17:34.000Z',
    },
    {
      id:         3,
      name:       '3 high',
      note:       'some note 3',
      active:     false,
      created_at: '2014-06-10T10:17:38.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'fullRender.contentRemoved')
  equal(result[1][0], 0)
  equal(result[1][1], undefined)
  equal(result[2][0], 0)
  equal(result[2][1], undefined)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '12.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '3 hoch', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td').length, 0, 'check row 3')

  $('#table').append('<hr><h1>table with data 8</h1><div id="table-new8"></div>')
  var el = $('#table-new8')
  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note',
      active:     true,
      created_at: '2014-06-12T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note 2',
      active:     false,
      created_at: '2014-06-10T10:17:34.000Z',
    },
    {
      id:         3,
      name:       '3 high',
      note:       'some note 3',
      active:     false,
      created_at: '2014-06-10T10:17:38.000Z',
    },
  ], {clear: true})

  var table = new App.ControllerTable({
    el:                 el,
    overviewAttributes: ['name', 'created_at', 'active'],
    model:              App.TicketPriority,
    objects:            App.TicketPriority.all(),
    checkbox:           false,
    radio:              false,
    orderBy:            'not_existing',
    orderDirection:     'DESC',
  })

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '12.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '3 hoch', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td').length, 0, 'check row 3')

  result = table.update({sync: true, objects: App.TicketPriority.all(), orderBy: 'not_existing', orderDirection: 'ASC'})
  equal(result[0], 'noChanges')

  $('#table').append('<hr><h1>table with data 9</h1><div id="table-new9"></div>')
  var el = $('#table-new9')
  App.TicketPriority.refresh([
    {
      id:          1,
      name:        '1 low',
      external_id: 3,
      note:        'some note',
      active:      true,
      created_at:  '2014-06-12T11:17:34.000Z',
    },
    {
      id:          2,
      name:        '2 normal',
      external_id: 2,
      note:        'some note 2',
      active:      false,
      created_at:  '2014-06-10T10:17:34.000Z',
    },
    {
      id:          3,
      name:        '3 high',
      external_id: 1,
      note:        'some note 3',
      active:      false,
      created_at:  '2014-06-10T10:17:38.000Z',
    },
  ], {clear: true})

  App.TicketPriority.resetAttributes()
  App.TicketPriority.updateAttributes([{
    name: 'external_id',
    display: 'External',
    tag: 'input',
    readonly: 1,
  }])

  var table = new App.ControllerTable({
    el:                 el,
    overviewAttributes: ['name', 'created_at', 'active'],
    model:              App.TicketPriority,
    objects:            App.TicketPriority.all(),
    checkbox:           false,
    radio:              false,
    orderBy:            'external',
    orderDirection:     'DESC',
  })

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '12.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '3 hoch', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td').length, 0, 'check row 3')

  result = table.update({sync: true, objects: App.TicketPriority.all(), orderBy: 'external', orderDirection: 'ASC'})
  equal(result[0], 'fullRender.contentChanged')
  equal(result[1], 0)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '3 hoch', 'check row 3')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '12.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 1')

  equal(el.find('tbody > tr:nth-child(4) > td').length, 0, 'check row 3')

  $('#table').append('<hr><h1>table with data 10</h1><div id="table-new10"></div>')
  var el = $('#table-new10')
  App.TicketPriority.refresh([
    {
      id:          1,
      name:        '1 low',
      external_id: 3,
      note:        'some note',
      active:      true,
      created_at:  '2014-06-12T11:17:34.000Z',
    },
    {
      id:          2,
      name:        '2 normal',
      external_id: 2,
      note:        'some note 2',
      active:      false,
      created_at:  '2014-06-10T10:17:34.000Z',
    },
    {
      id:          3,
      name:        '3 high',
      external_id: 1,
      note:        'some note 3',
      active:      false,
      created_at:  '2014-06-10T10:17:38.000Z',
    },
  ], {clear: true})
  App.TicketPriority.resetAttributes()
  App.TicketPriority.updateAttributes([{
    name: 'external',
    display: 'External',
    tag: 'input',
    readonly: 1,
  }])

  var table = new App.ControllerTable({
    el:                 el,
    overviewAttributes: ['name', 'created_at', 'active'],
    model:              App.TicketPriority,
    objects:            App.TicketPriority.all(),
    checkbox:           false,
    radio:              false,
    orderBy:            'external',
    orderDirection:     'ASC',
  })

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '12.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '3 hoch', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td').length, 0, 'check row 3')

  result = table.update({sync: true, objects: App.TicketPriority.all(), orderBy: 'external', orderDirection: 'DESC'})
  equal(result[0], 'fullRender.contentChanged')
  equal(result[1], 0)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '3 hoch', 'check row 3')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '12.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 1')

  equal(el.find('tbody > tr:nth-child(4) > td').length, 0, 'check row 3')

  $('#table').append('<hr><h1>table with data 11</h1><div id="table-new11"></div>')
  var el = $('#table-new11')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note 1',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note 2',
      active:     false,
      created_at: '2014-06-10T10:17:34.000Z',
    },
  ], {clear: true})

  var table = new App.ControllerTable({
    el:                        el,
    overviewAttributes:        ['name', 'created_at', 'active'],
    model:                     App.TicketPriority,
    objects:                   App.TicketPriority.search({sortBy:'name', order: 'ASC'}),
    checkbox:                  false,
    radio:                     false,
    frontendTimeUpdateExecute: false,
  })
  //equal(el.find('table').length, 0, 'row count')
  //table.render()
  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 0, 'check row 3')

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'noChanges')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '', 'check row 2')

})
