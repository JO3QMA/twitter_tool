require 'twitter'
require 'yaml'

# TwitterClientクラス
class TwiClient
  def initialize
    # 初期化
    config_file = YAML.load_file('./config.yml')
    api = config_file['api']
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = api['API_Key']
      config.consumer_secret     = api['API_Secret_Key']
      config.access_token        = api['Access_Token']
      config.access_token_secret = api['Access_Token_Secret']
    end
  end

  def client
    @client
  end
end

## てすと