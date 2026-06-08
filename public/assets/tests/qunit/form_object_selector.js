var testCount = 0

var testSetup = (config) => {
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
      active:     true,
      created_at: '2014-06-10T10:17:34.000Z',
    },
    {
      id:         3,
      name:       '3 high',
      note:       'some note 3',
      active:     true,
      created_at: '2014-06-10T10:17:44.000Z',
    },
  ])

  App.TicketState.refresh([
    {
      id:         1,
      name:       'new',
      note:       'some note 1',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       'open',
      note:       'some note 2',
      active:     true,
      created_at: '2014-06-10T10:17:34.000Z',
    },
  ])

  App.Group.refresh([
    {
      id:        1,
      name_last: 'group 1',
    },
    {
      id:         2,
      name_last: 'group 2',
    },
  ])

  App.User.refresh([
    {
      id:         47,
      login:      'bod@example.com',
      email:      'bod@example.com',
      firstname:  'Bob',
      lastname:   'Smith',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
  ])

  App.Organization.refresh([
    {
      id:         12,
      name:      'Org 1',
      active:     true,
      created_at: '2014-06-10T11:19:34.000Z',
    },
  ])

  App.Calendar.refresh([{"id":1,"name":"United Kingdom","timezone":"Europe/London","business_hours":{"mon":{"active":true,"timeframes":[["09:00","17:00"]]},"tue":{"active":true,"timeframes":[["09:00","17:00"]]},"wed":{"active":true,"timeframes":[["09:00","17:00"]]},"thu":{"active":true,"timeframes":[["09:00","17:00"]]},"fri":{"active":true,"timeframes":[["09:00","17:00"]]},"sat":{"active":false,"timeframes":[["09:00","17:00"]]},"sun":{"active":false,"timeframes":[["09:00","17:00"]]}},"default":true,"ical_url":"https://www.google.com/calendar/ical/en.uk%23holiday%40group.v.calendar.google.com/public/basic.ics","public_holidays":{"2021-11-30":{"active":true,"summary":"St Andrew's Day (Scotland)","feed":"fd000ebe4820b488646a39a520a2b03f"},"2021-12-24":{"active":true,"summary":"Christmas Eve","feed":"fd000ebe4820b488646a39a520a2b03f"},"2021-12-25":{"active":true,"summary":"Christmas Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2021-12-26":{"active":true,"summary":"Boxing Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2021-12-27":{"active":true,"summary":"Substitute Bank Holiday for Christmas Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2021-12-28":{"active":true,"summary":"Substitute Bank Holiday for Boxing Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2021-12-31":{"active":true,"summary":"New Year's Eve","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-01-01":{"active":true,"summary":"New Year's Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-01-03":{"active":true,"summary":"New Year's Day observed","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-01-04":{"active":true,"summary":"2nd January (substitute day) (Scotland)","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-01-05":{"active":true,"summary":"Twelfth Night","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-02-14":{"active":true,"summary":"Valentine's Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-03-01":{"active":true,"summary":"Carnival / Shrove Tuesday / Pancake Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-03-17":{"active":true,"summary":"St Patrick's Day (Northern Ireland)","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-03-27":{"active":true,"summary":"Mother's Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-04-15":{"active":true,"summary":"Good Friday","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-04-17":{"active":true,"summary":"Easter Sunday","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-04-18":{"active":true,"summary":"Easter Monday (regional holiday)","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-04-23":{"active":true,"summary":"St. George's Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-05-02":{"active":true,"summary":"Early May Bank Holiday","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-06-02":{"active":true,"summary":"Spring Bank Holiday","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-06-03":{"active":true,"summary":"Queen Elizabeth II's Platinum Jubilee","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-06-11":{"active":true,"summary":"Queen Elizabeth II's Birthday","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-06-19":{"active":true,"summary":"Father's Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-07-12":{"active":true,"summary":"Battle of the Boyne (Northern Ireland)","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-08-01":{"active":true,"summary":"Summer Bank Holiday (Scotland)","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-08-29":{"active":true,"summary":"Summer Bank Holiday (regional holiday)","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-09-19":{"active":true,"summary":"State Funeral of Queen Elizabeth II","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-10-31":{"active":true,"summary":"Halloween","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-11-05":{"active":true,"summary":"Guy Fawkes Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-11-13":{"active":true,"summary":"Remembrance Sunday","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-11-30":{"active":true,"summary":"St Andrew's Day (Scotland)","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-12-24":{"active":true,"summary":"Christmas Eve","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-12-25":{"active":true,"summary":"Christmas Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-12-26":{"active":true,"summary":"Boxing Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-12-27":{"active":true,"summary":"Substitute Bank Holiday for Christmas Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2022-12-31":{"active":true,"summary":"New Year's Eve","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-01-01":{"active":true,"summary":"New Year's Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-01-02":{"active":true,"summary":"New Year's Day observed","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-01-03":{"active":true,"summary":"2nd January (substitute day) (Scotland)","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-01-05":{"active":true,"summary":"Twelfth Night","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-02-14":{"active":true,"summary":"Valentine's Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-02-21":{"active":true,"summary":"Carnival / Shrove Tuesday / Pancake Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-03-17":{"active":true,"summary":"St Patrick's Day (Northern Ireland)","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-03-19":{"active":true,"summary":"Mother's Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-04-07":{"active":true,"summary":"Good Friday","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-04-09":{"active":true,"summary":"Easter Sunday","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-04-10":{"active":true,"summary":"Easter Monday (regional holiday)","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-04-23":{"active":true,"summary":"St. George's Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-05-01":{"active":true,"summary":"Early May Bank Holiday","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-05-06":{"active":true,"summary":"The Coronation of King Charles III","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-05-08":{"active":true,"summary":"Bank Holiday for the Coronation of King Charles III","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-05-29":{"active":true,"summary":"Spring Bank Holiday","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-06-10":{"active":true,"summary":"King's Birthday","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-06-18":{"active":true,"summary":"Father's Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-07-12":{"active":true,"summary":"Battle of the Boyne (Northern Ireland)","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-08-07":{"active":true,"summary":"Summer Bank Holiday (Scotland)","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-08-28":{"active":true,"summary":"Summer Bank Holiday (regional holiday)","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-10-31":{"active":true,"summary":"Halloween","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-11-05":{"active":true,"summary":"Guy Fawkes Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-11-12":{"active":true,"summary":"Remembrance Sunday","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-11-30":{"active":true,"summary":"St Andrew's Day (Scotland)","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-12-24":{"active":true,"summary":"Christmas Eve","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-12-25":{"active":true,"summary":"Christmas Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-12-26":{"active":true,"summary":"Boxing Day","feed":"fd000ebe4820b488646a39a520a2b03f"},"2023-12-31":{"active":true,"summary":"New Year's Eve","feed":"fd000ebe4820b488646a39a520a2b03f"}},"last_log":null,"last_sync":"2022-11-24T17:18:41.544Z","updated_by_id":1,"created_by_id":1,"created_at":"2022-11-21T09:20:33.577Z","updated_at":"2022-11-24T17:18:41.551Z"}])

  App.ObjectManagerAttribute.refresh([{"name":"number","object":"Ticket","display":"#","active":true,"editable":false,"data_type":"input","data_option":{"type":"text","readonly":1,"null":true,"maxlength":60,"width":"68px"},"screens":{"create_top":{},"edit":{}},"position":5,"id":1},{"name":"title","object":"Ticket","display":"Title","active":true,"editable":false,"data_type":"input","data_option":{"type":"text","maxlength":200,"null":false,"translate":false},"screens":{"create_top":{"-all-":{"null":false}},"edit":{}},"position":8,"id":2},{"name":"customer_id","object":"Ticket","display":"Customer","active":true,"editable":false,"data_type":"user_autocompletion","data_option":{"relation":"User","autocapitalize":false,"multiple":false,"guess":true,"null":false,"limit":200,"placeholder":"Enter Person or Organization/Company","minLengt":2,"translate":false,"permission":["ticket.agent"]},"screens":{"create_top":{"-all-":{"null":false}},"edit":{}},"position":10,"id":3},{"name":"organization_id","object":"Ticket","display":"Organization","active":true,"editable":false,"data_type":"autocompletion_ajax_customer_organization","data_option":{"relation":"Organization","autocapitalize":false,"multiple":false,"null":true,"translate":false,"permission":["ticket.agent","ticket.customer"]},"screens":{"create_top":{"-all-":{"null":false}},"edit":{}},"position":12,"id":4},{"name":"type","object":"Ticket","display":"Type","active":false,"editable":true,"data_type":"select","data_option":{"default":"","options":{"Incident":"Incident","Problem":"Problem","Request for Change":"Request for Change"},"nulloption":true,"multiple":false,"null":true,"translate":true,"maxlength":255},"screens":{"create_middle":{"-all-":{"null":false,"item_class":"column"}},"edit":{"ticket.agent":{"null":false}}},"position":20,"id":5},{"name":"group_id","object":"Ticket","display":"Group","active":true,"editable":false,"data_type":"select","data_option":{"default":"","relation":"Group","relation_condition":{"access":"full"},"nulloption":true,"multiple":false,"null":false,"translate":false,"only_shown_if_selectable":true,"permission":["ticket.agent","ticket.customer"],"maxlength":255},"screens":{"create_middle":{"-all-":{"null":false,"item_class":"column"}},"edit":{"ticket.agent":{"null":false}}},"position":25,"id":6},{"name":"owner_id","object":"Ticket","display":"Owner","active":true,"editable":false,"data_type":"select","data_option":{"default":"","relation":"User","relation_condition":{"roles":"Agent"},"nulloption":true,"multiple":false,"null":true,"translate":false,"permission":["ticket.agent"],"maxlength":255},"screens":{"create_middle":{"-all-":{"null":true,"item_class":"column"}},"edit":{"-all-":{"null":true}}},"position":30,"id":7},{"name":"state_id","object":"Ticket","display":"State","active":true,"editable":false,"data_type":"select","data_option":{"relation":"TicketState","nulloption":true,"multiple":false,"null":false,"default":2,"translate":true,"filter":[2,1,3,4,6,7],"maxlength":255},"screens":{"create_middle":{"ticket.agent":{"null":false,"item_class":"column","filter":[2,1,3,4,7]},"ticket.customer":{"item_class":"column","nulloption":false,"null":true,"filter":[1,4],"default":1}},"edit":{"ticket.agent":{"nulloption":false,"null":false,"filter":[2,3,4,7]},"ticket.customer":{"nulloption":false,"null":true,"filter":[2,4],"default":2}}},"position":40,"id":8},{"name":"pending_time","object":"Ticket","display":"Pending till","active":true,"editable":false,"data_type":"datetime","data_option":{"future":true,"past":false,"diff":null,"null":true,"translate":true,"permission":["ticket.agent"]},"screens":{"create_middle":{"-all-":{"null":false,"item_class":"column"}},"edit":{"-all-":{"null":false}}},"position":41,"id":9},{"name":"priority_id","object":"Ticket","display":"Priority","active":true,"editable":false,"data_type":"select","data_option":{"relation":"TicketPriority","nulloption":false,"multiple":false,"null":false,"default":2,"translate":true,"maxlength":255},"screens":{"create_middle":{"ticket.agent":{"null":false,"item_class":"column"}},"edit":{"ticket.agent":{"null":false}}},"position":80,"id":10},{"name":"login","object":"User","display":"Login","active":true,"editable":false,"data_type":"input","data_option":{"type":"text","maxlength":100,"null":true,"autocapitalize":false,"item_class":"formGroup--halfSize"},"screens":{"signup":{},"invite_agent":{},"invite_customer":{},"edit":{},"view":{"-all-":{"shown":false}}},"position":100,"id":17},{"name":"type_id","object":"TicketArticle","display":"Type","active":true,"editable":false,"data_type":"select","data_option":{"relation":"TicketArticleType","nulloption":false,"multiple":false,"null":false,"default":10,"translate":true,"maxlength":255},"screens":{"create_middle":{},"edit":{"ticket.agent":{"null":false}}},"position":100,"id":12},{"name":"firstname","object":"User","display":"First name","active":true,"editable":false,"data_type":"input","data_option":{"type":"text","maxlength":150,"null":true,"item_class":"formGroup--halfSize"},"screens":{"signup":{"-all-":{"null":true}},"invite_agent":{"-all-":{"null":true}},"invite_customer":{"-all-":{"null":true}},"edit":{"-all-":{"null":true}},"create":{"-all-":{"null":true}},"view":{"-all-":{"shown":true}}},"position":200,"id":18},{"name":"internal","object":"TicketArticle","display":"Visibility","active":true,"editable":false,"data_type":"select","data_option":{"options":{"true":"internal","false":"public"},"nulloption":false,"multiple":false,"null":true,"default":false,"translate":true,"maxlength":255},"screens":{"create_middle":{},"edit":{"ticket.agent":{"null":false}}},"position":200,"id":13},{"name":"name","object":"Group","display":"Name","active":true,"editable":false,"data_type":"input","data_option":{"type":"text","maxlength":150,"null":false},"screens":{"create":{"-all-":{"null":false}},"edit":{"-all-":{"null":false}},"view":{"-all-":{"shown":true}}},"position":200,"id":44},{"name":"name","object":"Organization","display":"Name","active":true,"editable":false,"data_type":"input","data_option":{"type":"text","maxlength":150,"null":false,"item_class":"formGroup--halfSize"},"screens":{"edit":{"-all-":{"null":false}},"create":{"-all-":{"null":false}},"view":{"ticket.agent":{"shown":true},"ticket.customer":{"shown":true}}},"position":200,"id":38},{"name":"assignment_timeout","object":"Group","display":"Assignment Timeout","active":true,"editable":false,"data_type":"integer","data_option":{"maxlength":150,"null":true,"note":"Assignment timeout in minutes if assigned agent is not working on it. Ticket will be shown as unassigend.","min":0,"max":999999},"screens":{"create":{"-all-":{"null":true}},"edit":{"-all-":{"null":true}}},"position":300,"id":45},{"name":"lastname","object":"User","display":"Last name","active":true,"editable":false,"data_type":"input","data_option":{"type":"text","maxlength":150,"null":true,"item_class":"formGroup--halfSize"},"screens":{"signup":{"-all-":{"null":true}},"invite_agent":{"-all-":{"null":true}},"invite_customer":{"-all-":{"null":true}},"edit":{"-all-":{"null":true}},"create":{"-all-":{"null":true}},"view":{"-all-":{"shown":true}}},"position":300,"id":19},{"name":"to","object":"TicketArticle","display":"To","active":true,"editable":false,"data_type":"input","data_option":{"type":"text","maxlength":1000,"null":true},"screens":{"create_middle":{},"edit":{"ticket.agent":{"null":true}}},"position":300,"id":14},{"name":"cc","object":"TicketArticle","display":"CC","active":true,"editable":false,"data_type":"input","data_option":{"type":"text","maxlength":1000,"null":true},"screens":{"create_top":{},"create_middle":{},"edit":{"ticket.agent":{"null":true}}},"position":400,"id":15},{"name":"email","object":"User","display":"Email","active":true,"editable":false,"data_type":"input","data_option":{"type":"email","maxlength":150,"null":true,"item_class":"formGroup--halfSize"},"screens":{"signup":{"-all-":{"null":true}},"invite_agent":{"-all-":{"null":true}},"invite_customer":{"-all-":{"null":true}},"edit":{"-all-":{"null":true}},"create":{"-all-":{"null":true}},"view":{"-all-":{"shown":true}}},"position":400,"id":20},{"name":"follow_up_possible","object":"Group","display":"Follow-up possible","active":true,"editable":false,"data_type":"select","data_option":{"default":"yes","options":{"yes":"yes","new_ticket":"do not reopen Ticket but create new Ticket"},"null":false,"note":"Follow-up for closed ticket possible or not.","translate":true,"nulloption":true,"maxlength":255},"screens":{"create":{"-all-":{"null":false}},"edit":{"-all-":{"null":false}}},"position":400,"id":46},{"name":"follow_up_assignment","object":"Group","display":"Assign Follow-Ups","active":true,"editable":false,"data_type":"select","data_option":{"default":"true","options":{"true":"yes","false":"no"},"null":false,"note":"Assign follow-up to latest agent again.","translate":true,"nulloption":true,"maxlength":255},"screens":{"create":{"-all-":{"null":false}},"edit":{"-all-":{"null":false}}},"position":500,"id":47},{"name":"web","object":"User","display":"Web","active":true,"editable":false,"data_type":"input","data_option":{"type":"url","maxlength":250,"null":true,"item_class":"formGroup--halfSize"},"screens":{"signup":{},"invite_agent":{},"invite_customer":{},"edit":{"-all-":{"null":true}},"create":{"-all-":{"null":true}},"view":{"-all-":{"shown":true}}},"position":500,"id":21},{"name":"body","object":"TicketArticle","display":"Text","active":true,"editable":false,"data_type":"richtext","data_option":{"type":"richtext","maxlength":150000,"upload":true,"rows":8,"null":true},"screens":{"create_top":{"-all-":{"null":false}},"edit":{"-all-":{"null":true}}},"position":600,"id":16},{"name":"email_address_id","object":"Group","display":"Email","active":true,"editable":false,"data_type":"select","data_option":{"default":"","multiple":false,"null":true,"relation":"EmailAddress","nulloption":true,"do_not_log":true,"maxlength":255},"screens":{"create":{"-all-":{"null":true}},"edit":{"-all-":{"null":true}}},"position":600,"id":48},{"name":"phone","object":"User","display":"Phone","active":true,"editable":false,"data_type":"input","data_option":{"type":"tel","maxlength":100,"null":true,"item_class":"formGroup--halfSize"},"screens":{"signup":{},"invite_agent":{},"invite_customer":{},"edit":{"-all-":{"null":true}},"create":{"-all-":{"null":true}},"view":{"-all-":{"shown":true}}},"position":600,"id":22},{"name":"signature_id","object":"Group","display":"Signature","active":true,"editable":false,"data_type":"select","data_option":{"default":"","multiple":false,"null":true,"relation":"Signature","nulloption":true,"do_not_log":true,"maxlength":255},"screens":{"create":{"-all-":{"null":true}},"edit":{"-all-":{"null":true}}},"position":600,"id":49},{"name":"mobile","object":"User","display":"Mobile","active":true,"editable":false,"data_type":"input","data_option":{"type":"tel","maxlength":100,"null":true,"item_class":"formGroup--halfSize"},"screens":{"signup":{},"invite_agent":{},"invite_customer":{},"edit":{"-all-":{"null":true}},"create":{"-all-":{"null":true}},"view":{"-all-":{"shown":true}}},"position":700,"id":23},{"name":"fax","object":"User","display":"Fax","active":true,"editable":false,"data_type":"input","data_option":{"type":"tel","maxlength":100,"null":true,"item_class":"formGroup--halfSize"},"screens":{"signup":{},"invite_agent":{},"invite_customer":{},"edit":{"-all-":{"null":true}},"create":{"-all-":{"null":true}},"view":{"-all-":{"shown":true}}},"position":800,"id":24},{"name":"organization_id","object":"User","display":"Organization","active":true,"editable":false,"data_type":"autocompletion_ajax","data_option":{"multiple":false,"nulloption":true,"null":true,"relation":"Organization","item_class":"formGroup--halfSize"},"screens":{"signup":{},"invite_agent":{},"invite_customer":{"-all-":{"null":true}},"edit":{"-all-":{"null":true}},"create":{"-all-":{"null":true}},"view":{"-all-":{"shown":true}}},"position":900,"id":25},{"name":"tags","object":"Ticket","display":"Tags","active":true,"editable":false,"data_type":"tag","data_option":{"type":"text","null":true,"translate":false},"screens":{"create_bottom":{"ticket.agent":{"null":true}},"edit":{}},"position":900,"id":11},{"name":"organization_ids","object":"User","display":"Secondary organizations","active":true,"editable":false,"data_type":"autocompletion_ajax","data_option":{"multiple":true,"nulloption":true,"null":true,"relation":"Organization","item_class":"formGroup--halfSize","display_limit":3},"screens":{"signup":{},"invite_agent":{},"invite_customer":{"-all-":{"null":true}},"edit":{"-all-":{"null":true}},"create":{"-all-":{"null":true}},"view":{"-all-":{"shown":true}}},"position":901,"id":26},{"name":"test_text","object":"Ticket","display":"test_text","active":true,"editable":true,"data_type":"input","data_option":{"default":"","type":"text","maxlength":120,"linktemplate":"","null":true,"options":{},"relation":""},"screens":{"create_middle":{"ticket.customer":{"shown":true,"required":false,"item_class":"column"},"ticket.agent":{"shown":true,"required":false,"item_class":"column"}},"edit":{"ticket.customer":{"shown":true,"required":false},"ticket.agent":{"shown":true,"required":false}}},"position":901,"id":61},{"name":"test_textarea","object":"Ticket","display":"test_textarea","active":true,"editable":true,"data_type":"textarea","data_option":{"default":"","maxlength":500,"rows":4,"null":true,"options":{},"relation":""},"screens":{"create_middle":{"ticket.customer":{"shown":true,"required":false,"item_class":"column"},"ticket.agent":{"shown":true,"required":false,"item_class":"column"}},"edit":{"ticket.customer":{"shown":true,"required":false},"ticket.agent":{"shown":true,"required":false}}},"position":902,"id":62},{"name":"test_integer","object":"Ticket","display":"test_integer","active":true,"editable":true,"data_type":"integer","data_option":{"default":null,"min":0,"max":999999999,"null":true,"options":{},"relation":""},"screens":{"create_middle":{"ticket.customer":{"shown":true,"required":false,"item_class":"column"},"ticket.agent":{"shown":true,"required":false,"item_class":"column"}},"edit":{"ticket.customer":{"shown":true,"required":false},"ticket.agent":{"shown":true,"required":false}}},"position":903,"id":63},{"name":"test_date","object":"Ticket","display":"test_date","active":true,"editable":true,"data_type":"date","data_option":{"diff":null,"default":null,"null":true,"options":{},"relation":""},"screens":{"create_middle":{"ticket.customer":{"shown":true,"required":false,"item_class":"column"},"ticket.agent":{"shown":true,"required":false,"item_class":"column"}},"edit":{"ticket.customer":{"shown":true,"required":false},"ticket.agent":{"shown":true,"required":false}}},"position":904,"id":64},{"name":"test_datetime","object":"Ticket","display":"test_datetime","active":true,"editable":true,"data_type":"datetime","data_option":{"future":true,"past":true,"diff":null,"default":null,"null":true,"options":{},"relation":""},"screens":{"create_middle":{"ticket.customer":{"shown":true,"required":false,"item_class":"column"},"ticket.agent":{"shown":true,"required":false,"item_class":"column"}},"edit":{"ticket.customer":{"shown":true,"required":false},"ticket.agent":{"shown":true,"required":false}}},"position":905,"id":65},{"name":"test_select","object":"Ticket","display":"test_select","active":true,"editable":true,"data_type":"select","data_option":{"options":{"a":"A","b":"B","c":"C"},"linktemplate":"","default":"","null":true,"relation":"","nulloption":true,"maxlength":255,"historical_options":{"a":"A","b":"B","c":"C"}},"screens":{"create_middle":{"ticket.customer":{"shown":true,"required":false,"item_class":"column"},"ticket.agent":{"shown":true,"required":false,"item_class":"column"}},"edit":{"ticket.customer":{"shown":true,"required":false},"ticket.agent":{"shown":true,"required":false}}},"position":906,"id":66},{"name":"test_multiselect","object":"Ticket","display":"test_multiselect","active":true,"editable":true,"data_type":"multiselect","data_option":{"options":{"a":"A","b":"B","c":"C"},"linktemplate":"","default":[],"null":true,"relation":"","nulloption":true,"maxlength":255,"multiple":true,"historical_options":{"a":"A","b":"B","c":"C"}},"screens":{"create_middle":{"ticket.customer":{"shown":true,"required":false,"item_class":"column"},"ticket.agent":{"shown":true,"required":false,"item_class":"column"}},"edit":{"ticket.customer":{"shown":true,"required":false},"ticket.agent":{"shown":true,"required":false}}},"position":907,"id":67},{"name":"test_tree_select","object":"Ticket","display":"test_tree_select","active":true,"editable":true,"data_type":"tree_select","data_option":{"options":[{"name":"a","value":"a","children":[{"name":"b","value":"a::b","children":[{"name":"c","value":"a::b::c"}]}]}],"default":"","null":true,"relation":"","nulloption":true,"maxlength":255,"historical_options":{"a":"a","a::b":"b","a::b::c":"c"}},"screens":{"create_middle":{"ticket.customer":{"shown":true,"required":false,"item_class":"column"},"ticket.agent":{"shown":true,"required":false,"item_class":"column"}},"edit":{"ticket.customer":{"shown":true,"required":false},"ticket.agent":{"shown":true,"required":false}}},"position":908,"id":68},{"name":"test_multi_tree_select","object":"Ticket","display":"test_multi_tree_select","active":true,"editable":true,"data_type":"multi_tree_select","data_option":{"options":[{"name":"a","value":"a","children":[{"name":"b","value":"a::b","children":[{"name":"c","value":"a::b::c"}]}]}],"default":null,"null":true,"relation":"","multiple":true},"screens":{"create_middle":{"ticket.customer":{"shown":true,"required":false,"item_class":"column"},"ticket.agent":{"shown":true,"required":false,"item_class":"column"}},"edit":{"ticket.customer":{"shown":true,"required":false},"ticket.agent":{"shown":true,"required":false}}},"position":909,"id":69},{"name":"department","object":"User","display":"Department","active":true,"editable":true,"data_type":"input","data_option":{"type":"text","maxlength":200,"null":true,"item_class":"formGroup--halfSize"},"screens":{"signup":{},"invite_agent":{},"invite_customer":{},"edit":{"-all-":{"null":true}},"create":{"-all-":{"null":true}},"view":{"-all-":{"shown":true}}},"position":1000,"id":27},{"name":"street","object":"User","display":"Street","active":false,"editable":true,"data_type":"input","data_option":{"type":"text","maxlength":100,"null":true},"screens":{"signup":{},"invite_agent":{},"invite_customer":{},"edit":{"-all-":{"null":true}},"create":{"-all-":{"null":true}},"view":{"-all-":{"shown":true}}},"position":1100,"id":28},{"name":"zip","object":"User","display":"Zip","active":false,"editable":true,"data_type":"input","data_option":{"type":"text","maxlength":100,"null":true,"item_class":"formGroup--halfSize"},"screens":{"signup":{},"invite_agent":{},"invite_customer":{},"edit":{"-all-":{"null":true}},"create":{"-all-":{"null":true}},"view":{"-all-":{"shown":true}}},"position":1200,"id":29},{"name":"city","object":"User","display":"City","active":false,"editable":true,"data_type":"input","data_option":{"type":"text","maxlength":100,"null":true,"item_class":"formGroup--halfSize"},"screens":{"signup":{},"invite_agent":{},"invite_customer":{},"edit":{"-all-":{"null":true}},"create":{"-all-":{"null":true}},"view":{"-all-":{"shown":true}}},"position":1300,"id":30},{"name":"country","object":"User","display":"Country","active":false,"editable":true,"data_type":"input","data_option":{"type":"text","maxlength":100,"null":true,"item_class":"formGroup--halfSize"},"screens":{"signup":{},"invite_agent":{},"invite_customer":{},"edit":{"-all-":{"null":true}},"create":{"-all-":{"null":true}},"view":{"-all-":{"shown":true}}},"position":1325,"id":31},{"name":"address","object":"User","display":"Address","active":true,"editable":true,"data_type":"textarea","data_option":{"type":"text","maxlength":500,"rows":4,"null":true,"item_class":"formGroup--halfSize"},"screens":{"signup":{},"invite_agent":{},"invite_customer":{},"edit":{"-all-":{"null":true}},"create":{"-all-":{"null":true}},"view":{"-all-":{"shown":true}}},"position":1350,"id":32},{"name":"password","object":"User","display":"Password","active":true,"editable":false,"data_type":"input","data_option":{"type":"password","maxlength":1001,"null":true,"autocomplete":"new-password","item_class":"formGroup--halfSize"},"screens":{"signup":{"-all-":{"null":false}},"invite_agent":{},"invite_customer":{},"edit":{"admin.user":{"null":true}},"create":{"-all-":{"null":true}},"view":{}},"position":1400,"id":33},{"name":"shared","object":"Organization","display":"Shared organization","active":true,"editable":false,"data_type":"boolean","data_option":{"null":true,"default":true,"note":"Customers in the organization can view each other's items.","item_class":"formGroup--halfSize","options":{"true":"yes","false":"no"},"translate":true,"permission":["admin.organization"]},"screens":{"edit":{"-all-":{"null":false}},"create":{"-all-":{"null":false}},"view":{"ticket.agent":{"shown":true},"ticket.customer":{"shown":false}}},"position":1400,"id":39},{"name":"shared_drafts","object":"Group","display":"Shared Drafts","active":true,"editable":false,"data_type":"active","data_option":{"null":false,"default":true,"permission":["admin.group"]},"screens":{"create":{"-all-":{"null":true}},"edit":{"-all-":{"null":false}},"view":{"-all-":{"shown":false}}},"position":1400,"id":50},{"name":"domain_assignment","object":"Organization","display":"Domain based assignment","active":true,"editable":false,"data_type":"boolean","data_option":{"null":true,"default":false,"note":"Assign users based on user domain.","item_class":"formGroup--halfSize","options":{"true":"yes","false":"no"},"translate":true,"permission":["admin.organization"]},"screens":{"edit":{"-all-":{"null":false}},"create":{"-all-":{"null":false}},"view":{"ticket.agent":{"shown":true},"ticket.customer":{"shown":false}}},"position":1410,"id":40},{"name":"domain","object":"Organization","display":"Domain","active":true,"editable":false,"data_type":"input","data_option":{"type":"text","maxlength":150,"null":true,"item_class":"formGroup--halfSize"},"screens":{"edit":{"-all-":{"null":true}},"create":{"-all-":{"null":true}},"view":{"ticket.agent":{"shown":true},"ticket.customer":{"shown":false}}},"position":1420,"id":41},{"name":"vip","object":"User","display":"VIP","active":true,"editable":false,"data_type":"boolean","data_option":{"null":true,"default":false,"item_class":"formGroup--halfSize","options":{"false":"no","true":"yes"},"translate":true,"permission":["admin.user","ticket.agent"]},"screens":{"edit":{"-all-":{"null":true}},"create":{"-all-":{"null":true}},"view":{"-all-":{"shown":false}}},"position":1490,"id":34},{"name":"note","object":"Group","display":"Note","active":true,"editable":false,"data_type":"richtext","data_option":{"type":"text","maxlength":250,"null":true,"note":"Notes are visible to agents only, never to customers."},"screens":{"create":{"-all-":{"null":true}},"edit":{"-all-":{"null":true}},"view":{"-all-":{"shown":true}}},"position":1500,"id":51},{"name":"note","object":"Organization","display":"Note","active":true,"editable":false,"data_type":"richtext","data_option":{"type":"text","maxlength":5000,"null":true,"note":"Notes are visible to agents only, never to customers."},"screens":{"edit":{"-all-":{"null":true}},"create":{"-all-":{"null":true}},"view":{"ticket.agent":{"shown":true},"ticket.customer":{"shown":false}}},"position":1500,"id":42},{"name":"note","object":"User","display":"Note","active":true,"editable":false,"data_type":"richtext","data_option":{"type":"text","maxlength":5000,"null":true,"note":"Notes are visible to agents only, never to customers."},"screens":{"signup":{},"invite_agent":{},"invite_customer":{"-all-":{"null":true}},"edit":{"-all-":{"null":true}},"create":{"-all-":{"null":true}},"view":{"-all-":{"shown":true}}},"position":1500,"id":35},{"name":"role_ids","object":"User","display":"Permissions","active":true,"editable":false,"data_type":"user_permission","data_option":{"null":false,"item_class":"checkbox","permission":["admin.user"]},"screens":{"signup":{},"invite_agent":{"-all-":{"null":false,"default":[2]}},"invite_customer":{},"edit":{"-all-":{"null":true}},"create":{"-all-":{"null":true}},"view":{"-all-":{"shown":false}}},"position":1600,"id":36},{"name":"active","object":"Organization","display":"Active","active":true,"editable":false,"data_type":"active","data_option":{"null":true,"default":true,"permission":["admin.organization"]},"screens":{"edit":{"-all-":{"null":false}},"create":{"-all-":{"null":false}},"view":{"ticket.agent":{"shown":true},"ticket.customer":{"shown":false}}},"position":1800,"id":43},{"name":"active","object":"User","display":"Active","active":true,"editable":false,"data_type":"active","data_option":{"null":true,"default":true,"permission":["admin.user","ticket.agent"]},"screens":{"signup":{},"invite_agent":{},"invite_customer":{},"edit":{"-all-":{"null":false}},"create":{"-all-":{"null":false}},"view":{"-all-":{"shown":false}}},"position":1800,"id":37},{"name":"active","object":"Group","display":"Active","active":true,"editable":false,"data_type":"active","data_option":{"null":true,"default":true,"permission":["admin.group"]},"screens":{"create":{"-all-":{"null":true}},"edit":{"-all-":{"null":false}},"view":{"-all-":{"shown":false}}},"position":1800,"id":52}])

  for (setting of config) {
    App.Config.set(setting.name, setting.value)
  }

  testCount++

  var { testName } = QUnit.config.current

  return {
    testCount,
    testName,
  }
}

/*
 * Examples in this group are with expert conditions turned on.
 */
QUnit.module('form object selector - with expert conditions')

QUnit.test('defaults to ticket object', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: true }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'object_selector' },
      ]
    },
    autofocus: true
  })
  var params = App.ControllerForm.params(el)
  var test_params = {
    condition: {
      'ticket.state_id': {
        operator: 'is',
        value: [],
      },
    },
  }
  assert.deepEqual(params, test_params, 'params structure')
})

QUnit.test('supports ticket object', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: true }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  var defaults = {
    object: 'Ticket',
  }
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'object_selector' },
      ]
    },
    params: defaults,
    autofocus: true
  })
  var params = App.ControllerForm.params(el)
  var test_params = {
    condition: {
      'ticket.state_id': {
        operator: 'is',
        value: [],
      },
    },
  }
  assert.deepEqual(params, test_params, 'params structure')
  assert.deepEqual(el.find('.js-attributeSelector').find('optgroup').map(function () { return $(this).attr('label') }).toArray(), ['Ticket', 'Article', 'Customer', 'Organization'], 'has correct groups')

  assert.notOk(el.find('.js-switch input').prop('checked'), 'expert mode switch is off')
})

QUnit.test('supports user object', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: true }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  var defaults = {
    object: 'User',
  }
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'object_selector' },
      ]
    },
    params: defaults,
    autofocus: true
  })
  var params = App.ControllerForm.params(el)
  var test_params = {
    condition: {
      'user.role_ids': { // default
        operator: 'is',
        value: [],
      },
    },
  }
  assert.deepEqual(params, test_params, 'params structure')
  assert.deepEqual(el.find('.js-attributeSelector').find('optgroup').map(function () { return $(this).attr('label') }).toArray(), ['User', 'Ticket Customer', 'Ticket Owner', 'Organization'], 'has correct groups')

  // Special attributes
  assert.ok(el.find('.js-attributeSelector optgroup[label="User"] option').filter(function () { return $(this).text() === 'Role' }).length, 'has Role attribute')
  assert.ok(el.find('.js-attributeSelector optgroup[label="User"] option').filter(function () { return $(this).text() === 'Last login' }).length, 'has Last login attribute')
  assert.ok(el.find('.js-attributeSelector optgroup[label="Ticket Customer"] option').filter(function () { return $(this).text() === 'Last contact' }).length, 'has Ticket Customer Last contact attribute')
  assert.ok(el.find('.js-attributeSelector optgroup[label="Ticket Customer"] option').filter(function () { return $(this).text() === 'Last contact (agent)' }).length, 'has Ticket Customer Last contact (agent) attribute')
  assert.ok(el.find('.js-attributeSelector optgroup[label="Ticket Customer"] option').filter(function () { return $(this).text() === 'Last contact (customer)' }).length, 'has Ticket Customer Last contact (customer) attribute')
  assert.ok(el.find('.js-attributeSelector optgroup[label="Ticket Customer"] option').filter(function () { return $(this).text() === 'Updated at' }).length, 'has Ticket Customer Updated at attribute')
  assert.ok(el.find('.js-attributeSelector optgroup[label="Ticket Customer"] option').filter(function () { return $(this).text() === 'Existing tickets' }).length, 'has Ticket Customer Existing tickets attribute')
  assert.ok(el.find('.js-attributeSelector optgroup[label="Ticket Customer"] option').filter(function () { return $(this).text() === 'Existing tickets (open)' }).length, 'has Ticket Customer Existing tickets (open) attribute')
  assert.ok(el.find('.js-attributeSelector optgroup[label="Ticket Owner"] option').filter(function () { return $(this).text() === 'Existing tickets' }).length, 'has Ticket Owner Existing tickets attribute')
  assert.ok(el.find('.js-attributeSelector optgroup[label="Ticket Owner"] option').filter(function () { return $(this).text() === 'Existing tickets (open)' }).length, 'has Ticket Owner Existing tickets (open) attribute')

  assert.notOk(el.find('.js-switch input').prop('checked'), 'expert mode switch is off')
})

QUnit.test('supports organization object', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: true }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  var defaults = {
    object: 'Organization',
  }
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'object_selector' },
      ]
    },
    params: defaults,
    autofocus: true
  })
  var params = App.ControllerForm.params(el)
  var test_params = {
    condition: {
      'organization.members_existing': { // default
        operator: 'is',
        value: true,
      },
    },
  }
  assert.deepEqual(params, test_params, 'params structure')
  assert.deepEqual(el.find('.js-attributeSelector optgroup').map(function () { return $(this).attr('label') }).toArray(), ['Organization'], 'has correct groups')

  // Special attributes
  assert.ok(el.find('.js-attributeSelector optgroup[label="Organization"] option').filter(function () { return $(this).text() === 'Existing members' }).length, 'has Existing members attribute')

  assert.notOk(el.find('.js-switch input').prop('checked'), 'expert mode switch is off')
})

/*
 * Examples in this group are with expert conditions turned off.
 */
QUnit.module('form object selector - without expert conditions')

QUnit.test('defaults to ticket object', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: false }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'object_selector' },
      ]
    },
    autofocus: true
  })
  var params = App.ControllerForm.params(el)
  var test_params = {
    condition: {
      'ticket.state_id': {
        operator: 'is',
        value: [],
      },
    },
  }
  assert.deepEqual(params, test_params, 'params structure')
})

QUnit.test('supports ticket object', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: false }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  var defaults = {
    object: 'Ticket',
  }
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'object_selector' },
      ]
    },
    params: defaults,
    autofocus: true
  })
  var params = App.ControllerForm.params(el)
  var test_params = {
    condition: {
      'ticket.state_id': {
        operator: 'is',
        value: [],
      },
    },
  }
  assert.deepEqual(params, test_params, 'params structure')
  assert.deepEqual(el.find('.js-attributeSelector').find('optgroup').map(function () { return $(this).attr('label') }).toArray(), ['Ticket', 'Article', 'Customer', 'Organization'], 'has correct groups')

  assert.notOk(el.find('.js-switch input').length, 'expert mode switch is missing')
})

QUnit.test('supports user object', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: false }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  var defaults = {
    object: 'User',
  }
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'object_selector' },
      ]
    },
    params: defaults,
    autofocus: true
  })
  var params = App.ControllerForm.params(el)
  var test_params = {
    condition: {
      'user.role_ids': { // default
        operator: 'is',
        value: [],
      },
    },
  }
  assert.deepEqual(params, test_params, 'params structure')
  assert.deepEqual(el.find('.js-attributeSelector').find('optgroup').map(function () { return $(this).attr('label') }).toArray(), ['User', 'Ticket Customer', 'Ticket Owner', 'Organization'], 'has correct groups')

  // Special attributes
  assert.ok(el.find('.js-attributeSelector optgroup[label="User"] option').filter(function () { return $(this).text() === 'Role' }).length, 'has Role attribute')
  assert.ok(el.find('.js-attributeSelector optgroup[label="User"] option').filter(function () { return $(this).text() === 'Last login' }).length, 'has Last login attribute')
  assert.ok(el.find('.js-attributeSelector optgroup[label="Ticket Customer"] option').filter(function () { return $(this).text() === 'Last contact' }).length, 'has Ticket Customer Last contact attribute')
  assert.ok(el.find('.js-attributeSelector optgroup[label="Ticket Customer"] option').filter(function () { return $(this).text() === 'Last contact (agent)' }).length, 'has Ticket Customer Last contact (agent) attribute')
  assert.ok(el.find('.js-attributeSelector optgroup[label="Ticket Customer"] option').filter(function () { return $(this).text() === 'Last contact (customer)' }).length, 'has Ticket Customer Last contact (customer) attribute')
  assert.ok(el.find('.js-attributeSelector optgroup[label="Ticket Customer"] option').filter(function () { return $(this).text() === 'Updated at' }).length, 'has Ticket Customer Updated at attribute')
  assert.ok(el.find('.js-attributeSelector optgroup[label="Ticket Customer"] option').filter(function () { return $(this).text() === 'Existing tickets' }).length, 'has Ticket Customer Existing tickets attribute')
  assert.ok(el.find('.js-attributeSelector optgroup[label="Ticket Customer"] option').filter(function () { return $(this).text() === 'Existing tickets (open)' }).length, 'has Ticket Customer Existing tickets (open) attribute')
  assert.ok(el.find('.js-attributeSelector optgroup[label="Ticket Owner"] option').filter(function () { return $(this).text() === 'Existing tickets' }).length, 'has Ticket Owner Existing tickets attribute')
  assert.ok(el.find('.js-attributeSelector optgroup[label="Ticket Owner"] option').filter(function () { return $(this).text() === 'Existing tickets (open)' }).length, 'has Ticket Owner Existing tickets (open) attribute')

  assert.notOk(el.find('.js-switch input').length, 'expert mode switch is missing')
})

QUnit.test('supports organization object', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: false }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  var defaults = {
    object: 'Organization',
  }
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'object_selector' },
      ]
    },
    params: defaults,
    autofocus: true
  })
  var params = App.ControllerForm.params(el)
  var test_params = {
    condition: {
      'organization.members_existing': { // default
        operator: 'is',
        value: true,
      },
    },
  }
  assert.deepEqual(params, test_params, 'params structure')
  assert.deepEqual(el.find('.js-attributeSelector optgroup').map(function () { return $(this).attr('label') }).toArray(), ['Organization'], 'has correct groups')

  // Special attributes
  assert.ok(el.find('.js-attributeSelector optgroup[label="Organization"] option').filter(function () { return $(this).text() === 'Existing members' }).length, 'has Existing members attribute')

  assert.notOk(el.find('.js-switch input').length, 'expert mode switch is missing')
})

QUnit.test('has changed operator does not block value from showing up (#5661)', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'has_changed_show_value', value: false }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'object_selector', hasChanged: true },
      ]
    },
    autofocus: true
  })

  el.find('.js-filterElement:first-child .js-operator select').val('has changed').trigger('change')
  assert.ok(el.find('.js-filterElement:first-child .js-value select').is(':hidden'), 'value picker visible when coming from has changed operator')

  var params = App.ControllerForm.params(el)

  var test_params = {
    condition: {
      'ticket.state_id': {
        operator: 'has changed',
        value: []
      },
    },
  }
  assert.deepEqual(params, test_params, 'params structure')

  el.find('.js-filterElement:first-child .js-attributeSelector select').val('article.sender_id').trigger('change')

  var test_params = {
    condition: {
      'article.sender_id': {
        operator: 'is',
        value: []
      },
    },
  }

  var params = App.ControllerForm.params(el)
  assert.deepEqual(params, test_params, 'params structure')

  assert.equal(el.find('.js-filterElement:first-child .js-attributeSelector select option:selected').text(), 'Sender', 'article sender attribute selected')

  assert.ok(el.find('.js-filterElement:first-child .js-value select').is(':visible'), 'value picker visible when coming from has changed operator')

  assert.ok(!el.find('.js-filterElement:first-child .js-operator select').text().includes('has changed'), 'non-ticket item does not have has changed operator')
})
