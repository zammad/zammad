# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe PasswordPolicy do

  subject(:instance) { described_class.new('some_password') }

  let(:passing_job_class)         { make_job_class(valid: true,  applicable: true,  error: 'passing job') }
  let(:failing_job_class)         { make_job_class(valid: false, applicable: true,  error: 'failing job') }
  let(:another_failing_job_class) { make_job_class(valid: false, applicable: true,  error: 'another failing job') }
  let(:not_applicable_job_class)  { make_job_class(valid: false, applicable: false, error: 'not applicable job') }

  describe '#valid?' do
    it 'returns true when all backends pass' do
      instance.backends = Set.new [passing_job_class]
      expect(instance).to be_valid
    end

    it 'returns false when one of backends fail' do
      instance.backends = Set.new [passing_job_class, failing_job_class]
      expect(instance).not_to be_valid
    end

    it 'returns true when one of backends fail but is not applicable' do
      instance.backends = Set.new [passing_job_class, not_applicable_job_class]
      expect(instance).to be_valid
    end
  end

  describe '#error' do
    it 'returns nil when no errors present' do
      instance.backends = Set.new
      expect(instance.error).to be_nil
    end

    it 'returns Array with the error when an error is present' do
      instance.backends = Set.new [failing_job_class]
      expect(instance.errors.first).to eq(['failing job'])
    end

    it 'returns Array with the first error when multiple errors are present' do
      instance.backends = Set.new [another_failing_job_class, failing_job_class]
      expect(instance.errors.first).to eq(['another failing job'])
    end
  end

  describe '#errors' do
    it 'returns empty Array when all backends pass' do
      instance.backends = Set.new [passing_job_class]
      expect(instance.errors).to be_kind_of(Array).and(be_blank)
    end

    it 'returns an Array of Arrays when one of backends fail' do
      instance.backends = Set.new [failing_job_class]
      expect(instance.errors.first).to be_kind_of(Array)
    end
  end

  def make_job_class(valid:, applicable:, error:)
    klass = Class.new(PasswordPolicy::Backend)
    klass.define_method(:valid?) { valid }
    klass.define_singleton_method(:applicable?) { applicable }
    klass.define_method(:error) { [error] }

    klass
  end
end
