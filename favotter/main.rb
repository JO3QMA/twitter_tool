require 'bundler/setup'
require 'rubygems'
require 'yaml'
require 'twitter'
require 'pp'

# 全処理
class TweetController
  # 初期化
  def initialize
    puts '初期化開始'
    puts 'config.ymlをロード'
    yaml_file = YAML.load_file('./config.yml')
    api = yaml_file['api']
    @option = yaml_file['option']
    puts 'Twitter認証開始'
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = api['API_Key']
      config.consumer_secret     = api['API_Secret_Key']
      config.access_token        = api['Access_Token']
      config.access_token_secret = api['Access_Token_Secret']
    end
    puts '最終ツイートID読み込み'
    @last_tweet_file = './tweet_id.txt'
    if File.exist?(@last_tweet_file)
      @last_tweet = File.read(@last_tweet_file).to_i
      puts "最終ツイートID: #{@last_tweet}"
    else
      @last_tweet = 0
      puts '最終ツイートIDが読み込めませんでした。IDを0に設定します。'
    end
    @id_list = []
    @tweet_list = []
    puts '初期化終了'
  end

  def search_tweet
    p '検索開始'
    query = @option['query']
    count = @option['count']
    result_type = @option['result_type']
    lang = @option['lang']
    since_id = @last_tweet
    p since_id
    p '取得開始'
    result = @client.search(query, result_type: result_type, exclude: 'retweets', since_id: since_id, lang: lang,
                                   count: count).take(count)
    result.reverse_each do |tweet|
      unless @id_list.include?(tweet.user.id)
        @tweet_list.push tweet.id
        @id_list.push tweet.user.id
      end
    end
    pp @tweet_list.size
    p '終了'
  end

  def fav_tweet
    @tweet_list.each do |tweet|
      @client.favorite(tweet)
      p tweet
      sleep @option['cooldown']
      sleep rand(30)
    end
  end

  def write_last_id
    File.write(@last_tweet_file, @tweet_list.last) unless @tweet_list.size == 0
  end

  def main
    search_tweet
    fav_tweet
    write_last_id
  end
end
test = TweetController.new
test.main
