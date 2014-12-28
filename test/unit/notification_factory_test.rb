# encoding: utf-8
require 'test_helper'

class NotificationFactoryTest < ActiveSupport::TestCase
  test 'notifications base' do
    ticket = Ticket.create(
      :title         => 'some title äöüß',
      :group         => Group.lookup( :name => 'Users'),
      :customer_id   => 2,
      :state         => Ticket::State.lookup( :name => 'new' ),
      :priority      => Ticket::Priority.lookup( :name => '2 normal' ),
      :updated_by_id => 1,
      :created_by_id => 1,
    )
    article_plain = Ticket::Article.create(
      :ticket_id     => ticket.id,
      :type_id       => Ticket::Article::Type.where(:name => 'phone' ).first.id,
      :sender_id     => Ticket::Article::Sender.where(:name => 'Customer' ).first.id,
      :from          => 'Zammad Feedback <feedback@example.org>',
      :body          => 'some text',
      :internal      => false,
      :updated_by_id => 1,
      :created_by_id => 1,
    )
    tests = [
      {
        :locale => 'en',
        :string => 'Hi #{recipient.firstname},',
        :result => 'Hi Nicole,',
      },
      {
        :locale => 'de',
        :string => 'Hi #{recipient.firstname},',
        :result => 'Hi Nicole,',
      },
      {
        :locale => 'de',
        :string => 'Hi #{recipient.firstname}, Group: #{ticket.group.name}',
        :result => 'Hi Nicole, Group: Users',
      },
      {
        :locale => 'de',
        :string => '#{config.http_type} some text',
        :result => 'http some text',
      },
      {
        :locale => 'de',
        :string => 'i18n(New) some text',
        :result => 'Neu some text',
      },
      {
        :locale => 'de',
        :string => '\'i18n(#{ticket.state.name})\' ticket state',
        :result => '\'neu\' ticket state',
      },
      {
        :locale => 'de',
        :string => 'Subject #{article.from}, Group: #{ticket.group.name}',
        :result => 'Subject Zammad Feedback <feedback@example.org>, Group: Users',
      },
      {
        :locale => 'de',
        :string => 'Body #{article.body}, Group: #{ticket.group.name}',
        :result => 'Body > some text, Group: Users',
      },
      {
        :locale => 'de',
        :string => '\#{puts `ls`}',
        :result => '\#{puts `ls`}',
      },
    ]
    tests.each { |test|
      result = NotificationFactory.build(
        :string  => test[:string],
        :objects => {
          :ticket    => ticket,
          :article   => article_plain,
          :recipient => User.find(2),
        },
        :locale  => test[:locale]
      )
      assert_equal( test[:result], result, "verify result" )
    }

    ticket.destroy
  end

  test 'notifications html' do
    ticket = Ticket.create(
      :title         => 'some title <b>äöüß</b> 2',
      :group         => Group.lookup( :name => 'Users'),
      :customer_id   => 2,
      :state         => Ticket::State.lookup( :name => 'new' ),
      :priority      => Ticket::Priority.lookup( :name => '2 normal' ),
      :updated_by_id => 1,
      :created_by_id => 1,
    )
    article_html = Ticket::Article.create(
      :ticket_id     => ticket.id,
      :type_id       => Ticket::Article::Type.where(:name => 'phone' ).first.id,
      :sender_id     => Ticket::Article::Sender.where(:name => 'Customer' ).first.id,
      :from          => 'Zammad Feedback <feedback@example.org>',
      :body          => 'some <b>text</b><br>next line',
      :content_type  => 'text/html',
      :internal      => false,
      :updated_by_id => 1,
      :created_by_id => 1,
    )
    tests = [
      {
        :locale => 'de',
        :string => 'Subject #{ticket.title}',
        :result => 'Subject some title <b>äöüß</b> 2',
      },
      {
        :locale => 'de',
        :string => 'Subject #{article.from}, Group: #{ticket.group.name}',
        :result => 'Subject Zammad Feedback <feedback@example.org>, Group: Users',
      },
      {
        :locale => 'de',
        :string => 'Body #{article.body}, Group: #{ticket.group.name}',
        :result => 'Body > some text
> next line, Group: Users',
      },
    ]
    tests.each { |test|
      result = NotificationFactory.build(
        :string  => test[:string],
        :objects => {
          :ticket    => ticket,
          :article   => article_html,
          :recipient => User.find(2),
        },
        :locale  => test[:locale]
      )
      assert_equal( test[:result], result, "verify result" )
    }

    ticket.destroy
  end

  test 'notifications attack' do
    ticket = Ticket.create(
      :title         => 'some title <b>äöüß</b> 3',
      :group         => Group.lookup( :name => 'Users'),
      :customer_id   => 2,
      :state         => Ticket::State.lookup( :name => 'new' ),
      :priority      => Ticket::Priority.lookup( :name => '2 normal' ),
      :updated_by_id => 1,
      :created_by_id => 1,
    )
    article_html = Ticket::Article.create(
      :ticket_id     => ticket.id,
      :type_id       => Ticket::Article::Type.where(:name => 'phone' ).first.id,
      :sender_id     => Ticket::Article::Sender.where(:name => 'Customer' ).first.id,
      :from          => 'Zammad Feedback <feedback@example.org>',
      :body          => 'some <b>text</b><br>next line',
      :content_type  => 'text/html',
      :internal      => false,
      :updated_by_id => 1,
      :created_by_id => 1,
    )
    tests = [
      {
        :locale => 'de',
        :string => '\#{puts `ls`}',
        :result => '\#{puts `ls`}',
      },
      {
        :locale => 'de',
        :string => 'attack#1 #{article.destroy}',
        :result => 'attack#1 #{article.destroy}',
      },
      {
        :locale => 'de',
        :string => 'attack#2 #{Article.where}',
        :result => 'attack#2 #{Article.where}',
      },
      {
        :locale => 'de',
        :string => 'attack#1 #{article.
        destroy}',
        :result => 'attack#1 #{article.
        destroy}',
      },
      {
        :locale => 'de',
        :string => 'attack#1 #{article.find}',
        :result => 'attack#1 #{article.find}',
      },
      {
        :locale => 'de',
        :string => 'attack#1 #{article.update}',
        :result => 'attack#1 #{article.update}',
      },
      {
        :locale => 'de',
        :string => 'attack#1 #{article.all}',
        :result => 'attack#1 #{article.all}',
      },
      {
        :locale => 'de',
        :string => 'attack#1 #{article.delete}',
        :result => 'attack#1 #{article.delete}',
      },
    ]
    tests.each { |test|
      result = NotificationFactory.build(
        :string  => test[:string],
        :objects => {
          :ticket    => ticket,
          :article   => article_html,
          :recipient => User.find(2),
        },
        :locale  => test[:locale]
      )
      assert_equal( test[:result], result, "verify result" )
    }

    ticket.destroy
  end
end