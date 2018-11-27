# frozen_string_literal: true

describe SettingAccessors::SettingSet do
  include SettingModel
  with_model 'Assignable' do
    model do
      setting_accessor :a_string, type: :string, default: ''
      setting_accessor :an_integer, type: :integer, default: 0
      setting_accessor :a_boolean, type: :boolean, default: true
      setting_accessor :an_array, type: :polymorphic, default: []
    end
  end

  #----------------------------------------------------------------
  #                           #persist!
  #----------------------------------------------------------------

  describe '#persist' do
    let(:assignable) { Assignable.create }
    let(:instance) { described_class.new(assignable) }

    it 'only persists settings which were actually changed' do
      Setting.set(:a_string, 'a', assignable: assignable)
      Setting.set(:an_integer, 42, assignable: assignable)

      instance.set(:a_string, 'a')
      instance.set(:an_integer, 21)

      expect(Setting).to receive(:set).with(:an_integer, 21, assignable: assignable)
      instance.send(:persist!)
    end
  end

  #----------------------------------------------------------------
  #                         #value_was
  #----------------------------------------------------------------

  describe '#value_was' do
    let(:assignable) { Assignable.create }
    let(:instance) { described_class.new(assignable) }

    shared_examples 'correct value without side-effects' do
      it 'returns the value in the database' do
        expect(instance.get_or_default(setting_name)).to eql expected_new_value
        expect(instance.value_was(setting_name)).to eql expected_old_value
      end

      it 'does not change the current value' do
        expect { instance.value_was(setting_name) }.not_to change(instance, :changed_settings)
      end
    end

    # Required #let's:
    # - new_value: The new setting value to be used in #set
    shared_examples '#set usage' do
      context 'and the new value was set using #set' do
        include_examples 'correct value without side-effects' do
          before(:each) { instance.set(setting_name, expected_new_value) }
        end
      end
    end

    # Required #let's:
    # - mutation_proc: Block that's executed to change the existing setting value in-place
    # - expected_old_value: The value before mutating it
    # - mutation_suffix: The value to be appended to the existing value through mutation
    shared_examples 'mutation' do
      context 'and the value was mutated instead of #set' do
        include_examples 'correct value without side-effects' do
          before(:each) { mutation_proc.call }
        end
      end
    end

    shared_examples 'immutable setting' do
      context 'and the setting already exists in the database' do
        before(:each) { Setting.set(setting_name, existing_value, assignable: assignable) }
        let(:expected_old_value) { existing_value }

        include_examples '#set usage'
      end

      context 'and the setting does not exist in the database yet' do
        let(:expected_old_value) { default_value }

        include_examples '#set usage'
      end
    end

    shared_examples 'mutable setting' do
      let(:expected_new_value) { expected_old_value + new_value_suffix }

      context 'and the setting already exists in the database' do
        before(:each) { Setting.set(setting_name, existing_value, assignable: assignable) }
        let(:expected_old_value) { existing_value }

        include_examples '#set usage'
        include_examples 'mutation'
      end

      context 'and the setting does not exist in the database yet' do
        let(:expected_old_value) { default_value }

        include_examples '#set usage'
        include_examples 'mutation'
      end
    end

    context 'when referring to a boolean setting' do
      include_examples 'immutable setting' do
        let(:setting_name) { :a_boolean }
        let(:existing_value) { true }
        let(:default_value) { true }
        let(:expected_new_value) { false }
      end
    end

    context 'when referring to an integer setting' do
      include_examples 'immutable setting' do
        let(:setting_name) { :an_integer }
        let(:existing_value) { 21 }
        let(:default_value) { 0 }
        let(:expected_new_value) { 42 }
      end
    end

    context 'when referring to a :string setting' do
      include_examples 'mutable setting' do
        let(:setting_name) { :a_string }
        let(:existing_value) { 'a' }
        let(:default_value) { '' }
        let(:new_value_suffix) { String.new('b') }
        let(:mutation_proc) { -> { instance.get_or_default(setting_name) << new_value_suffix } }
      end
    end

    context 'when referring to a :polymorphic setting' do
      include_examples 'mutable setting' do
        let(:setting_name) { :an_array }
        let(:existing_value) { [1] }
        let(:default_value) { [] }
        let(:new_value_suffix) { [5] }
        let(:mutation_proc) { -> { instance.get_or_default(setting_name).push(new_value_suffix.first) } }
      end
    end
  end
end
