require 'melonsmasher/pokemon-go-status'

module GoBot
  module Plugin
    class GoStatus
      include Cinch::Plugin

      def initialize(*args)
        super

        @last_check = {exit_code: -1}
        @chans = []
        @bot.config.channels.each do |chan|
          @chans << chan.downcase
        end
        Timer(10, method: :check_status, shots: 1)
      end
  
      timer 60, method: :check_status
 
      match Regexp.new('gostatus'), method: :cmd_status
      def cmd_status(m)
        m.reply(fmt_status(@last_check))
      end

      def on_status_change
        status = fmt_status(@last_check)
        @chans.each do |c|
          Channel(c).send(status)
        end
      end

      def check_status(try_again = true)
        pg = PokemonGoStatus::Status.new
        begin
          status = pg.get_server_status
        rescue StandardError => e
          info e.to_s
          return
        end

        if try_again && status[:exit_code] == 3
          check_status(false)
          return
        end

        send_cb = status[:exit_code] != @last_check[:exit_code]
        @last_check = status
        on_status_change if send_cb
      end

      def fmt_status(h)
        "[#{fmt_exit_code(h[:exit_code])}] #{fmt_available(h[:available])} - average response time: #{h[:avg_ms]}ms"
      end

      def fmt_exit_code(exit_code)
        return Format(:green, 'up') if exit_code == 0
        return Format(:orange, 'slow') if exit_code == 1
        return Format(:red, 'down') if exit_code == 2
        Format(:grey, "error #{exit_code}")
      end

      def fmt_available(avl)
        return Format(:green, 'available') if avl
        Format(:red, 'unavailable')
      end
    end
  end
end
