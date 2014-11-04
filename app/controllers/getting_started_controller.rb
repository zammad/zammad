# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

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
    return if setup_done_response

    # if master user already exists, we need to be authenticated
    if setup_done
      return if !authentication_check
    end

    # get all groups
    groups = Group.where( :active => true )

    # return result
    render :json => {
      :setup_done     => setup_done,
      :import_mode    => Setting.get('import_mode'),
      :import_backend => Setting.get('import_backend'),
      :groups         => groups,
    }
  end

  def base_url
    return if setup_done_response

    # validate
    if !params[:url] ||params[:url] !~ /^(http|https):\/\/.+?$/
      render :json => {
        :result  => 'invalid',
        :message => 'Invalid!',
      }
      return
    end

    # split url in http_type and fqdn
    if params[:url] =~ /^(http|https):\/\/(.+?)$/
      Setting.set('http_type', $1)
      Setting.set('fqdn', $2)

      render :json => {
        :result => 'ok',
      }
      return
    end

    render :json => {
      :result  => 'invalid',
      :message => 'Unable to parse url!',
    }
  end

  def base_outbound
    return if setup_done_response

    # validate params
    if !params[:adapter]
      render :json => {
        :result  => 'invalid',
        :message => 'Invalid!',
      }
      return
    end

    # test connection
    translationMap = {
      'authentication failed' => 'Authentication failed!',
      'getaddrinfo: nodename nor servname provided, or not known' => 'Hostname not found!',
      'No route to host' => 'No route to host!',
      'Connection refused' => 'Connection refused!',
    }
    if params[:adapter] == 'smtp'
      begin
        Channel::SMTP.new.send(
          {
            :from    => 'me@example.com',
            :to      => 'emailtrytest@znuny.com',
            :subject => 'test',
            :body    => 'test',
          },
          {
            :options => params[:options]
          }
        )
      rescue Exception => e

        # check if sending email was ok, but mailserver rejected
        whiteMap = {
          'Recipient address rejected' => true,
        }
        whiteMap.each {|key, message|
          if e.message =~ /#{Regexp.escape(key)}/i
            render :json => {
              :result => 'ok',
            }
            return
          end
        }
        message_human = ''
        translationMap.each {|key, message|
          if e.message =~ /#{Regexp.escape(key)}/i
            message_human = message
          end
        }
        render :json => {
          :result        => 'invalid',
          :message       => e.message,
          :message_human => message_human,
        }
        return
      end

    else
      begin
        Channel::Sendmail.new.send(
          {
            :from    => 'me@example.com',
            :to      => 'emailtrytest@znuny.com',
            :subject => 'test',
            :body    => 'test',
          },
          nil
        )
      rescue Exception => e
        message_human = ''
        translationMap.each {|key, message|
          if e.message =~ /#{Regexp.escape(key)}/i
            message_human = message
          end
        }
        render :json => {
          :result        => 'invalid',
          :message       => e.message,
          :message_human => message_human,
        }
        return
      end
    end

    # save settings
    if params[:adapter] == 'smtp'
      smtp = Channel.where( :adapter  => 'SMTP', :area => 'Email::Outbound' ).first
      smtp.options = params[:options]
      smtp.active  = true
      smtp.save!
      sendmail = Channel.where(:adapter => 'Sendmail').first
      sendmail.active = false
      sendmail.save!
    else
      sendmail = Channel.where( :adapter  => 'Sendmail', :area => 'Email::Outbound' ).first
      sendmail.options = {}
      sendmail.active  = true
      sendmail.save!
      smtp = Channel.where(:adapter => 'SMTP').first
      smtp.active = false
      smtp.save
    end

    # return result
    render :json => {
      :result => 'ok',
    }
  end

  def base_inbound
    return if setup_done_response

    # validate params
    if !params[:adapter]
      render :json => {
        :result => 'invalid',
      }
      return
    end

    # connection test
    translationMap = {
      'authentication failed'                                     => 'Authentication failed!',
      'getaddrinfo: nodename nor servname provided, or not known' => 'Hostname not found!',
      'No route to host'                                          => 'No route to host!',
      'Connection refused'                                        => 'Connection refused!',
    }
    if params[:adapter] == 'IMAP'
      begin
        Channel::IMAP.new.fetch( { :options => params[:options] }, 'check' )
      rescue Exception => e
        message_human = ''
        translationMap.each {|key, message|
          if e.message =~ /#{Regexp.escape(key)}/i
            message_human = message
          end
        }
        render :json => {
          :result        => 'invalid',
          :message       => e.message,
          :message_human => message_human,
        }
        return
      end
    else
      begin
        Channel::POP3.new.fetch( { :options => params[:options] }, 'check' )
      rescue Exception => e
        message_human = ''
        translationMap.each {|key, message|
          if e.message =~ /#{Regexp.escape(key)}/i
            message_human = message
          end
        }
        render :json => {
          :result        => 'invalid',
          :message       => e.message,
          :message_human => message_human,
        }
        return
      end
    end

    # send verify email to inbox
    subject = '#' + rand(99999999999).to_s
    Channel::EmailSend.new.send(
      {
        :from             => params[:email],
        :to               => params[:email],
        :subject          => "Zammad Getting started Test Email #{subject}",
        :body             => '.',
        'x-zammad-ignore' => 'true',
      }
    )
    (1..5).each {|loop|
      sleep 10

      # fetch mailbox
      found = nil
      if params[:adapter] == 'IMAP'
        found = Channel::IMAP.new.fetch( { :options => params[:options] }, 'verify', subject )
      else
        found = Channel::POP3.new.fetch( { :options => params[:options] }, 'verify', subject )
      end

      if found && found == 'verify ok'

        # remember address
        address = EmailAddress.all.first
        if address
          address.update_attributes(
            :realname      => 'Zammad',
            :email         => params[:email],
            :active        => 1,
            :updated_by_id => 1,
            :created_by_id => 1,
          )
        else
          EmailAddress.create(
            :realname      => 'Zammad',
            :email         => params[:email],
            :active        => 1,
            :updated_by_id => 1,
            :created_by_id => 1,
          )
        end

        # store mailbox
        Channel.create(
          :area          => 'Email::Inbound',
          :adapter       => params[:adapter],
          :options       => params[:options],
          :group_id      => 1,
          :active        => 1,
          :updated_by_id => 1,
          :created_by_id => 1,
        )

        render :json => {
          :result => 'ok',
        }
        return
      end
    }

    # check dilivery for 30 sek.
    render :json => {
      :result  => 'invalid',
      :message => 'Verification Email not found in mailbox.',
    }
    return
  end

  private

  def setup_done
    #return false
    count = User.all.count()
    done = true
    if count <= 2
      done = false
    end
    done
  end

  def setup_done_response
    if !setup_done
      return false
    end
    render :json => {
      :setup_done     => true,
      :import_mode    => Setting.get('import_mode'),
      :import_backend => Setting.get('import_backend'),
    }
    true
  end

end