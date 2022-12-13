require 'webmock/rspec'

def run_kobiton_action
  return Fastlane::FastFile.new.parse("lane :test do
    kobiton(
      api_key: 'api_key',
      app_id: 12345,
      file: '../spec/fixtures/app.apk',
      username: 'username',
    )
  end").runner.execute(:test)
end

def mock_authorization
  base64_authorization = Base64.strict_encode64("username:api_key")
  return "Basic #{base64_authorization}"
end

def mock_generate_upload_url
  stub_request(:post, "https://api.kobiton.com/v1/apps/uploadUrl").
    with(
      body: {
        'appId' => '12345',
        "filename" => 'app.apk'
      },
      headers: {
        'Accept' => 'application/json',
        'Authorization' => mock_authorization,
        'Content-Type' => 'application/x-www-form-urlencoded',
        'Host' => 'api.kobiton.com'
      }
    ).
    to_return(
      status: 200,
      body: '{
        "url": "s3_url",
        "appPath": "kobiton_app_path"
      }'
    )
end

def mock_s3_upload
  stub_request(:put, "http://s3_url/").
    with(
      headers: {
        'Content-Type' => 'application/octet-stream',
        'Host' => 's3_url'
      }
    ).
    to_return(status: 200, body: "true", headers: {})
end

def mock_create_application
  stub_request(:post, "https://api.kobiton.com/v1/apps").
    with(
      body: {
        "appPath" => "kobiton_app_path",
        "filename" => "app.apk"
      },
      headers: {
        'Authorization' => mock_authorization,
        'Content-Type' => 'application/x-www-form-urlencoded',
        'Host' => 'api.kobiton.com'
      }
    ).
    to_return(
      status: 200,
      body: '{
        "versionId": 12345
      }'
    )
end
