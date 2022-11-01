require 'fastlane/action'

describe Fastlane::Actions::KobitonAction do
  describe '#parse_name' do
    parse_name = Fastlane::Actions::KobitonAction.method(:parse_name)

    it 'Returns name unchanged if it has no special characters' do
      expect(parse_name.call('new name 123')).to eq('new name 123')
    end

    it 'Does not filter . + _ or -' do
      expect(parse_name.call('name with . + _ -')).to eq('name with . + _ -')
    end

    it 'Converts all other special characers to dashes -' do
      expect(parse_name.call('name/with/slashes')).to eq('name-with-slashes')
    end

    it 'cuts off characters after 255' do
      input = 'x' * 300
      expected = 'x' * 255

      expect(parse_name.call(input)).to eq(expected)
    end
  end
end
