# frozen_string_literal: true

describe SettingAccessors::SettingScaffold, type: :model do
  with_model 'User'

  #----------------------------------------------------------------
  #                         .method_missing
  #----------------------------------------------------------------

  describe 'method_missing' do
    context 'when a possible getter is being called' do
      context 'with an additional argument (assignable)' do
        let(:assignable) { User.create }

        it 'forwards the call to Setting.get' do
          expect(Setting).to receive(:get).with('foo', assignable)
          Setting.foo(assignable)
        end
      end

      context 'with no additional arguments' do
        it 'forwards the call to Setting.get' do
          expect(Setting).to receive(:get).with('foo', nil)
          Setting.foo
        end
      end

      context 'with more than one argument' do
        it 'calls the original method_missing, leading to a NoMethodError' do
          expect { Setting.foo('bar', 'baz') }.to raise_error NoMethodError
        end
      end
    end

    context 'when a setter is being called' do
      context 'with the new value as its argument' do
        it 'forwards the call to Setting.create_or_update' do
          expect(Setting).to receive(:set).with('foo', 'bar')
          Setting.foo = 'bar'
        end
      end
    end
  end

  #----------------------------------------------------------------
  #                             .get
  #----------------------------------------------------------------

  describe '.get' do
    context 'when being called without an assignable' do
      context 'and no setting with that name exists yet' do
        it 'returns nil' do
          expect(Setting.get('foo')).to be nil
        end
      end

      context 'and a setting with that name already exists' do
        it "returns the setting's value" do
          Setting.create(name: 'foo', value: 'bar')
          expect(Setting.get('foo')).to eql 'bar'
        end
      end
    end

    context 'when being called with an assignable' do
      let(:assignable) { User.create }
      subject { Setting.get('foo', assignable) }

      before(:each) do
        Setting.create(name: 'foo', value: 'bar')
        Setting.create(name: 'foo', value: 'baz', assignable: User.create)
      end

      context 'and no assigned setting with that name exists yet' do
        it { is_expected.to be nil }
      end

      context 'and an assigned setting with that name already exists' do
        before(:each) { Setting.create(name: 'foo', value: 'BAM', assignable: assignable) }

        it { is_expected.to eql 'BAM' }
      end
    end
  end

  #----------------------------------------------------------------
  #                           .get!
  #----------------------------------------------------------------

  describe '.get!' do
    context 'when being called without an assignable' do
      context 'and no setting with that name exists yet' do
        it 'raises a SettingNotFoundError' do
          expect { Setting.get!('foo') }.to raise_error SettingAccessors::SettingNotFoundError
        end
      end

      context 'and a setting with that name already exists' do
        it "returns the setting's value" do
          Setting.create(name: 'foo', value: 'bar')
          expect(Setting.get!('foo')).to eql 'bar'
        end
      end
    end

    context 'when being called with an assignable' do
      let(:assignable) { User.create }
      subject { Setting.get!('foo', assignable) }

      before(:each) do
        Setting.create(name: 'foo', value: 'bar')
        Setting.create(name: 'foo', value: 'baz', assignable: User.create)
      end

      context 'and no assigned setting with that name exists yet' do
        it 'raises a SettingNotFoundError' do
          expect { Setting.get!('foo', assignable) }.to raise_error SettingAccessors::SettingNotFoundError
        end
      end

      context 'and an assigned setting with that name already exists' do
        before(:each) { Setting.create(name: 'foo', value: 'BAM', assignable: assignable) }

        it { is_expected.to eql 'BAM' }
      end
    end
  end

  #----------------------------------------------------------------
  #                             .set
  #----------------------------------------------------------------

  describe '.set' do
    context 'when being called without an assignable' do
      context 'and no corresponding setting already exists' do
        it 'creates a new setting with the given value' do
          expect { Setting.set('foo', 'bar') }.to change { Setting.count }.from(0).to(1)
          expect(Setting.last.value).to eql 'bar'
        end
      end

      context 'and a corresponding setting already exists' do
        let!(:setting) { Setting.create!(name: 'foo', value: 'bar') }

        it 'updates the existing setting' do
          expect { Setting.set('foo', 'baz') }.not_to(change { Setting.count })
          expect(setting.reload.value).to eql 'baz'
        end
      end
    end

    context 'when being called with an assignable' do
      let(:assignable) { User.create }

      context 'and no corresponding setting already exists' do
        it 'creates a new setting with the given value and assignable' do
          expect { Setting.set('foo', 'bar', assignable: assignable) }.to change { Setting.count }.from(0).to(1)
          expect(Setting.last).to have_attributes(assignable: assignable, value: 'bar')
        end
      end

      context 'and a corresponding setting already exists' do
        let!(:setting) { Setting.create!(name: 'foo', value: 'bar', assignable: assignable) }

        it 'updates the existing setting' do
          expect { Setting.set('foo', 'baz', assignable: assignable) }.not_to(change { Setting.count })
          expect(setting.reload.value).to eql 'baz'
        end
      end
    end
  end

  #----------------------------------------------------------------
  #                           .[]=
  #----------------------------------------------------------------

  describe '.[]=' do
    context 'when being called without an assignable' do
      it 'sets the global setting accordingly' do
        expect(Setting).to receive(:set).with('foo', 'bar', assignable: nil)
        Setting['foo'] = 'bar'
      end
    end

    context 'when being called with an assignable' do
      let(:assignable) { User.create }

      it 'sets the assigned setting accordingly' do
        expect(Setting).to receive(:set).with('foo', 'bar', assignable: assignable)
        Setting['foo', assignable] = 'bar'
      end
    end

    context 'when being used with ||=' do
      it "sets the setting value if it doesn't exist yet" do
        expect(Setting.foo).to be nil
        Setting['foo'] ||= 'bar'
        expect(Setting.foo).to eql 'bar'
        Setting['foo'] ||= 'baz'
        expect(Setting.foo).to eql 'bar'

        assignable = User.create

        expect(Setting.foo(assignable)).to be nil
        Setting['foo', assignable] ||= 'bar'
        expect(Setting.foo(assignable)).to eql 'bar'
        Setting['foo', assignable] ||= 'baz'
        expect(Setting.foo(assignable)).to eql 'bar'
      end
    end
  end
end
