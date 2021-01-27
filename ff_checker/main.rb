# frozen_string_literal: true

require 'bundler/setup'
require 'rubygems'
require 'json'
require 'yaml'
require 'twitter'
require 'date'
require 'pp'

# 全処理
class FFChecker
  def initialize
    puts '初期化開始'
    config_file = YAML.load_file('./config.yml')
    api = config_file['api']
    @config_option = config_file['option']
    puts 'config.ymlをロードしました'
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = api['API_Key']
      config.consumer_secret     = api['API_Secret_Key']
      config.access_token        = api['Access_Token']
      config.access_token_secret = api['Access_Token_Secret']
    end
    puts 'Twitter認証終了'
    @yest_follower_file = './yest_follower.json'
    @yest_friend_file   = './yest_frined.json'
    @user_cache_file    = './user_cache.json'
    puts '初期化終了'
  end

  def load_yest_ffs
    puts '前回のFFの読み込み開始'
    @yest_follower_ids = load_json(@yest_follower_file)
    puts "前回のフォロワー: #{@yest_follower_ids.size}人"
    @yest_friend_ids = load_json(@yest_friend_file)
    puts "前回のフォロー中: #{@yest_friend_ids.size}人"
  end

  def get_today_ffs
    puts '現在のFFの取得開始'
    @today_follower = []
    @today_friend   = []
    @client.follower_ids.each_slice(100).each do |slice|
      @client.users(slice).each do |follower|
        @today_follower << extract_user_data(follower)
      end
    end
    puts "現在のフォロワー: #{@today_follower.size}人"
    @client.friend_ids.each_slice(100).each do |slice|
      @client.users(slice).each do |friend|
        @today_friend << extract_user_data(friend)
      end
    end
    puts "現在のフォロー中: #{@today_friend.size}人"
  end

  # get_today_ffsからしか呼び出されない
  def extract_user_data(user)
    # Twitter::UserのUserオブジェクトが渡されるのでその中から
    # ID, SN, 表示名を抽出し、Hashで返す
    user_data = {}
    user_data['id']          = user.id
    user_data['screen_name'] = user.screen_name
    user_data['name']        = user.name
    user_data
  end

  # ユーザーキャッシュの作成。
  def generate_user_cache
    puts 'ユーザーキャッシュの作成開始'
    puts '現在のFFから作成'
    @user_cache = check_duplication(@today_follower, @today_friend, 'id')
    puts '過去のユーザーキャッシュから不足分のみ追加'
    @user_cache = check_duplication(load_json(@user_cache_file), @user_cache, 'id')
    puts 'ユーザーキャッシュを保存'
  end

  # 連想配列を含む配列のマージ
  def check_duplication(source, target, key)
    result = target.dup
    source.each do |source_user|
      target.each_with_index do |target_user, i|
        if target_user[key] == source_user[key]
          break
        elsif i == target.length - 1
          result << source_user
        end
      end
    end
    result
  end

  def extract_user_id(users)
    user_id = []
    users.each do |user|
      user_id << user['id']
    end
    user_id
  end

  def get_user_id_list
    puts 'ユーザーIDのみ抽出したArrayを作成'
    @today_follower_ids = extract_user_id(@today_follower)
    @today_friend_ids = extract_user_id(@today_friend)
  end

  def generate_diff
    @decreased_follower = @yest_follower_ids  - @today_follower_ids # 減ったフォロワー
    @decreased_friend   = @yest_friend_ids    - @today_friend_ids   # 減ったフォロー中
    @increased_follower = @today_follower_ids - @yest_follower_ids  # 増えたフォロワー
    @increased_friend   = @today_friend_ids   - @yest_friend_ids    # 増えたフォロー中
  end

  def get_user_data(user_id)
    @user_cache.each do |user|
      return user if user['id'] == user_id
    end
  end

  def user_data_formatter(user_ids)
    msg = ''
    user_ids.each do |user_id|
      info = get_user_data(user_id)
      msg += "・#{info['name']}(@#{info['screen_name']})\n"
    end
    msg = 'なし' if msg == ''
    msg
  end

  def generate_msg
    " #{Date.today.to_time}
    フォロー中: #{@today_follower_ids.size}人
    フォロワー: #{@today_friend_ids.size}人 \n
    減ったフォロワー: #{@decreased_follower.size}人 \n #{user_data_formatter(@decreased_follower)} \n
    減ったフォロー中: #{@decreased_friend.size}人   \n #{user_data_formatter(@decreased_friend)}   \n
    増えたフォロワー: #{@increased_follower.size}人 \n #{user_data_formatter(@increased_follower)} \n
    増えたフォロー中: #{@increased_friend.size}人   \n #{user_data_formatter(@increased_friend)}   \n
    "
  end

  # 自分宛にDMを送信
  def send_direct_message(msg)
    user = @client.user.id
    @client.create_direct_message(user, msg)
  end

  # JSONの読み込み
  def load_json(path)
    if File.exist?(path)
      File.open(path) do |io|
        return JSON.load(io)
      end
    else
      []
    end
  end

  # JSONの保存
  def save_json(path, obj)
    puts "#{path}に保存しています。"
    open(path, 'w') do |io|
      JSON.dump(obj, io)
    end
    puts "#{path}に保存しました。"
  end

  def main
    load_yest_ffs
    get_today_ffs
    generate_user_cache
    get_user_id_list
    generate_diff
    send_direct_message(generate_msg)
    save_json(@yest_follower_file, @today_follower_ids)
    save_json(@yest_friend_file, @today_friend_ids)
    save_json(@user_cache_file, @user_cache)
  end
end
main = FFChecker.new
main.main
