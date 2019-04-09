require 'rails_helper'

RSpec.describe Issue2541FixNotificationEmailWithoutBody, type: :db_migration do

  context 'when migrating Triggers' do

    before(:all) { Trigger.skip_callback(:create, :before, :validate_perform) }

    it "updates empty perform['notification.email']['body'] attribute" do
      trigger = create(:trigger,
                       perform: {
                         'notification.email' => {
                           'body'      => '',
                           'recipient' => 'article_last_sender',
                           'subject'   => 'Thanks for your inquiry (#{ticket.title})', # rubocop:disable Lint/InterpolationCheck
                         },
                       })

      expect { migrate }.to change { trigger.reload.perform['notification.email']['body'] }.from('').to('-')
    end

    it "updates empty perform['notification.sms']['body'] attribute" do
      trigger = create(:trigger,
                       perform: {
                         'notification.sms' => {
                           'body'      => '',
                           'recipient' => 'article_last_sender',
                         },
                       })

      expect { migrate }.to change { trigger.reload.perform['notification.sms']['body'] }.from('').to('-')
    end
  end

  context 'when migrating Jobs' do

    before(:all) { Job.skip_callback(:create, :before, :validate_perform) }

    it "updates empty perform['notification.email']['body'] attribute" do

      job = create(:job,
                   perform: {
                     'notification.email' => {
                       'body'      => '',
                       'recipient' => 'article_last_sender',
                       'subject'   => 'Thanks for your inquiry (#{ticket.title})', # rubocop:disable Lint/InterpolationCheck
                     },
                   },)

      expect { migrate }.to change { job.reload.perform['notification.email']['body'] }.from('').to('-')
    end
  end

  it "re-enables 'Job.run' Scheduler" do
    scheduler = Scheduler.find_by(method: 'Job.run')
    scheduler.update!(active: false)

    expect { migrate }.to change { scheduler.reload.active }.to(true)
  end

end
