# frozen_string_literal: true

describe SettingAccessors::Integration, type: :model do
  include SettingModel

  #----------------------------------------------------------------
  #                           #as_json
  #----------------------------------------------------------------

  describe '#as_json' do
    with_model 'User' do
      table do |t|
        t.string :first_name
        t.string :last_name
        t.timestamps null: false
      end

      model do
        setting_accessor :polymorphic_setting, type: :polymorphic, default: {}, fallback: :default
        setting_accessor :locale, type: :string
        setting_accessor :recently_active, type: :boolean, default: true, fallback: :default

        setting_accessor :catchphrase, type: :string, fallback: 'Oiski Poiski!'
        setting_accessor :additional_catchphrase, type: :string, fallback: :default, default: 'Kapitanski'

        validates :locale, presence: true
      end
    end

    let(:user_attributes) { {first_name: 'Sascha', last_name: 'Desman', locale: 'RU-ru'} }
    let(:user) { User.create(user_attributes) }
    let(:additional_attribute_names) { %w[id created_at updated_at] }
    let(:options) { {} }
    let(:json) { user.as_json(options) }
    let(:settings_and_attributes) { setting_names(User) + user_attributes.keys.map(&:to_s) }

    context 'when being called without options' do
      it 'returns all attributes and all settings' do
        settings_and_attributes.each do |name|
          expect(json).to include(name => user.send(name))
        end
      end
    end

    context 'when being called with the :only option' do
      let(:options) { super().merge(only: %i[first_name locale]) }

      it 'returns only the requested attributes and settings' do
        expect(json).to eql user_attributes.slice(:first_name, :locale).stringify_keys
      end
    end

    context 'when being called with the :except option' do
      let(:options) { super().merge(except: %w[first_name recent_activity]) }

      it 'returns all attributes and settings except for the given exclusions' do
        (settings_and_attributes - options[:except]).each do |name|
          expect(json).to include(name => user.send(name))
        end

        options[:except].each do |name|
          expect(json).not_to include(name)
        end
      end
    end
  end

  #----------------------------------------------------------------
  #                            #save
  #----------------------------------------------------------------

  describe '#save' do
    context 'when a normal attribute was changed' do

    end

    context 'when only a setting was changed' do
      context 'by assigning ' do

      end
    end
  end

  #----------------------------------------------------------------
  #                          #reload
  #----------------------------------------------------------------

  describe '#reload' do

  end

  #----------------------------------------------------------------
  #                      .setting_accessor
  #----------------------------------------------------------------

  describe '.setting_accessor' do
    let(:record) { TestModel.create }

    shared_examples 'getters' do
      it 'creates a getter method' do
        expect(record).to respond_to(:setting_with_default)
      end

      context 'if a default value was set' do
        context 'and no custom value was given yet' do
          it 'returns the default value' do
            expect(record.setting_with_default).to eql default_value
          end
        end

        context 'and a custom value was given' do
          it 'returns the custom value' do
            record.setting_with_default = custom_value
            expect(record.setting_with_default).to eql custom_value
          end
        end
      end

      context 'if no default value was set' do
        it 'returns nil' do
          expect(record.setting_without_default).to be nil
        end
      end
    end

    shared_examples 'setters' do
      it 'creates a setter method' do
        expect(record).to respond_to(:setting_with_default=)
      end

      it 'marks the attribute as changed when a new value is assigned' do
        record.setting_with_default = custom_value
        expect(record.setting_with_default_changed?).to be true
      end

      it 'marks the record as changed when a new value is assigned' do
        record.setting_with_default = custom_value
        expect(record).to be_changed
      end

      it 'typecasts the value correctly' do
        record.setting_with_default = raw_custom_value
        expect(record.setting_with_default).to eql custom_value
        expect(record.setting_with_default_before_type_cast).to eql raw_custom_value
      end

      it 'provides access to the old value until the record is saved' do
        record.setting_with_default = custom_value
        expect(record.setting_with_default_was).to eql default_value
        record.save!
        record.setting_with_default = default_value
        expect(record.setting_with_default_was).to eql custom_value

        # Sub-test for nil values
        record.setting_without_default = custom_value
        expect(record.setting_without_default_was).to be nil
      end
    end

    context 'when setting up a boolean setting' do
      with_model 'TestModel' do
        model do
          setting_accessor :setting_with_default, type: :boolean, default: true
          setting_accessor :setting_without_default, type: :boolean
        end
      end

      let(:default_value) { true }
      let(:custom_value) { false }
      let(:raw_custom_value) { 'false' }

      context 'regarding setters' do
        include_examples 'setters'
      end

      context 'regarding getters' do
        include_examples 'getters' do
          it 'creates a ?-alias for the getter' do
            expect(record).to respond_to(:setting_with_default?)
            expect(record.setting_with_default?).to eql record.setting_with_default
          end
        end
      end
    end

    context 'when setting up a string setting' do
      with_model 'TestModel' do
        model do
          setting_accessor :setting_with_default, type: :string, default: 'Oiski Poiski!'
          setting_accessor :setting_without_default, type: :string
        end
      end

      let(:default_value) { 'Oiski Poiski!' }
      let(:custom_value) { 'true' }
      let(:raw_custom_value) { true }

      context 'regarding getters' do
        include_examples 'getters'
      end

      context 'regarding setters' do
        include_examples 'setters'
      end
    end

    context 'when setting up an integer setting' do
      with_model 'TestModel' do
        model do
          setting_accessor :setting_with_default, type: :integer, default: 42
          setting_accessor :setting_without_default, type: :integer
        end
      end

      let(:default_value) { 42 }
      let(:custom_value) { 21 }
      let(:raw_custom_value) { '21' }

      context 'regarding getters' do
        include_examples 'getters'
      end

      context 'regarding setters' do
        include_examples 'setters'
      end
    end

    context 'when setting up a polymorphic setting' do
      with_model 'TestModel' do
        model do
          setting_accessor :setting_with_default, type: :polymorphic, default: {}
          setting_accessor :setting_without_default, type: :polymorphic
        end
      end

      let(:default_value) { {} }
      let(:custom_value) { {oiski: 'Poiski'} }
      let(:raw_custom_value) { custom_value }

      context 'regarding getters' do
        include_examples 'getters'
      end

      context 'regarding setters' do
        include_examples 'setters' do
          it 'does not share the default value between all settings' do
            # yes, this happened...
            another_record = TestModel.create
            record.setting_with_default[:a] = :b
            expect(another_record.setting_with_default).to eql default_value
          end

          it 'marks the attribute as changed when the existing value is mutated' do
            record.setting_with_default[:a] = :b
            expect(record.setting_with_default_changed?).to be true
          end

          it 'marks the record as changed when the existing value is mutated' do
            record.setting_with_default[:a] = :b
            expect(record).to be_changed
          end
        end
      end
    end
  end
end
