#!/usr/bin/env ruby

# frozen_string_literal: true

require 'twitter'
require 't'
require 'thor'
require 'json'
require 'fileutils'
require 'yaml'
require 'ruby-progressbar'

module TweetHelper
  def dump_tweet(tweet)
    attrs = {}
    tweet.attrs.each do |key, value|
      case key
      when :text
        attrs[:full_text] = tweet.full_text
      when :created_at
        attrs[:created_at] = tweet.created_at.iso8601
      else
        attrs[key] = value
      end
    end
    attrs
  end
end

class TweetClient
  include T::Collectable
  def initialize(cli_config)
    @client =
      Twitter::REST::Client.new do |config|
        config.consumer_key = cli_config['consumer_key']
        config.consumer_secret     = cli_config['consumer_secret']
        config.access_token        = cli_config['access_token']
        config.access_token_secret = cli_config['access_token_secret']
      end
    @user = cli_config['user']
  end

  def user_fav_count
    @client.user(@user).favourites_count
  end

  def fav_tweets(count)
    opts = {}
    collect_with_count(count) do |count_opts|
      @client.favorites(@user, count_opts.merge(opts))
    end
  end
end

module CliHelper
  def parseConfig(conf_path)
    if File.exist?(conf_path)
      cli_config = YAML.safe_load(File.read(conf_path))
      TweetClient.new(cli_config)
    else
      puts <<~EOF
        #{conf_path} not found!
        Please run`#{File.basename(__FILE__)} init` to create the config file first.
      EOF
    end
  end
end

class Cli < Thor
  include TweetHelper
  include CliHelper
  def initialize(*args)
    super
    @conf_path = File.join(__dir__, 'config.yaml')
  end

  desc 'init', <<~EOF
    Initialize account information and save it to config.yaml under the same folder of this script.
    Developer credentials can be created/found in https://apps.twitter.com/
  EOF
  method_option :consumer_key,
                required: true
  method_option :consumer_secret,
                required: true
  method_option :access_token,
                required: true
  method_option :access_token_secret,
                required: true
  method_option :username,
                required: true,
                desc: 'Your twitter username'
  def init
    File.open(@conf_path, 'w') { |f| f.write(options.to_hash.to_yaml) }
  end

  desc 'meta', 'Archives meta data of favorite tweets for the user sepcified in config.yaml'
  method_option :count,
                type: :numeric,
                default: 0,
                aliases: '-c',
                desc: 'Number of favorite tweets to archive. 0 means the total of user\'s favorites available by Twitter API'
  method_option :output_dir,
                type: :string,
                aliases: '-o',
                default: 'output',
                desc: 'Output dir'
  method_option :organize_output,
                type: :boolean,
                aliases: '--organize',
                default: true,
                desc: 'If enabled, organize output as <output_dir>/year/month/tweet_id. Otherwise <output_dir>/tweet_id.'
  def meta
    @client = parseConfig(@conf_path)
    return if @client.nil?

    count = if options[:count].positive?
              options[:count]
            else
              @client.user_fav_count
            end
    output_dir = options[:output_dir]
    should_organize_output = options[:organize_output]

    progressbar = ProgressBar.create(title: 'Favorites', total: count)
    @client.fav_tweets(count).each do |tweet|
      progressbar.increment
      dir_for_months = if should_organize_output
                         File.join(tweet.created_at.strftime('%Y'), tweet.created_at.strftime('%m'))
                       else
                         ''
                       end
      dir = File.join(output_dir, dir_for_months, tweet.id.to_s)
      file = File.join(dir, 'tweet.json')
      FileUtils.mkdir_p(dir)
      File.open(file, 'w') do |f|
        f.puts JSON.pretty_generate(dump_tweet(tweet))
      end
    end
  end
end

Cli.start(ARGV)
