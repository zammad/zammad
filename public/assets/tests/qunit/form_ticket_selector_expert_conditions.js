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
      id:   1,
      name: 'group 1',
    },
    {
      id:   2,
      name: 'group 2',
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
QUnit.module('form ticket selector - with expert conditions')

QUnit.test('renders with expert mode turned off by default', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: true }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'ticket_selector' },
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

  // Check expert mode switch.
  assert.notOk(el.find('.js-switch input').prop('checked'), 'expert mode switch is off')
})

QUnit.test('renders default selector when params are empty', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: true }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'ticket_selector', preview: false, always_expert_mode: true },
      ]
    },
    autofocus: true
  })
  var params = App.ControllerForm.params(el)
  var test_params = {
    condition: {
      operator: 'AND',
      conditions: [
        {
          name: 'ticket.state_id',
          operator: 'is',
          value: [],
        }
      ],
    },
  }
  assert.deepEqual(params, test_params, 'params structure')

  // Check subclause operator options.
  assert.equal(el.find('.js-subclauseSelector select option:selected').text(), 'Match all (AND)', 'AND operator selected (default)')
  assert.equal(el.find('.js-subclauseSelector select option:nth-child(1)').text(), 'Match all (AND)', 'AND operator selection')
  assert.equal(el.find('.js-subclauseSelector select option:nth-child(2)').text(), 'Match any (OR)', 'OR operator selection')
  assert.equal(el.find('.js-subclauseSelector select option:nth-child(3)').text(), 'Match none (NOT)', 'NOT operator selection')

  // Check ticket state options.
  assert.equal(el.find('.js-attributeSelector select option:selected').text(), 'State', 'state attribute selected')
  assert.equal(el.find('.js-operator select option:selected').text(), 'is', 'is operator selected')
  assert.equal(el.find('.js-value select option:selected').text(), '', 'no value selected')

  // Check draggable handles.
  assert.notOk(el.find('.js-filterElement:nth-child(1) .draggable').length, 'root subclause is not draggable')
  assert.ok(el.find('.js-filterElement:nth-child(2) .draggable').length, 'state filter is draggable')

  // Check filter controls.
  assert.ok(el.find('.js-filterElement:nth-child(1) .filter-controls .filter-control-remove').hasClass('is-disabled'), 'root subclause is not removable')
  assert.ok(el.find('.js-filterElement:nth-child(1) .filter-controls .js-add').length, 'root subclause supports conditions')
  assert.ok(el.find('.js-filterElement:nth-child(1) .filter-controls .js-subclause').length, 'root subclause supports subclauses')
  assert.ok(el.find('.js-filterElement:nth-child(2) .filter-controls .js-remove').hasClass('is-disabled'), 'state condition is currently not removable')
  assert.ok(el.find('.js-filterElement:nth-child(2) .filter-controls .js-add').length, 'state condition supports conditions')
  assert.ok(el.find('.js-filterElement:nth-child(2) .filter-controls .js-subclause').length, 'state condition supports subclauses')

  // Check expert mode switch.
  assert.ok(el.find('.js-switch input').prop('checked'), 'expert mode switch is on')
})

QUnit.test('renders selector based on passed params', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: true }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  var defaults = {
    condition: {
      operator: 'AND',
      conditions: [
        {
          name: 'ticket.number',
          operator: 'contains',
          value: 'foo',
        },
        {
          operator: 'OR',
          conditions: [
            {
              name: 'ticket.priority_id',
              operator: 'is',
              value: ['1', '2'],
            },
            {
              name: 'ticket.title',
              operator: 'contains not',
              value: 'bar',
            },
          ],
        },
      ],
    },
  }
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'ticket_selector', preview: false, always_expert_mode: true },
      ],
    },
    params: clone(defaults),
    autofocus: true,
  })
  var params = App.ControllerForm.params(el)
  assert.deepEqual(params, defaults, 'params structure')

  // Check subclause operator options.
  assert.equal(el.find('.js-filterElement:nth-child(1) .js-subclauseSelector select option:selected').text(), 'Match all (AND)', 'AND operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(3) .js-subclauseSelector select option:selected').text(), 'Match any (OR)', 'OR operator selected')

  // Check ticket number options.
  assert.equal(el.find('.js-filterElement:nth-child(2) .js-attributeSelector select option:selected').text(), '#', 'ticket number attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(2) .js-operator select option:selected').text(), 'contains', 'contains operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(2) .js-value input').val(), 'foo', 'foo input value')

  // Check ticket priority options.
  assert.equal(el.find('.js-filterElement:nth-child(4) .js-attributeSelector select option:selected').text(), 'Priority', 'priority attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(4) .js-operator select option:selected').text(), 'is', 'is operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(4) .js-value select option:selected:nth-child(1)').text(), '1 low', '1 low value selected')
  assert.equal(el.find('.js-filterElement:nth-child(4) .js-value select option:selected:nth-child(2)').text(), '2 normal', '2 normal value selected')

  // Check ticket title options.
  assert.equal(el.find('.js-filterElement:nth-child(5) .js-attributeSelector select option:selected').text(), 'Title', 'title attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(5) .js-operator select option:selected').text(), 'contains not', 'contains not attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(5) .js-value input').val(), 'bar', 'bar input value')

  // Check draggable handles.
  assert.notOk(el.find('.js-filterElement:nth-child(1) .draggable').length, 'root subclause is not draggable')
  assert.ok(el.find('.js-filterElement:nth-child(n+2) .draggable').length, 'all other conditions are draggable')

  // Check filter controls.
  assert.ok(el.find('.js-filterElement:nth-child(1) .filter-controls .filter-control-remove').hasClass('is-disabled'), 'root subclause is not removable')
  assert.ok(el.find('.js-filterElement:nth-child(1) .filter-controls .js-add').length, 'root subclause supports conditions')
  assert.ok(el.find('.js-filterElement:nth-child(1) .filter-controls .js-subclause').length, 'root subclause supports subclauses')
  assert.notOk(el.find('.js-filterElement:nth-child(2) .filter-controls .js-remove').hasClass('is-disabled'), 'number condition is currently removable')
  assert.ok(el.find('.js-filterElement:nth-child(2) .filter-controls .js-add').length, 'number condition supports conditions')
  assert.ok(el.find('.js-filterElement:nth-child(2) .filter-controls .js-subclause').length, 'number condition supports subclauses')
  assert.notOk(el.find('.js-filterElement:nth-child(3) .filter-controls .js-remove').hasClass('is-disabled'), 'second subclause is currently removable')
  assert.ok(el.find('.js-filterElement:nth-child(3) .filter-controls .js-add').length, 'second subclause supports conditions')
  assert.ok(el.find('.js-filterElement:nth-child(3) .filter-controls .js-subclause').length, 'second subclause supports subclauses')
  assert.notOk(el.find('.js-filterElement:nth-child(4) .filter-controls .js-remove').hasClass('is-disabled'), 'priority condition is currently removable')
  assert.ok(el.find('.js-filterElement:nth-child(4) .filter-controls .js-add').length, 'priority condition supports conditions')
  assert.ok(el.find('.js-filterElement:nth-child(4) .filter-controls .js-subclause').length, 'priority condition supports subclauses')
  assert.notOk(el.find('.js-filterElement:nth-child(5) .filter-controls .js-remove').hasClass('is-disabled'), 'title condition is currently removable')
  assert.ok(el.find('.js-filterElement:nth-child(5) .filter-controls .js-add').length, 'title condition supports conditions')
  assert.ok(el.find('.js-filterElement:nth-child(5) .filter-controls .js-subclause').length, 'title condition supports subclauses')
})

QUnit.test('renders additional attributes correctly', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: true }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  var defaults = {
    condition: {
      operator: 'OR',
      conditions: [
        {
          name: 'ticket.customer_id',
          operator: 'is',
          pre_condition: 'current_user.id',
          value: [],
        },
        {
          name: 'ticket.customer_id',
          operator: 'is not',
          pre_condition: 'specific',
          value: ['47'],
        },
        {
          name: 'ticket.customer_id',
          operator: 'is',
          pre_condition: 'not_set',
          value: [],
        },
        {
          name: 'ticket.organization_id',
          operator: 'is',
          pre_condition: 'current_user.organization_id',
          value: [],
        },
        {
          name: 'ticket.organization_id',
          operator: 'is not',
          pre_condition: 'specific',
          value: ['12'],
        },
        {
          name: 'ticket.organization_id',
          operator: 'is',
          pre_condition: 'not_set',
          value: [],
        },
        {
          name: 'ticket.type',
          operator: 'is',
          value: [
            'Incident',
            'Problem',
          ],
        },
        {
          name: 'ticket.group_id',
          operator: 'is',
          value: ['1'],
        },
        {
          name: 'ticket.owner_id',
          operator: 'is',
          pre_condition: 'current_user.id',
          value: [],
        },
        {
          name: 'ticket.owner_id',
          operator: 'is not',
          pre_condition: 'specific',
          value: ['47'],
        },
        {
          name: 'ticket.pending_time',
          operator: 'today',
        },
        {
          name: 'ticket.pending_time',
          operator: 'before (absolute)',
          value: '2022-11-15T08:00:00.000Z',
        },
        {
          name: 'ticket.pending_time',
          operator: 'after (absolute)',
          value: '2022-11-16T08:00:00.000Z',
        },
        {
          name: 'ticket.pending_time',
          operator: 'before (relative)',
          value: '3',
          range: 'minute',
        },
        {
          name: 'ticket.pending_time',
          operator: 'after (relative)',
          value: '5',
          range: 'hour',
        },
        {
          name: 'ticket.pending_time',
          operator: 'within next (relative)',
          value: '7',
          range: 'day',
        },
        {
          name: 'ticket.pending_time',
          operator: 'within last (relative)',
          value: '9',
          range: 'week',
        },
        {
          name: 'ticket.pending_time',
          operator: 'till (relative)',
          value: '12',
          range: 'month',
        },
        {
          name: 'ticket.pending_time',
          operator: 'from (relative)',
          value: '15',
          range: 'year',
        },
        {
          name: 'ticket.tags',
          operator: 'contains all',
          value: 'tag 1, tag 2',
        },
        {
          name: 'ticket.tags',
          operator: 'contains one',
          value: 'tag 1',
        },
        {
          name: 'ticket.tags',
          operator: 'contains all not',
          value: 'tag 3, tag 4',
        },
        {
          name: 'ticket.tags',
          operator: 'contains one not',
          value: 'tag 3',
        },
        {
          name: 'ticket.test_text',
          operator: 'contains',
          value: 'foo',
        },
        {
          name: 'ticket.test_text',
          operator: 'contains not',
          value: 'bar',
        },
        {
          name: 'ticket.test_textarea',
          operator: 'contains',
          value: 'foo',
        },
        {
          name: 'ticket.test_textarea',
          operator: 'contains not',
          value: 'bar',
        },
        {
          name: 'ticket.test_integer',
          operator: 'is',
          value: '42',
        },
        {
          name: 'ticket.test_integer',
          operator: 'is not',
          value: '999',
        },
        {
          name: 'ticket.test_date',
          operator: 'today',
        },
        {
          name: 'ticket.test_date',
          operator: 'before (absolute)',
          value: '2022-11-15T08:00:00.000Z',
        },
        {
          name: 'ticket.test_date',
          operator: 'after (absolute)',
          value: '2022-11-16T08:00:00.000Z',
        },
        {
          name: 'ticket.test_date',
          operator: 'before (relative)',
          value: '3',
          range: 'minute',
        },
        {
          name: 'ticket.test_date',
          operator: 'after (relative)',
          value: '5',
          range: 'hour',
        },
        {
          name: 'ticket.test_date',
          operator: 'within next (relative)',
          value: '7',
          range: 'day',
        },
        {
          name: 'ticket.test_date',
          operator: 'within last (relative)',
          value: '9',
          range: 'week',
        },
        {
          name: 'ticket.test_datetime',
          operator: 'today',
        },
        {
          name: 'ticket.test_datetime',
          operator: 'before (absolute)',
          value: '2022-11-15T08:00:00.000Z',
        },
        {
          name: 'ticket.test_datetime',
          operator: 'after (absolute)',
          value: '2022-11-16T08:00:00.000Z',
        },
        {
          name: 'ticket.test_datetime',
          operator: 'before (relative)',
          value: '3',
          range: 'minute',
        },
        {
          name: 'ticket.test_datetime',
          operator: 'after (relative)',
          value: '5',
          range: 'hour',
        },
        {
          name: 'ticket.test_datetime',
          operator: 'within next (relative)',
          value: '7',
          range: 'day',
        },
        {
          name: 'ticket.test_datetime',
          operator: 'within last (relative)',
          value: '9',
          range: 'week',
        },
        {
          name: 'ticket.test_datetime',
          operator: 'till (relative)',
          value: '12',
          range: 'month',
        },
        {
          name: 'ticket.test_datetime',
          operator: 'from (relative)',
          value: '15',
          range: 'year',
        },
        {
          name: 'ticket.test_select',
          operator: 'is',
          value: ['a', 'b'],
        },
        {
          name: 'ticket.test_select',
          operator: 'is not',
          value: ['c'],
        },
        {
          name: 'ticket.test_multiselect',
          operator: 'contains all',
          value: ['a', 'b'],
        },
        {
          name: 'ticket.test_multiselect',
          operator: 'contains one',
          value: ['c'],
        },
        {
          name: 'ticket.test_multiselect',
          operator: 'contains all not',
          value: ['b', 'c'],
        },
        {
          name: 'ticket.test_multiselect',
          operator: 'contains one not',
          value: ['a'],
        },
        {
          name: 'ticket.test_tree_select',
          operator: 'is',
          value: ['a', 'a::b'],
        },
        {
          name: 'ticket.test_tree_select',
          operator: 'is not',
          value: ['a::b::c'],
        },
        {
          name: 'ticket.test_multi_tree_select',
          operator: 'contains all',
          value: ['a', 'a::b'],
        },
        {
          name: 'ticket.test_multi_tree_select',
          operator: 'contains one',
          value: ['a::b::c'],
        },
        {
          name: 'ticket.test_multi_tree_select',
          operator: 'contains all not',
          value: ['a::b', 'a::b::c'],
        },
        {
          name: 'ticket.test_multi_tree_select',
          operator: 'contains one not',
          value: ['a'],
        },
        {
          name: 'customer.vip',
          operator: 'is',
          value: 'false',
        },
        {
          name: 'customer.vip',
          operator: 'is not',
          value: 'true',
        },
      ],
    },
  }
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'ticket_selector', preview: false, always_expert_mode: true },
      ],
    },
    params: clone(defaults),
    autofocus: true,
  })
  var params = App.ControllerForm.params(el)
  var test_params = {
    _completion: Array(14).fill(''),
    ...defaults,
  }
  assert.deepEqual(params, test_params, 'params structure')

  // Check ticket customer options.
  assert.equal(el.find('.js-filterElement:nth-child(2) .js-attributeSelector select option:selected').text(), 'Customer', 'customer attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(2) .js-operator select option:selected').text(), 'is', 'is operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(2) .js-preCondition select option:selected').text(), 'current user', 'current user pre-condition selected')
  assert.equal(el.find('.js-filterElement:nth-child(3) .js-attributeSelector select option:selected').text(), 'Customer', 'customer attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(3) .js-operator select option:selected').text(), 'is not', 'is not operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(3) .js-preCondition select option:selected').text(), 'specific user', 'specific user pre-condition selected')
  assert.equal(el.find('.js-filterElement:nth-child(3) .js-objectId option:selected').text(), 'Bob Smith', 'Bob Smith input value')
  assert.equal(el.find('.js-filterElement:nth-child(4) .js-attributeSelector select option:selected').text(), 'Customer', 'customer attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(4) .js-operator select option:selected').text(), 'is', 'is operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(4) .js-preCondition select option:selected').text(), 'not set (not defined)', 'not defined pre-condition selected')

  // Check ticket organization options.
  assert.equal(el.find('.js-filterElement:nth-child(5) .js-attributeSelector select option:selected').text(), 'Organization', 'organization attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(5) .js-operator select option:selected').text(), 'is', 'is operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(5) .js-preCondition select option:selected').text(), 'current user organization', 'current user organization pre-condition selected')
  assert.equal(el.find('.js-filterElement:nth-child(6) .js-attributeSelector select option:selected').text(), 'Organization', 'organization attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(6) .js-operator select option:selected').text(), 'is not', 'is not operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(6) .js-preCondition select option:selected').text(), 'specific organization', 'specific organization pre-condition selected')
  assert.equal(el.find('.js-filterElement:nth-child(6) .js-shadow option:selected').text(), 'Org 1', 'Org 1 input value')
  assert.equal(el.find('.js-filterElement:nth-child(7) .js-attributeSelector select option:selected').text(), 'Organization', 'organization attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(7) .js-operator select option:selected').text(), 'is', 'is operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(7) .js-preCondition select option:selected').text(), 'not set (not defined)', 'not defined pre-condition selected')

  // Check ticket type options.
  assert.equal(el.find('.js-filterElement:nth-child(8) .js-attributeSelector select option:selected').text(), 'Type', 'type attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(8) .js-operator select option:selected').text(), 'is', 'is operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(8) .js-value select option:selected:nth-child(1)').text(), 'Incident', 'Incident value selected')
  assert.equal(el.find('.js-filterElement:nth-child(8) .js-value select option:selected:nth-child(2)').text(), 'Problem', 'Problem value selected')

  // Check ticket group options.
  assert.equal(el.find('.js-filterElement:nth-child(9) .js-attributeSelector select option:selected').text(), 'Group', 'group attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(9) .js-operator select option:selected').text(), 'is', 'is operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(9) .js-value select option:selected').text(), 'group 1', 'group 1 value selected')

  // Check ticket owner options.
  assert.equal(el.find('.js-filterElement:nth-child(10) .js-attributeSelector select option:selected').text(), 'Owner', 'owner attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(10) .js-operator select option:selected').text(), 'is', 'is operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(10) .js-preCondition select option:selected').text(), 'current user', 'current user pre-condition selected')
  assert.equal(el.find('.js-filterElement:nth-child(11) .js-attributeSelector select option:selected').text(), 'Owner', 'owner attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(11) .js-operator select option:selected').text(), 'is not', 'is not operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(11) .js-preCondition select option:selected').text(), 'specific user', 'specific user pre-condition selected')
  assert.equal(el.find('.js-filterElement:nth-child(11) .js-objectId option:selected').text(), 'Bob Smith', 'Bob Smith input value')

  // Check pending till options.
  assert.equal(el.find('.js-filterElement:nth-child(12) .js-attributeSelector select option:selected').text(), 'Pending till', 'pending till attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(12) .js-operator select option:selected').text(), 'today', 'today operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(13) .js-attributeSelector select option:selected').text(), 'Pending till', 'pending till attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(13) .js-operator select option:selected').text(), 'before (absolute)', 'before (absolute) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(13) .js-value input.js-datepicker').val(), '11/15/2022', '11/15/2022 input value')
  assert.equal(el.find('.js-filterElement:nth-child(13) .js-value input.js-timepicker').val(), '08:00', '08:00 input value')
  assert.equal(el.find('.js-filterElement:nth-child(14) .js-attributeSelector select option:selected').text(), 'Pending till', 'pending till attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(14) .js-operator select option:selected').text(), 'after (absolute)', 'after (absolute) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(14) .js-value input.js-datepicker').val(), '11/16/2022', '11/16/2022 input value')
  assert.equal(el.find('.js-filterElement:nth-child(14) .js-value input.js-timepicker').val(), '08:00', '08:00 input value')
  assert.equal(el.find('.js-filterElement:nth-child(15) .js-attributeSelector select option:selected').text(), 'Pending till', 'pending till attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(15) .js-operator select option:selected').text(), 'before (relative)', 'before (relative) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(15) select.js-value option:selected').text(), '3', '3 value selected')
  assert.equal(el.find('.js-filterElement:nth-child(15) select.js-range option:selected').text(), 'Minute(s)', 'Minute(s) value selected')
  assert.equal(el.find('.js-filterElement:nth-child(16) .js-attributeSelector select option:selected').text(), 'Pending till', 'pending till attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(16) .js-operator select option:selected').text(), 'after (relative)', 'after (relative) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(16) select.js-value option:selected').text(), '5', '4 value selected')
  assert.equal(el.find('.js-filterElement:nth-child(16) select.js-range option:selected').text(), 'Hour(s)', 'Hour(s) value selected')
  assert.equal(el.find('.js-filterElement:nth-child(17) .js-attributeSelector select option:selected').text(), 'Pending till', 'pending till attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(17) .js-operator select option:selected').text(), 'within next (relative)', 'within next (relative) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(17) select.js-value option:selected').text(), '7', '7 value selected')
  assert.equal(el.find('.js-filterElement:nth-child(17) select.js-range option:selected').text(), 'Day(s)', 'Day(s) value selected')
  assert.equal(el.find('.js-filterElement:nth-child(18) .js-attributeSelector select option:selected').text(), 'Pending till', 'pending till attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(18) .js-operator select option:selected').text(), 'within last (relative)', 'within last (relative) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(18) select.js-value option:selected').text(), '9', '9 value selected')
  assert.equal(el.find('.js-filterElement:nth-child(18) select.js-range option:selected').text(), 'Week(s)', 'Week(s) value selected')
  assert.equal(el.find('.js-filterElement:nth-child(19) .js-attributeSelector select option:selected').text(), 'Pending till', 'pending till attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(19) .js-operator select option:selected').text(), 'till (relative)', 'till (relative) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(19) select.js-value option:selected').text(), '12', '12 value selected')
  assert.equal(el.find('.js-filterElement:nth-child(19) select.js-range option:selected').text(), 'Month(s)', 'Month(s) value selected')
  assert.equal(el.find('.js-filterElement:nth-child(20) .js-attributeSelector select option:selected').text(), 'Pending till', 'pending till attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(20) .js-operator select option:selected').text(), 'from (relative)', 'from (relative) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(20) select.js-value option:selected').text(), '15', '15 value selected')
  assert.equal(el.find('.js-filterElement:nth-child(20) select.js-range option:selected').text(), 'Year(s)', 'Year(s) value selected')

  // Check ticket tag options.
  assert.equal(el.find('.js-filterElement:nth-child(21) .js-attributeSelector select option:selected').text(), 'Tags', 'tags attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(21) .js-operator select option:selected').text(), 'contains all', 'contains all operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(21) .js-value input.form-control').val(), 'tag 1, tag 2', 'tag 1, tag 2 input value')
  assert.equal(el.find('.js-filterElement:nth-child(22) .js-attributeSelector select option:selected').text(), 'Tags', 'tags attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(22) .js-operator select option:selected').text(), 'contains one', 'contains one operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(22) .js-value input.form-control').val(), 'tag 1', 'tag 1 input value')
  assert.equal(el.find('.js-filterElement:nth-child(23) .js-attributeSelector select option:selected').text(), 'Tags', 'tags attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(23) .js-operator select option:selected').text(), 'contains all not', 'contains all not operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(23) .js-value input.form-control').val(), 'tag 3, tag 4', 'tag 3, tag 4 input value')
  assert.equal(el.find('.js-filterElement:nth-child(24) .js-attributeSelector select option:selected').text(), 'Tags', 'tags attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(24) .js-operator select option:selected').text(), 'contains one not', 'contains one not operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(24) .js-value input.form-control').val(), 'tag 3', 'tag 3 input value')

  // Check custom text attribute options.
  assert.equal(el.find('.js-filterElement:nth-child(25) .js-attributeSelector select option:selected').text(), 'test_text', 'test_text attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(25) .js-operator select option:selected').text(), 'contains', 'contains operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(25) .js-value input').val(), 'foo', 'foo input value')
  assert.equal(el.find('.js-filterElement:nth-child(26) .js-attributeSelector select option:selected').text(), 'test_text', 'test_text attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(26) .js-operator select option:selected').text(), 'contains not', 'contains not operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(26) .js-value input').val(), 'bar', 'bar input value')

  // Check custom textarea attribute options.
  assert.equal(el.find('.js-filterElement:nth-child(27) .js-attributeSelector select option:selected').text(), 'test_textarea', 'test_textarea attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(27) .js-operator select option:selected').text(), 'contains', 'contains operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(27) .js-value textarea').val(), 'foo', 'foo input value')
  assert.equal(el.find('.js-filterElement:nth-child(28) .js-attributeSelector select option:selected').text(), 'test_textarea', 'test_textarea attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(28) .js-operator select option:selected').text(), 'contains not', 'contains not operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(28) .js-value textarea').val(), 'bar', 'bar input value')

  // Check custom integer attribute options.
  assert.equal(el.find('.js-filterElement:nth-child(29) .js-attributeSelector select option:selected').text(), 'test_integer', 'test_integer attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(29) .js-operator select option:selected').text(), 'is', 'is operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(29) .js-value input').val(), '42', '42 input value')
  assert.equal(el.find('.js-filterElement:nth-child(30) .js-attributeSelector select option:selected').text(), 'test_integer', 'test_integer attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(30) .js-operator select option:selected').text(), 'is not', 'is not operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(30) .js-value input').val(), '999', '999 input value')

  // Check custom date attribute options.
  assert.equal(el.find('.js-filterElement:nth-child(31) .js-attributeSelector select option:selected').text(), 'test_date', 'test_date attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(31) .js-operator select option:selected').text(), 'today', 'today operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(32) .js-attributeSelector select option:selected').text(), 'test_date', 'test_date attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(32) .js-operator select option:selected').text(), 'before (absolute)', 'before (absolute) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(32) .js-value input.js-datepicker').val(), '11/15/2022', '11/15/2022 input value')
  assert.equal(el.find('.js-filterElement:nth-child(33) .js-attributeSelector select option:selected').text(), 'test_date', 'test_date attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(33) .js-operator select option:selected').text(), 'after (absolute)', 'after (absolute) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(33) .js-value input.js-datepicker').val(), '11/16/2022', '11/16/2022 input value')
  assert.equal(el.find('.js-filterElement:nth-child(34) .js-attributeSelector select option:selected').text(), 'test_date', 'test_date attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(34) .js-operator select option:selected').text(), 'before (relative)', 'before (relative) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(34) select.js-value option:selected').text(), '3', '3 value selected')
  assert.equal(el.find('.js-filterElement:nth-child(34) select.js-range option:selected').text(), 'Minute(s)', 'Minute(s) value selected')
  assert.equal(el.find('.js-filterElement:nth-child(35) .js-attributeSelector select option:selected').text(), 'test_date', 'test_date attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(35) .js-operator select option:selected').text(), 'after (relative)', 'after (relative) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(35) select.js-value option:selected').text(), '5', '5 value selected')
  assert.equal(el.find('.js-filterElement:nth-child(35) select.js-range option:selected').text(), 'Hour(s)', 'Hour(s) value selected')
  assert.equal(el.find('.js-filterElement:nth-child(36) .js-attributeSelector select option:selected').text(), 'test_date', 'test_date attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(36) .js-operator select option:selected').text(), 'within next (relative)', 'within next (relative) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(36) select.js-value option:selected').text(), '7', '7 value selected')
  assert.equal(el.find('.js-filterElement:nth-child(36) select.js-range option:selected').text(), 'Day(s)', 'Day(s) value selected')
  assert.equal(el.find('.js-filterElement:nth-child(37) .js-attributeSelector select option:selected').text(), 'test_date', 'test_date attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(37) .js-operator select option:selected').text(), 'within last (relative)', 'within last (relative) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(37) select.js-value option:selected').text(), '9', '9 value selected')
  assert.equal(el.find('.js-filterElement:nth-child(37) select.js-range option:selected').text(), 'Week(s)', 'Week(s) value selected')

  // Check custom datetime attribute options.
  assert.equal(el.find('.js-filterElement:nth-child(38) .js-attributeSelector select option:selected').text(), 'test_datetime', 'test_datetime attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(38) .js-operator select option:selected').text(), 'today', 'today operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(39) .js-attributeSelector select option:selected').text(), 'test_datetime', 'test_datetime attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(39) .js-operator select option:selected').text(), 'before (absolute)', 'before (absolute) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(39) .js-value input.js-datepicker').val(), '11/15/2022', '11/15/2022 input value')
  assert.equal(el.find('.js-filterElement:nth-child(39) .js-value input.js-timepicker').val(), '08:00', '08:00 input value')
  assert.equal(el.find('.js-filterElement:nth-child(40) .js-attributeSelector select option:selected').text(), 'test_datetime', 'test_datetime attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(40) .js-operator select option:selected').text(), 'after (absolute)', 'after (absolute) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(40) .js-value input.js-datepicker').val(), '11/16/2022', '11/16/2022 input value')
  assert.equal(el.find('.js-filterElement:nth-child(40) .js-value input.js-timepicker').val(), '08:00', '08:00 input value')
  assert.equal(el.find('.js-filterElement:nth-child(41) .js-attributeSelector select option:selected').text(), 'test_datetime', 'test_datetime attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(41) .js-operator select option:selected').text(), 'before (relative)', 'before (relative) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(41) select.js-value option:selected').text(), '3', '3 value selected')
  assert.equal(el.find('.js-filterElement:nth-child(41) select.js-range option:selected').text(), 'Minute(s)', 'Minute(s) value selected')
  assert.equal(el.find('.js-filterElement:nth-child(42) .js-attributeSelector select option:selected').text(), 'test_datetime', 'test_datetime attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(42) .js-operator select option:selected').text(), 'after (relative)', 'after (relative) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(42) select.js-value option:selected').text(), '5', '5 value selected')
  assert.equal(el.find('.js-filterElement:nth-child(42) select.js-range option:selected').text(), 'Hour(s)', 'Hour(s) value selected')
  assert.equal(el.find('.js-filterElement:nth-child(43) .js-attributeSelector select option:selected').text(), 'test_datetime', 'test_datetime attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(43) .js-operator select option:selected').text(), 'within next (relative)', 'within next (relative) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(43) select.js-value option:selected').text(), '7', '7 value selected')
  assert.equal(el.find('.js-filterElement:nth-child(43) select.js-range option:selected').text(), 'Day(s)', 'Day(s) value selected')
  assert.equal(el.find('.js-filterElement:nth-child(44) .js-attributeSelector select option:selected').text(), 'test_datetime', 'test_datetime attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(44) .js-operator select option:selected').text(), 'within last (relative)', 'within last (relative) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(44) select.js-value option:selected').text(), '9', '8 value selected')
  assert.equal(el.find('.js-filterElement:nth-child(44) select.js-range option:selected').text(), 'Week(s)', 'Week(s) value selected')
  assert.equal(el.find('.js-filterElement:nth-child(45) .js-attributeSelector select option:selected').text(), 'test_datetime', 'test_datetime attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(45) .js-operator select option:selected').text(), 'till (relative)', 'till (relative) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(45) select.js-value option:selected').text(), '12', '12 value selected')
  assert.equal(el.find('.js-filterElement:nth-child(45) select.js-range option:selected').text(), 'Month(s)', 'Month(s) value selected')
  assert.equal(el.find('.js-filterElement:nth-child(46) .js-attributeSelector select option:selected').text(), 'test_datetime', 'test_datetime attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(46) .js-operator select option:selected').text(), 'from (relative)', 'from (relative) operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(46) select.js-value option:selected').text(), '15', '15 value selected')
  assert.equal(el.find('.js-filterElement:nth-child(46) select.js-range option:selected').text(), 'Year(s)', 'Year(s) value selected')

  // Check custom select attribute options.
  assert.equal(el.find('.js-filterElement:nth-child(47) .js-attributeSelector select option:selected').text(), 'test_select', 'test_select attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(47) .js-operator select option:selected').text(), 'is', 'is operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(47) .js-value select option:selected:nth-child(1)').text(), 'A', 'A value selected')
  assert.equal(el.find('.js-filterElement:nth-child(47) .js-value select option:selected:nth-child(2)').text(), 'B', 'B value selected')
  assert.equal(el.find('.js-filterElement:nth-child(48) .js-attributeSelector select option:selected').text(), 'test_select', 'test_select attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(48) .js-operator select option:selected').text(), 'is not', 'is not operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(48) .js-value select option:selected').text(), 'C', 'C value selected')

  // Check custom multiselect attribute options.
  assert.equal(el.find('.js-filterElement:nth-child(49) .js-attributeSelector select option:selected').text(), 'test_multiselect', 'test_multiselect attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(49) .js-operator select option:selected').text(), 'contains all', 'contains all operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(49) .js-value select option:selected:nth-child(1)').text(), 'A', 'A value selected')
  assert.equal(el.find('.js-filterElement:nth-child(49) .js-value select option:selected:nth-child(2)').text(), 'B', 'B value selected')
  assert.equal(el.find('.js-filterElement:nth-child(50) .js-attributeSelector select option:selected').text(), 'test_multiselect'), 'test_multiselect attribute selected'
  assert.equal(el.find('.js-filterElement:nth-child(50) .js-operator select option:selected').text(), 'contains one', 'contains one operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(50) .js-value select option:selected').text(), 'C', 'C value selected')
  assert.equal(el.find('.js-filterElement:nth-child(51) .js-attributeSelector select option:selected').text(), 'test_multiselect', 'test_multiselect attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(51) .js-operator select option:selected').text(), 'contains all not', 'contains all not operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(51) .js-value select option:selected:nth-child(2)').text(), 'B', 'B value selected')
  assert.equal(el.find('.js-filterElement:nth-child(51) .js-value select option:selected:nth-child(3)').text(), 'C', 'B value selected')
  assert.equal(el.find('.js-filterElement:nth-child(52) .js-attributeSelector select option:selected').text(), 'test_multiselect', 'test_multiselect attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(52) .js-operator select option:selected').text(), 'contains one not', 'contains one not operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(52) .js-value select option:selected').text(), 'A', 'A value selected')

  // Check custom tree select attribute options.
  assert.equal(el.find('.js-filterElement:nth-child(53) .js-attributeSelector select option:selected').text(), 'test_tree_select', 'test_tree_select attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(53) .js-operator select option:selected').text(), 'is', 'is operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(53) .js-value select option:selected:nth-child(1)').text(), 'a', 'a value selected')
  assert.equal(el.find('.js-filterElement:nth-child(53) .js-value select option:selected:nth-child(2)').text(), 'a::b', 'a::b value selected')
  assert.equal(el.find('.js-filterElement:nth-child(54) .js-attributeSelector select option:selected').text(), 'test_tree_select', 'test_tree_select attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(54) .js-operator select option:selected').text(), 'is not', 'is not operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(54) .js-value select option:selected').text(), 'a::b::c', 'a::b::c value selected')

  // Check custom multiselect attribute options.
  assert.equal(el.find('.js-filterElement:nth-child(55) .js-attributeSelector select option:selected').text(), 'test_multi_tree_select', 'test_multi_tree_select attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(55) .js-operator select option:selected').text(), 'contains all', 'contains all operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(55) .js-value select option:selected:nth-child(1)').text(), 'a', 'a value selected')
  assert.equal(el.find('.js-filterElement:nth-child(55) .js-value select option:selected:nth-child(2)').text(), 'a::b', 'a::b value selected')
  assert.equal(el.find('.js-filterElement:nth-child(56) .js-attributeSelector select option:selected').text(), 'test_multi_tree_select', 'test_multi_tree_select attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(56) .js-operator select option:selected').text(), 'contains one', 'contains one operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(56) .js-value select option:selected').text(), 'a::b::c', 'a::b::c value selected')
  assert.equal(el.find('.js-filterElement:nth-child(57) .js-attributeSelector select option:selected').text(), 'test_multi_tree_select', 'test_multi_tree_select attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(57) .js-operator select option:selected').text(), 'contains all not', 'contains all not operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(57) .js-value select option:selected:nth-child(1)').text(), 'a::b', 'a::b value selected')
  assert.equal(el.find('.js-filterElement:nth-child(57) .js-value select option:selected:nth-child(2)').text(), 'a::b::c', 'a::b::c value selected')
  assert.equal(el.find('.js-filterElement:nth-child(58) .js-attributeSelector select option:selected').text(), 'test_multi_tree_select', 'test_multi_tree_select attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(58) .js-operator select option:selected').text(), 'contains one not', 'contains one not operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(58) .js-value select option:selected').text(), 'a', 'a value selected')

  // Check customer VIP flag options (boolean).
  assert.equal(el.find('.js-filterElement:nth-child(59) .js-attributeSelector select option:selected').text(), 'VIP', 'vip attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(59) .js-operator select option:selected').text(), 'is', 'is operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(59) .js-value select option:selected').text(), 'no', 'no value selected')
  assert.equal(el.find('.js-filterElement:nth-child(60) .js-attributeSelector select option:selected').text(), 'VIP', 'vip attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(60) .js-operator select option:selected').text(), 'is not', 'is not operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(60) .js-value select option:selected').text(), 'yes', 'yes value selected')
})

QUnit.test('supports advanced features', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: true }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  var defaults = {
    condition: {
      operator: 'NOT',
      conditions: [
        {
          name: 'ticket.action',
          operator: 'is not',
          value: 'update',
        },
        {
          name: 'ticket.title',
          operator: 'has changed',
        },
        {
          name: 'execution_time.calendar_id',
          operator: 'is not in working time',
          value: '1',
        },
        {
          name: 'ticket.out_of_office_replacement_id',
          operator: 'is',
          pre_condition: 'current_user.id',
          value: [],
        },
      ],
    },
  }
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'ticket_selector', action: true, hasChanged: true, executionTime: true, out_of_office: true, preview: false, always_expert_mode: true },
      ],
    },
    params: clone(defaults),
    autofocus: true,
  })
  var params = App.ControllerForm.params(el)
  var test_params = {
    _completion: '',
    ...defaults,
  }
  assert.deepEqual(params, test_params, 'params structure')

  // Check ticket action options.
  assert.equal(el.find('.js-filterElement:nth-child(2) .js-attributeSelector select option:selected').text(), 'Action', 'action attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(2) .js-operator select option:selected').text(), 'is not', 'is not operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(2) .js-value select option:selected').text(), 'updated', 'updated value selected')

  // Check ticket title options.
  assert.equal(el.find('.js-filterElement:nth-child(3) .js-attributeSelector select option:selected').text(), 'Title', 'title attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(3) .js-operator select option:selected').text(), 'has changed', 'has changed operator selected')

  // Check execution time calendar options.
  assert.equal(el.find('.js-filterElement:nth-child(4) .js-attributeSelector select option:selected').text(), 'Calendar', 'calendar attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(4) .js-operator select option:selected').text(), 'is not in working time', 'is not in working time operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(4) .js-value select option:selected').text(), 'United Kingdom - Europe/London', 'United Kingdom - Europe/London value selected')

  // Check ticket out of office options.
  assert.equal(el.find('.js-filterElement:nth-child(5) .js-attributeSelector select option:selected').text(), 'Out of office replacement', 'ooo attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(5) .js-operator select option:selected').text(), 'is', 'is operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(5) .js-preCondition select option:selected').text(), 'current user', 'current user pre-condition selected')
})

QUnit.test('supports migration of the outdated param structure', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: true }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  var defaults = {
    condition: {
      'ticket.title': {
        operator: 'contains',
        value: 'foo',
      },
    },
  }
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'ticket_selector', preview: false, always_expert_mode: true },
      ]
    },
    params: defaults,
    autofocus: true
  })
  var params = App.ControllerForm.params(el)
  var test_params = {
    condition: {
      operator: 'AND',
      conditions: [
        {
          name: 'ticket.title',
          operator: 'contains',
          value: 'foo',
        },
      ],
    },
  }
  assert.deepEqual(params, test_params, 'params structure')
})

QUnit.test('supports maximum nested level', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: true }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  var defaults = {
    condition: {
      operator: 'OR',
      conditions: [
        {
          name: 'ticket.title',
          operator: 'contains',
          value: 'foo',
        },
        {
          operator: 'AND',
          conditions: [
            {
              operator: 'AND',
              conditions: [
                {
                  name: 'ticket.number',
                  operator: 'contains',
                  value: '123',
                },
              ],
            },
            {
              name: 'ticket.state_id',
              operator: 'is',
              value: ['1'],
            }
          ],
        }
      ],
    },
  }
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'ticket_selector', preview: false, always_expert_mode: true },
      ]
    },
    params: defaults,
    autofocus: true
  })

  // Check the disable state of subclause buttons.
  assert.notOk(el.find('.js-filterElement:nth-child(1) .filter-controls .js-subclause').hasClass('is-disabled'), 'root subclause supports subclauses')
  assert.notOk(el.find('.js-filterElement:nth-child(2) .filter-controls .js-subclause').hasClass('is-disabled'), 'title condition supports subclauses')
  assert.notOk(el.find('.js-filterElement:nth-child(3) .filter-controls .js-subclause').hasClass('is-disabled'), 'first level subclause supports subclauses')
  assert.ok(el.find('.js-filterElement:nth-child(4) .filter-controls .js-subclause').hasClass('is-disabled'), 'second level subclause does not support subclauses')
  assert.ok(el.find('.js-filterElement:nth-child(5) .filter-controls .js-subclause').hasClass('is-disabled'), 'third level condition does not support subclauses')
  assert.notOk(el.find('.js-filterElement:nth-child(6) .filter-controls .js-subclause').hasClass('is-disabled'), 'second level condition supports subclauses')

})

QUnit.test('disables removal of a single nested condition', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: true }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  var defaults = {
    condition: {
      operator: 'OR',
      conditions: [
        {
          operator: 'AND',
          conditions: [
            {
              name: 'ticket.number',
              operator: 'contains',
              value: '123',
            },
          ],
        }
      ],
    },
  }
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'ticket_selector', preview: false, always_expert_mode: true },
      ]
    },
    params: defaults,
    autofocus: true
  })

  // Check the disable state of remove buttons.
  assert.ok(el.find('.js-filterElement:nth-child(2) .filter-controls .js-remove').hasClass('is-disabled'), 'single subclause does not support removal')
  assert.ok(el.find('.js-filterElement:nth-child(3) .filter-controls .js-remove').hasClass('is-disabled'), 'ticket number condition does not support removal')
})

QUnit.test('disables removal of a single subclause with several nested conditions', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: true }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  var defaults = {
    condition: {
      operator: 'OR',
      conditions: [
        {
          operator: 'AND',
          conditions: [],
        },
        {
          operator: 'OR',
          conditions: [
            {
              name: 'ticket.number',
              operator: 'contains',
              value: '123',
            },
            {
              name: 'ticket.state_id',
              operator: 'is',
              value: ['1'],
            }
          ],
        }
      ],
    },
  }
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'ticket_selector', preview: false, always_expert_mode: true },
      ]
    },
    params: defaults,
    autofocus: true
  })

  // Check the disable state of remove buttons.
  assert.notOk(el.find('.js-filterElement:nth-child(2) .filter-controls .js-remove').hasClass('is-disabled'), 'empty subclause supports removal')
  assert.ok(el.find('.js-filterElement:nth-child(3) .filter-controls .js-remove').hasClass('is-disabled'), 'single subclause does not support removal')
  assert.notOk(el.find('.js-filterElement:nth-child(4) .filter-controls .js-remove').hasClass('is-disabled'), 'ticket number condition supports removal')
  assert.notOk(el.find('.js-filterElement:nth-child(5) .filter-controls .js-remove').hasClass('is-disabled'), 'ticket number condition supports removal')
})

QUnit.test('enables removal of multiple subclauses with nested conditions', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: true }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  var defaults = {
    condition: {
      operator: 'OR',
      conditions: [
        {
          operator: 'AND',
          conditions: [
            {
              name: 'ticket.number',
              operator: 'contains',
              value: '123',
            },
          ],
        },
        {
          operator: 'OR',
          conditions: [
            {
              name: 'ticket.state_id',
              operator: 'is',
              value: ['1'],
            },
          ],
        },
      ],
    },
  }
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'ticket_selector', preview: false, always_expert_mode: true },
      ]
    },
    params: defaults,
    autofocus: true
  })

  // Check the disable state of remove buttons.
  assert.notOk(el.find('.js-filterElement:nth-child(2) .filter-controls .js-remove').hasClass('is-disabled'), 'first subclause supports removal')
  assert.notOk(el.find('.js-filterElement:nth-child(3) .filter-controls .js-remove').hasClass('is-disabled'), 'ticket number condition supports removal')
  assert.notOk(el.find('.js-filterElement:nth-child(4) .filter-controls .js-remove').hasClass('is-disabled'), 'second subclause supports removal')
  assert.notOk(el.find('.js-filterElement:nth-child(5) .filter-controls .js-remove').hasClass('is-disabled'), 'state condition supports removal')
})

QUnit.test('handles tags attribute without any errors #4507', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: true }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  var defaults = {
    condition: {
      operator: 'OR',
      conditions: [
        {
          name: 'ticket.tags',
          operator: 'contains one',
          value: 'tag 1',
        },
        {
          name: 'ticket.tags',
          operator: 'contains one not',
          value: 'tag 2',
        },
      ],
    },
  }
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'ticket_selector', preview: false, always_expert_mode: true },
      ]
    },
    params: defaults,
    autofocus: true
  })

  assert.equal(el.find('.js-filterElement:nth-child(2) .js-attributeSelector select option:selected').text(), 'Tags', 'tags attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(2) .js-operator select option:selected').text(), 'contains one', 'contains one operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(2) .js-value input.form-control').val(), 'tag 1', 'tag 1 input value')
  assert.equal(el.find('.js-filterElement:nth-child(3) .js-attributeSelector select option:selected').text(), 'Tags', 'tags attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(3) .js-operator select option:selected').text(), 'contains one not', 'contains one not operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(3) .js-value input.form-control').val(), 'tag 2', 'tag 2 input value')

  el.find('.js-filterElement:nth-child(2) .js-operator select').val('contains all').trigger('change')
  el.find('.js-filterElement:nth-child(2) .js-value input.form-control').val('tag 3, tag 4').trigger('change')
  el.find('.js-filterElement:nth-child(3) .js-operator select').val('contains all not').trigger('change')
  el.find('.js-filterElement:nth-child(3) .js-value input.form-control').val('tag 5, tag 6').trigger('change')

  var params = App.ControllerForm.params(el)
  var test_params = {
    condition: {
      operator: 'OR',
      conditions: [
        {
          name: 'ticket.tags',
          operator: 'contains all',
          value: 'tag 3, tag 4',
        },
        {
          name: 'ticket.tags',
          operator: 'contains all not',
          value: 'tag 5, tag 6',
        },
      ],
    },
  }
  assert.deepEqual(params, test_params, 'params structure')
})

QUnit.test('reacts on changes of pre-condition dropdown values #4532', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: true }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  var defaults = {
    condition: {
      operator: 'OR',
      conditions: [
        {
          name: 'ticket.organization_id',
          operator: 'is',
          pre_condition: 'current_user.organization_id',
          value: [],
        },
        {
          name: 'ticket.owner_id',
          operator: 'is',
          pre_condition: 'not_set',
          value: [],
        },
      ],
    },
  }
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'ticket_selector', preview: false, always_expert_mode: true },
      ]
    },
    params: defaults,
    autofocus: true
  })

  assert.equal(el.find('.js-filterElement:nth-child(2) .js-attributeSelector select option:selected').text(), 'Organization', 'organization attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(2) .js-operator select option:selected').text(), 'is', 'is operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(2) .js-preCondition select option:selected').text(), 'current user organization', 'current user organization pre-condition selected')
  assert.equal(el.find('.js-filterElement:nth-child(2) .js-value').hasClass('hide'), true, 'value invisible')
  assert.equal(el.find('.js-filterElement:nth-child(3) .js-attributeSelector select option:selected').text(), 'Owner', 'owner attribute selected')
  assert.equal(el.find('.js-filterElement:nth-child(3) .js-operator select option:selected').text(), 'is', 'is operator selected')
  assert.equal(el.find('.js-filterElement:nth-child(3) .js-preCondition select option:selected').text(), 'not set (not defined)', 'not defined pre-condition selected')
  assert.equal(el.find('.js-filterElement:nth-child(3) .js-value').hasClass('hide'), true, 'value invisible')

  el.find('.js-filterElement:nth-child(3) .js-preCondition select').val('current_user.id').trigger('change')

  var params = App.ControllerForm.params(el)
  var test_params = {
    _completion: [
      '',
      '',
    ],
    condition: {
      operator: 'OR',
      conditions: [
        {
          name: 'ticket.organization_id',
          operator: 'is',
          pre_condition: 'current_user.organization_id',
          value: [],
        },
        {
          name: 'ticket.owner_id',
          operator: 'is',
          pre_condition: 'current_user.id',
          value: [],
        },
      ],
    },
  }
  assert.deepEqual(params, test_params, 'params structure')

  el.find('.js-filterElement:nth-child(2) .js-preCondition select').val('not_set').trigger('change')

  params = App.ControllerForm.params(el)
  test_params = {
    _completion: [
      '',
      '',
    ],
    condition: {
      operator: 'OR',
      conditions: [
        {
          name: 'ticket.organization_id',
          operator: 'is',
          pre_condition: 'not_set',
          value: [],
        },
        {
          name: 'ticket.owner_id',
          operator: 'is',
          pre_condition: 'current_user.id',
          value: [],
        },
      ],
    },
  }
  assert.deepEqual(params, test_params, 'params structure')
})

/*
 * Examples in this group are with expert conditions turned off.
 */
QUnit.module('form ticket selector - without expert conditions')

QUnit.test('supports downgrade of the param structure', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: false }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  var defaults = {
    condition: {
      operator: 'AND',
      conditions: [
        {
          name: 'ticket.title',
          operator: 'contains',
          value: 'foo',
        },
      ],
    },
  }
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'ticket_selector', preview: false, always_expert_mode: true },
      ]
    },
    params: defaults,
    autofocus: true
  })
  var params = App.ControllerForm.params(el)
  var test_params = {
    condition: {
      'ticket.title': {
          operator: 'contains',
          value: 'foo',
      },
    },
  }
  assert.deepEqual(params, test_params, 'params structure')

  // Check alert visibility.
  assert.ok(el.find('[role="alert"]').hasClass('hidden'), 'alert invisible')
})

QUnit.test('shows an alert when downgrade of the param structure leads to possible data loss', (assert) => {
  var { testCount, testName } = testSetup([{ name: 'ticket_allow_expert_conditions', value: false }])
  var testFormId = `form${testCount}`
  $('#forms').append(`<hr><h1>${testName} #${testCount}</h1><form id="${testFormId}"></form>`)
  var el = $(`#${testFormId}`)
  var defaults = {
    condition: {
      operator: 'OR',
      conditions: [
        {
          name: 'ticket.title',
          operator: 'contains',
          value: 'foo',
        },
        {
          operator: 'AND',
          conditions: [
            {
              name: 'ticket.number',
              operator: 'contains',
              value: '123',
            },
            {
              name: 'ticket.state_id',
              operator: 'is',
              value: ['1'],
            }
          ],
        }
      ],
    },
  }
  new App.ControllerForm({
    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'ticket_selector', preview: false, always_expert_mode: true },
      ]
    },
    params: defaults,
    autofocus: true
  })
  var params = App.ControllerForm.params(el)
  var test_params = {
    condition: {
      'ticket.title': {
          operator: 'contains',
          value: 'foo',
      },
    },
  }
  assert.deepEqual(params, test_params, 'params structure')

  // Check alert visibility and text.
  assert.notOk(el.find('[role="alert"]').hasClass('hidden'), 'alert visible')
  assert.equal(el.find('[role="alert"]').text(), 'Caution! You disabled the expert mode. This will downgrade all expert conditions and can lead to data loss in your condition attributes. Please check your conditions before saving.', 'alert text')
})
