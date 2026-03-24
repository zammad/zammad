# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe PasswordSettingsChangeType, type: :db_migration do
  let(:setting) { Setting.find_by(name:) }

  describe 'migration of password_min_2_lower_2_upper_characters' do
    let(:name) { 'password_min_2_lower_2_upper_characters' }

    before do
      setting.update!(
        state_current: { value: 0 },
        state_initial: { value: 1 },
        options:       {
          form: [
            {
              display: '',
              null:    true,
              name:    'password_min_2_lower_2_upper_characters',
              tag:     'select',
              options: {
                1 => 'yes',
                0 => 'no',
              },
            }
          ]
        }
      )
    end

    it 'applies changes' do
      migrate

      expect(setting.reload).to have_attributes(
        name:,
        state_current: { value: false },
        state_initial: { value: true },
        options:       {
          form: [
            {
              display: '',
              null:    true,
              name:    'password_min_2_lower_2_upper_characters',
              tag:     'boolean',
              options: {
                true  => 'yes',
                false => 'no',
              },
            },
          ],
        },
      )
    end
  end

  describe 'migration of password_need_digit' do
    let(:name) { 'password_need_digit' }

    before do
      setting.update!(
        state_current: { value: 0 },
        state_initial: { value: 1 },
        options:       {
          form: [
            {
              display: 'Needed',
              null:    true,
              name:    'password_need_digit',
              tag:     'select',
              options: {
                1 => 'yes',
                0 => 'no',
              },
            }
          ]
        }
      )
    end

    it 'applies changes' do
      migrate

      expect(setting.reload).to have_attributes(
        name:,
        state_current: { value: false },
        state_initial: { value: true },
        options:       {
          form: [
            {
              display: '',
              null:    true,
              name:    'password_need_digit',
              tag:     'boolean',
              options: {
                true  => 'yes',
                false => 'no',
              },
            },
          ],
        },
      )
    end
  end

  describe 'migration of password_need_special_character' do
    let(:name) { 'password_need_special_character' }

    before do
      setting.update!(
        state_current: { value: 1 },
        state_initial: { value: 0 },
        options:       {
          form: [
            {
              display: 'Needed',
              null:    true,
              name:    'password_need_special_character',
              tag:     'select',
              options: {
                1 => 'yes',
                0 => 'no',
              },
            }
          ]
        }
      )
    end

    it 'applies changes' do
      migrate

      expect(setting.reload).to have_attributes(
        name:,
        state_current: { value: true },
        state_initial: { value: false },
        options:       {
          form: [
            {
              display: '',
              null:    true,
              name:    'password_need_special_character',
              tag:     'boolean',
              options: {
                true  => 'yes',
                false => 'no',
              },
            },
          ],
        },
      )
    end
  end

  describe 'migration of auth_openid_connect_credentials' do
    let(:name) { 'auth_openid_connect_credentials' }

    before do
      setting.options[:form].find { it[:name] == 'pkce' }[:tag] = 'select'
      setting.save!
    end

    it 'applies changes' do
      migrate

      expect(setting.reload).to have_attributes(
        name:    'auth_openid_connect_credentials',
        options: {
          'form' => include(
            include(name: 'pkce', tag: 'boolean', display: 'PKCE'), # Check if migration was OK
            include(display: 'Scopes') # Check if the rest of form values are not lost
          )
        }
      )
    end
  end
end
