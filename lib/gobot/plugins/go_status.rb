require 'melonsmasher/pokemon-go-status'

module GoBot
  module Plugin
    class GoStatus
      EXIT_CODE_UP = 0
      EXIT_CODE_SLOW = 1
      EXIT_CODE_DOWN = 2
      EXIT_CODE_RANGE = (EXIT_CODE_UP..EXIT_CODE_DOWN)

      include Cinch::Plugin

      def initialize(*args)
        super
        @announce = [EXIT_CODE_UP, EXIT_CODE_DOWN]
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

        send_cb = status[:exit_code] != @last_check[:exit_code] && announce?(status[:exit_code])
        @last_check = status
        on_status_change if send_cb
        log fmt_status(@last_check)
      end

      def fmt_status(h)
        "[#{fmt_exit_code(h[:exit_code])}] #{fmt_available(h[:available])} - response time: #{h[:avg_ms]}ms"
      end

      def fmt_exit_code(exit_code)
        return Format(:green, 'up') if exit_code == EXIT_CODE_UP
        return Format(:orange, 'slow') if exit_code == EXIT_CODE_SLOW
        return Format(:red, 'down') if exit_code == EXIT_CODE_DOWN
        Format(:grey, "error #{exit_code}")
      end

      def fmt_available(avl)
        return Format(:green, 'available') if avl
        Format(:red, 'unavailable')
      end

      def announce?(exit_code, check_last = true)
        (check_last && announce?(@last_check[:exit_code], false) || !check_last) && (@announce.include?(exit_code) || !EXIT_CODE_RANGE.include?(exit_code))
      end
    end
  end
end
