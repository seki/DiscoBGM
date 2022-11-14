require 'discordrb'

# overwrite play_internal, encode_file
module Discordrb::Voice
  class VoiceBot
    def play_internal
      count = 0
      @playing = true

      # Default play length (ms), will be adjusted later
      @length = IDEAL_LENGTH
      
      origin = Time.now
      self.speaking = true
      loop do
        break unless @playing

        count += 1

        # If we should skip, get some data, discard it and go to the next iteration
        if @skips.positive?
          @skips -= 1
          yield
          next
        end

        # Track packet count, sequence and time (Discord requires this)
        increment_packet_headers

        # Get packet data
        buf = yield

        # Stop doing anything if the stop signal was sent
        break if buf == :stop

        # Proceed to the next packet if we got nil
        next unless buf

        # Send the packet
        begin
          sleep(origin + (0.001 * IDEAL_LENGTH * count) - Time.now)
        rescue ArgumentError
          Discordrb::LOGGER.warn('Audio encoding and sending together took longer than Discord expects one packet to be (20 ms)! This may be indicative of network problems.')
        end
        @udp.send_audio(buf, @sequence, @time)

        # Set the stream time (for tracking how long we've been playing)
        @stream_time = count * @length / 1000

        # If paused, wait
        sleep 0.1 while @paused
      end

      @bot.debug('Sending five silent frames to clear out buffers')

      5.times do
        increment_packet_headers
        @udp.send_audio(Encoder::OPUS_SILENCE, @sequence, @time)

        # Length adjustments don't matter here, we can just wait 20ms since nobody is going to hear it anyway
        sleep IDEAL_LENGTH / 1000.0
      end

      @bot.debug('Performing final cleanup after stream ended')

      # Final clean-up
      stop_playing

      # Notify any stop_playing methods running right now that we have actually stopped
      @has_stopped_playing = true
    end
  end

  class Encoder
    def encode_file(file, options = '')
      command = "#{ffmpeg_command} -loglevel 0 -stream_loop -1 -i \"#{file}\" #{options} -f s16le -ar 48000 -ac 2 #{filter_volume_argument} pipe:1"
      IO.popen(command)
    end
  end
end
