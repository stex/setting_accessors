# frozen_string_literal: true

describe SettingAccessors::Converters::StringConverter do
  subject { described_class }

  with_model 'TestModel' do
    table do |t|
      t.string :string_attribute
    end
  end

  it { is_expected.to convert(1).similar_to(TestModel.new).on(:string_attribute) }
  it { is_expected.to convert('Oiski').similar_to(TestModel.new).on(:string_attribute) }
  it { is_expected.to convert(true).to('true') }
  it { is_expected.to convert(false).to('false') }
  it { is_expected.to convert(nil).similar_to(TestModel.new).on(:string_attribute) }
end
