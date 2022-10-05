require 'fastlane/action'
require 'webmock/rspec'

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

      base64_authorization = Base64.strict_encode64("username:api_key")
      authorization = "Basic #{base64_authorization}"

      stub_request(:post, "https://api.kobiton.com/v1/apps/uploadUrl").
        with(
          body: { 'appId' => '12345', "filename" => 'app.apk' },
          headers: {
         'Accept' => 'application/json',
         'Authorization' => authorization,
         'Content-Type' => 'application/x-www-form-urlencoded',
         'Host' => 'api.kobiton.com',
         'User-Agent' => 'rest-client/2.1.0 (darwin21.3.0 x86_64) ruby/2.6.10p210'
          }
        ).
        to_return(status: 200, body: '{
          "url": "s3_url",
          "appPath": "kobiton_app_path"
        }', headers: {})

      stub_request(:put, "http://s3_url/").
        with(
          headers: {
            'Content-Type' => 'application/octet-stream',
            'Host' => 's3_url',
            'User-Agent' => 'rest-client/2.1.0 (darwin21.3.0 x86_64) ruby/2.6.10p210',
            'X-Amz-Tagging' => 'unsaved=true'
          }
        ).
        to_return(status: 200, body: "true", headers: {})

      stub_request(:post, "https://api.kobiton.com/v1/apps").
        with(
          body: { "appPath" => "kobiton_app_path", "filename" => "app.apk" },
          headers: {
         'Accept' => '*/*',
         'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
         'Authorization' => 'Basic dXNlcm5hbWU6YXBpX2tleQ==',
         'Content-Length' => '41',
         'Content-Type' => 'application/x-www-form-urlencoded',
         'Host' => 'api.kobiton.com',
         'User-Agent' => 'rest-client/2.1.0 (darwin21.3.0 x86_64) ruby/2.6.10p210'
          }
        ).
        to_return(status: 200, body: '{
        "versionId": 12345
      }', headers: {})

      result = Fastlane::FastFile.new.parse("lane :test do
        kobiton(
          api_key: 'api_key',
          app_id: 12345,
          file: '../spec/resources/app.apk',
          username: 'username',
        )
      end").runner.execute(:test)
    end
  end
end
