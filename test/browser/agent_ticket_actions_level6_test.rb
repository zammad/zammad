# encoding: utf-8
require 'browser_test_helper'

class AgentTicketActionLevel6Test < TestCase
  def test_ticket

    @browser = browser_instance
    login(
      :username => 'agent1@example.com',
      :password => 'test',
      :url      => browser_url,
    )
    tasks_close_all()

    #
    # attachment checks - new ticket
    #

    # create new ticket with no attachment, attachment check should pop up
    ticket1 = ticket_create(
      :data => {
        :customer => 'nico',
        :group    => 'Users',
        :title    => 'test 6 - ticket 1',
        :body     => 'test 6 - ticket 1 - with the word attachment, but not attachment atteched it should give an warning on submit',
      },
      :do_not_submit => true,
    )
    sleep 1

    # submit form
    click( :css => '.content.active button.submit' )
    sleep 2

    # check warning
    alert = @browser.switch_to.alert
    alert.dismiss()
    #alert.accept()
    #alert = alert.text

    # add attachment, attachment check should quiet
    @browser.execute_script( "App.TestHelper.attachmentUploadFake('.active .richtext .attachments')" )

    # submit form
    click( :css => '.content.active button.submit' )
    sleep 5

    # no warning
    #alert = @browser.switch_to.alert

    # check if ticket is shown
    location_check( :url => '#ticket/zoom/' )



    #
    # attachment checks - update ticket
    #

    # update ticket with no attachment, attachment check should pop up
    ticket_update(
      :data => {
        :body => 'test 6 - ticket 1-1 - with the word attachment, but not attachment atteched it should give an warning on submit',
      },
      :do_not_submit => true,
    )

    # submit form
    click(
      :css => '.active button.js-submit',
    )
    sleep 2

    # check warning
    alert = @browser.switch_to.alert
    alert.dismiss()

    # add attachment, attachment check should quiet
    @browser.execute_script( "App.TestHelper.attachmentUploadFake('.active .article-add .textBubble .attachments')" )

    # submit form
    click(
      :css => '.active button.js-submit',
    )
    sleep 2

    # no warning
    #alert = @browser.switch_to.alert

    # check if article exists

    # discard changes should gone away
    watch_for_disappear(
      :css      => '.content.active .js-reset',
      :value    => '(Discard your unsaved changes.|Verwerfen der)',
      :no_quote => true,
    )
    ticket_verify(
      :data => {
        :body => '',
      },
    )

    # check content and edit screen in instance 1
    match(
      :css   => '.active div.ticket-article',
      :value => 'test 6 - ticket 1-1',
    )


    #
    # ticket customer change checks
    #

    # update customer, check if new customer is shown in side bar


    # check if customer has changed in second browser


    #
    # ticket customer organization change checks
    #

    # change org of customer, check if org is shown in sidebar


    # check if org has changed in second browser





    #
    # form change/reset checks
    #


    # some form reset checks
  end
end