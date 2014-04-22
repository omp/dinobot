#!/usr/bin/env ruby

require_relative 'dinobot'

bot = Dinobot::Bot.new('irc.example.org', 6667, 'dinobot') do
  join '#dinobot'

  load_module :admin
  load_module :config
  load_module :lastfm
  load_module :test

  @modules[:admin].add('dinobot.example.org')
  @modules[:lastfm].setapikey('keyhere')

  add_alias 'np', 'lastfm np'
  add_alias 'song', 'lastfm np'
end

loop do
  bot.run
end
