require 'net/http'
require 'json'

require_relative 'base'
require_relative '../core/store'

module Dinobot
  module Module
    class LastFM < Base
      def initialize(bot)
        super

        @store = Dinobot::Core::Store.new('data/lastfm.db')

        @commands << :np << :topartists << :setdefault << :getdefault
      end

      def setapikey(key)
        @store[:apikey] = key
        @store.save
      end

      def setdefault(m, args)
        return unless @bot.modules[:admin].is_admin?(m.user)
        return if args.nil?

        account = args.scan(/\w+/).first

        @store[m.channel] = {} unless @store[m.channel]
        @store[m.channel][:default] = account
        @store.save

        m.respond [:say, m.channel,
          "Set default LastFM account for #{m.channel} to #{account}."]
      end

      def getdefault(m, args)
        return unless @bot.modules[:admin].is_admin?(m.user)
        return unless @store[m.channel]

        m.respond [:say, m.channel, @store[m.channel][:default]]
      end

      def np(m, args)
        return unless @store[:apikey]

        if args.empty?
          account = @store[m.channel][:default] if @store[m.channel]

          return if account.nil?
        else
          account = args.scan(/\w+/).first
        end

        response = Net::HTTP.get_response(URI("http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=#{account}&api_key=#{@store[:apikey]}&format=json"))

        if response.code == '200'
          response_hash = JSON.parse(response.body)

          if response_hash.has_key?('error')
            m.respond [:say, m.channel,
              "np (#{account}): no such user found."]
            return
          end

          if response_hash['recenttracks'].has_key?('track') &&
            response_hash['recenttracks']['track'].first.has_key?('@attr') &&
            response_hash['recenttracks']['track'].first['@attr'].has_key?('nowplaying')

            m.respond [:say, m.channel,
              "np (#{account}): #{response_hash['recenttracks']['track'].first['artist']['#text']} - #{response_hash['recenttracks']['track'].first['name']}"]
            return
          end

          m.respond [:say, m.channel, "np (#{account}): nothing."]
        end
      end

      def topartists(m, args)
        return unless @store[:apikey]

        if args.empty?
          account = @store[m.channel][:default] if @store[m.channel]

          return if account.nil?
        else
          account = args.scan(/\w+/).first
        end

        response = Net::HTTP.get_response(URI("http://ws.audioscrobbler.com/2.0/?method=user.gettopartists&user=#{account}&limit=8&api_key=#{@store[:apikey]}&format=json"))

        if response.code == '200'
          response_hash = JSON.parse(response.body)

          if response_hash.has_key?('error')
            m.respond [:say, m.channel,
              "topartists (#{account}): no such user found."]
            return
          end

          if response_hash['topartists'].has_key?('artist')
            m.respond [:say, m.channel,
              "topartists (#{account}): #{response_hash['topartists']['artist'].map { |x| x['name'] }.join(', ')}"]
            return
          end

          m.respond [:say, m.channel, "topartists (#{account}): none."]
        end
      end
    end
  end
end
