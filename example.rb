#!/usr/bin/env ruby

require_relative 'dinobot'

bot = Dinobot::Bot.new('irc.example.org', 6667, 'dinobot') do
  join '#dinobot'

  load_module :test
end

loop do
  bot.run
end
