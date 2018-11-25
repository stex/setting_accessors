# frozen_string_literal: true

describe SettingAccessors::Converters::PolymorphicConverter do
  subject { described_class }

  it { is_expected.to convert(1).to(1) }
  it { is_expected.to convert('Oiski').to('Oiski') }
  it { is_expected.to convert(true).to(true) }
  it { is_expected.to convert(false).to(false) }
  it { is_expected.to convert(nil).to(nil) }
  it { is_expected.to convert(a: :b).to(a: :b) }
  it { is_expected.to convert([1, 2, 3]).to([1, 2, 3]) }
end
