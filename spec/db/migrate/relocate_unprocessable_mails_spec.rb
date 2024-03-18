# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

UNPROCESSABLE_DIR_OLD = Rails.root.join('tmp/unprocessable_mail')
UNPROCESSABLE_DIR_NEW = Rails.root.join('var/spool/unprocessable_mail')
OVERSIZED_DIR_OLD = Rails.root.join('tmp/oversized_mail')
OVERSIZED_DIR_NEW = Rails.root.join('var/spool/oversized_mail')
OLD_DIRS = [UNPROCESSABLE_DIR_OLD, OVERSIZED_DIR_OLD].freeze
NEW_DIRS = [UNPROCESSABLE_DIR_NEW, OVERSIZED_DIR_NEW].freeze
DIRS = [UNPROCESSABLE_DIR_OLD, UNPROCESSABLE_DIR_NEW, OVERSIZED_DIR_OLD, OVERSIZED_DIR_NEW].freeze
VAR_DIR = Rails.root.join('var')

RSpec.describe RelocateUnprocessableMails, :aggregate_failures, type: :db_migration do

  def remove_all_directories
    [*DIRS, VAR_DIR].each { |dir| FileUtils.rm_r(dir) if File.exist?(dir) }
  end

  def create_old_directories
    OLD_DIRS.each { |dir| FileUtils.mkdir_p(dir) }
  end

  def create_all_directories
    DIRS.each { |dir| FileUtils.mkdir_p(dir) }
  end

  before do
    remove_all_directories
  end

  after do
    remove_all_directories
  end

  context 'when migrating' do
    context 'without unprocessable mail directory' do
      it 'does nothing' do
        migrate
        DIRS.each { |dir| expect(dir).not_to exist }
      end
    end

    context 'with empty unprocessable mail directory' do
      before do
        create_old_directories
      end

      it 'does nothing' do
        migrate
        expect(OLD_DIRS).to all(exist)
        NEW_DIRS.each { |dir| expect(dir).not_to exist }
      end
    end

    context 'with unprocessable mails present' do
      before do
        create_old_directories
        %w[unprocessable_mail oversized_mail].each do |type|
          files = [
            "tmp/#{type}/1.eml",
            "tmp/#{type}/2.eml",
          ]
          FileUtils.touch(files.map { |f| Rails.root.join(f) })
        end
      end

      context 'with var folder being not creatable' do
        before do
          # Fake a situation with a readonly FS where the var folder cannot be created by
          #   placing a reguar 'var' file instead. Migration must tolerate this and skip.
          FileUtils.touch(VAR_DIR)
        end

        after do
          # Remove the regular 'var' file again.
          FileUtils.rm(VAR_DIR)
        end

        it 'silently skips the migration' do
          migrate
          expect([UNPROCESSABLE_DIR_OLD, OVERSIZED_DIR_OLD]).to all(exist)
        end
      end

      context 'with var folder being creatable' do

        it 'removes source directories' do
          migrate
          [UNPROCESSABLE_DIR_OLD, OVERSIZED_DIR_OLD].each { |dir| expect(dir).not_to exist }
        end

        it 'migrates files' do
          migrate
          %w[unprocessable_mail oversized_mail].each do |type|
            files = [
              "var/spool/#{type}/1.eml",
              "var/spool/#{type}/2.eml",
            ]
            files.each { |f| expect(Pathname.new(f)).to exist }
          end
        end
      end

      context 'with var folder being already present and having entries' do

        before do
          create_all_directories
          %w[unprocessable_mail oversized_mail].each do |type|
            files = [
              "var/spool/#{type}/2.eml",
              "var/spool/#{type}/3.eml",
            ]
            FileUtils.touch(files.map { |f| Rails.root.join(f) })
          end
        end

        it 'migrates files and keeps existing' do
          migrate
          %w[unprocessable_mail oversized_mail].each do |type|
            files = [
              "var/spool/#{type}/1.eml",
              "var/spool/#{type}/2.eml",
              "var/spool/#{type}/3.eml",
            ]
            files.each { |f| expect(Pathname.new(f)).to exist }
          end
        end
      end
    end
  end
end
