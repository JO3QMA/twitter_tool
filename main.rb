require 'bundler/setup'
require 'rubygems'
require 'yaml'
require 'twitter'
require 'pp'

class Favotter
  def initialize
    yaml_file = YAML.load_file('./config.yml')
    api = yaml_file['api']
    @option = yaml_file['option']
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = api['API_Key']
      config.consumer_secret     = api['API_Secret_Key']
      config.access_token        = api['Access_Token']
      config.access_token_secret = api['Access_Token_Secret']
    end
    @last_tweet_file = './tweet_id.txt'
    if File.exist?(@last_tweet_file)
      @last_tweet = File.read(@last_tweet_file).to_i
    else
      @last_tweet = nil
    end
    p @last_tweet
    @tweet_list = []
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
    # since_idの挙動怪しすぎて指定しないほうがいい説まである
    result = @client.search(query, result_type: result_type, exclude: 'retweets', since_id: since_id, lang: lang, count: count).take(count)
    result.each do |tweet|
      @tweet_list.push tweet.id
    end
    p '終了'
  end

  def fav_tweet
    @tweet_list.each do |tweet|
      @client.favorite(tweet)
      p tweet
      sleep @option['cooldown']
    end
  end

  def write_last_id
    unless @tweet_list.size == 0
      File.write(@last_tweet_file, @tweet_list[0])
    end
  end

  def main
    search_tweet
    fav_tweet
    write_last_id
  end
end
test = Favotter.new
test.main
