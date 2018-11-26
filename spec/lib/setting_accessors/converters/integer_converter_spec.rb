# frozen_string_literal: true

describe SettingAccessors::Converters::IntegerConverter do
  subject { described_class }

  with_model 'TestModel' do
    table do |t|
      t.integer :integer_attribute
    end
  end

  it { is_expected.to convert(1).similar_to(TestModel.new).on(:integer_attribute) }
  it { is_expected.to convert(1.0).similar_to(TestModel.new).on(:integer_attribute) }
  it { is_expected.to convert('Oiski').similar_to(TestModel.new).on(:integer_attribute) }
  it { is_expected.to convert(true).similar_to(TestModel.new).on(:integer_attribute) }
  it { is_expected.to convert(false).similar_to(TestModel.new).on(:integer_attribute) }
  it { is_expected.to convert(nil).similar_to(TestModel.new).on(:integer_attribute) }
end
