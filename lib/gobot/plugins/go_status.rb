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
        @reporting = false
        @report_next = false
        @announce = [EXIT_CODE_UP, EXIT_CODE_DOWN]
        @last_check = {exit_code: -1}
        @chans = []
        @bot.config.channels.each do |chan|
          @chans << chan.downcase
        end
        Timer(10, method: :check_status, shots: 1)
      end
  
      timer 120, method: :check_status
 
      match Regexp.new('gostatus'), method: :cmd_status
      def cmd_status(m)
        m.reply(fmt_status(@last_check))
      end

      match Regexp.new('goalert'), method: :cmd_report_next
      def cmd_report_next(m)
        if @reporting
          m.reply("Continuous reporting is enabled, cannot do one time reports.")
          return
        end

        m.reply("I will report when the status changes.")
        @report_next = true
      end

      def on_status_change
        if @reporting || @report_next
          status = fmt_status(@last_check)
          @chans.each do |c|
            Channel(c).send(status)
          end

          if @report_next
            @report_next = false
          end
        end
      end

      def check_status(try_again = true)
        pg = PokemonGoStatus::Status.new
        begin
          status = pg.get_server_status
        rescue StandardError => e
          info e.to_s
          status = {exit_code: EXIT_CODE_DOWN, reason: e.class.name, avg_ms: -1, available: false}
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
        ms = h[:avg_ms].nil? ? 'unknown' : "#{h[:avg_ms]}ms"
        append = h.key?(:reason) ? ' - error reason: ' + h[:reason] : ''
        "[#{fmt_exit_code(h[:exit_code])}] #{fmt_available(h[:available])} - response time: #{ms}#{append}"
      end

      def fmt_exit_code(exit_code)
        return Format(:green, ' up ') if exit_code == EXIT_CODE_UP
        return Format(:orange, 'slow') if exit_code == EXIT_CODE_SLOW
        return Format(:red, 'down') if exit_code == EXIT_CODE_DOWN
        Format(:grey, "error #{exit_code}")
      end

      def fmt_available(avl)
        return Format(:green, 'available') if avl
        Format(:red, 'unavailable')
      end

      def announce?(exit_code, check_last = true)
        @last_check[:exit_code] != EXIT_CODE_SLOW && exit_code != EXIT_CODE_SLOW
        # (check_last && announce?(@last_check[:exit_code], false) || !check_last) && (@announce.include?(exit_code) || !EXIT_CODE_RANGE.include?(exit_code))
      end
    end
  end
end
