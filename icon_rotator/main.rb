# frozen_string_literal: true

# require 'bundler/setup'
require 'rubygems'
require 'yaml'
require 'twitter'
require 'date'
require 'pp'
require 'rmagick'

class IconRotator
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
    @icon_path = @config_option['icon_path']
    puts '初期化終了'
  end

  def get_today_date
    current_date = Date.today
    today_date = current_date.day.to_f
    current_month_last_date = Date.new(current_date.year, current_date.month, -1).day.to_f
    (today_date / current_month_last_date) * 360.to_f
  end

  def rotate_icon(file, degree)
    img = Magick::Image.read(file).first
    img.rotate!(degree)
    img
  end

  def crop_icon(image, side_length)
    img = image.crop(0, 0, side_length, side_length)
    img.write('test.png')
  end

  def upload_icon
    @client.update_profile_image(File.open('test.png'))
  end

  def main
    degree = get_today_date

    crop_icon(rotate_icon(@icon_path, degree), 512)
    upload_icon
  end
end
main = IconRotator.new
main.main
