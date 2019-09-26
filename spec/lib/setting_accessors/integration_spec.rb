# frozen_string_literal: true

describe SettingAccessors::Integration, type: :model do

  #----------------------------------------------------------------
  #                           #as_json
  #----------------------------------------------------------------

  describe '#as_json' do
    context 'when not setting accessors are defined in the application' do
      with_model 'User' do
        table do |t|
          t.string :first_name
          t.string :last_name
          t.timestamps null: false
        end
      end

      let(:user_attributes) { {first_name: 'Sascha', last_name: 'Desman'} }
      let(:user) { User.create(user_attributes) }

      it "returns the record's attributes" do
        expect(user.as_json).to eql(user.attributes)
      end
    end

    context 'when setting accessors are defined in the application' do
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
  end

  #----------------------------------------------------------------
  #                       #create_or_update
  #----------------------------------------------------------------

  describe '#create_or_update' do
    with_model 'TestModel' do
      table do |t|
        t.string :string_attribute
        t.timestamps null: false
      end

      model do
        setting_accessor :string_setting, type: :string

        before_update :i_hate_johns, if: :johns_here

        def johns_here
          string_attribute == 'john'
        end

        def i_hate_johns
          Gem.loaded_specs['activerecord'].version >= Gem::Version.create('5.1') &&
            throw(:abort)
        end
      end
    end

    let(:initial_updated_at) { 1.day.ago }

    let!(:record) do
      TestModel.create(string_attribute: 'string_value', string_setting: 'string_setting_value', updated_at: initial_updated_at)
    end

    shared_examples 'attribute update and touch' do |attribute_name|
      it 'persists the record accordingly' do
        expect(TestModel.find(record.id).send(attribute_name)).to eql 'Poiski'
      end

      it 'updates the +updated_at+ column accordingly' do
        expect(TestModel.find(record.id).updated_at).to be_within(5.seconds).of(Time.now)
      end
    end

    shared_examples 'no touch' do
      it 'does not alter the +updated_at+ column' do
        expect(TestModel.find(record.id).updated_at).to eql initial_updated_at
      end
    end

    shared_examples 'attribute setter variations' do |attribute_name|
      context 'using a normal attribute setter and #save' do
        before(:each) do
          record.send("#{attribute_name}=", 'Poiski')
          record.save!
        end

        include_examples 'attribute update and touch', attribute_name
      end

      context 'using #update_attribute' do
        before(:each) { record.update_attribute(attribute_name, 'Poiski') }

        include_examples 'attribute update and touch', attribute_name
      end

      context 'using mass assignment (#update_attributes)' do
        before(:each) { record.update_attributes(attribute_name => 'Poiski') }

        include_examples 'attribute update and touch', attribute_name
      end
    end

    context 'when nothing was changed at all' do
      context 'and using #save' do
        before(:each) { record.save! }

        include_examples 'no touch'
      end

      context 'and using mass assignment (#update_attributes)' do
        before(:each) { record.update_attributes({}) }

        include_examples 'no touch'
      end
    end

    context 'when a normal attribute was changed' do
      include_examples 'attribute setter variations', :string_attribute
    end

    context 'when only a setting was changed' do
      include_examples 'attribute setter variations', :string_setting
    end

    context 'when an update is not valid and aborted using the abort symbol' do
      before(:each) { record.update_attributes(string_attribute: 'john', string_setting: 'jane') }

      it 'does not alter setting values' do
        expect(record.reload.string_setting).to eql 'string_setting_value'
      end

      include_examples 'no touch'
    end
  end

  #----------------------------------------------------------------
  #                          #reload
  #----------------------------------------------------------------

  describe '#reload' do
    with_model 'TestModel' do
      model do
        setting_accessor :a_string, type: :string, default: 'Oiski'
      end
    end

    it 'refreshes settings from the database' do
      record = TestModel.create
      expect(record.a_string).to eql 'Oiski'
      TestModel.find(record.id).update_attributes(a_string: 'Poiski')
      expect { record.reload }.to change(record, :a_string).from('Oiski').to('Poiski')
    end

    it 'discards locally changed but not persisted settings' do
      record = TestModel.create
      record.a_string = 'Poiski'
      expect { record.reload }.to change(record, :a_string).from('Poiski').to('Oiski')
    end
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
