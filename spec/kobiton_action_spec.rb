require 'fastlane/action'
require 'webmock/rspec'
require 'test_helpers'

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

  describe '#run' do
    it 'Prints all feedback messages for successful run.' do
      expect(Fastlane::UI).to receive(:message).with("Getting S3 upload URL...")
      expect(Fastlane::UI).to receive(:message).with("Got S3 upload URL.")
      expect(Fastlane::UI).to receive(:message).with("Uploading the build to Amazon S3 storage...")
      expect(Fastlane::UI).to receive(:message).with("Successfully uploaded the build to Amazon S3 storage.")
      expect(Fastlane::UI).to receive(:message).with("Successfully uploaded the build to Kobiton!")

      mock_generate_upload_url
      mock_s3_upload
      mock_create_application

      result = run_kobiton_action
    end
  end
end
