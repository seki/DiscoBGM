require_relative 'my_voice'

if __FILE__ == $0

  bot = Discordrb::Commands::CommandBot.new token: ENV['DISCORD_BOT_BGM'], prefix: '!'

  bot.command(:connect) do |event|
    pp event.user.discriminator
    return unless ["4114", "8747"].include?(event.user.discriminator)

    channel = event.user.voice_channel
    next "You're not in any voice channel!" unless channel
    bot.voice_connect(channel)
    "Connected to voice channel: #{channel.name}"
  end

  bot.command(:play) do |event|
    return unless ["4114", "8747"].include?(event.user.discriminator)

    voice_bot = event.voice
    voice_bot.volume = 0.2
    voice_bot.play_file('data/loop_bgm_5m.mp3')
  end

  bot.run
end