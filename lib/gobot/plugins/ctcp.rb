module GoBot
  module Plugin
    class CoreCTCP
      include Cinch::Plugin

      ctcp :version
      ctcp :time
      ctcp :ping
      ctcp :clientinfo

      def ctcp_version(m)
        if @bot.config.source_url
          m.ctcp_reply "GoBot v#{VERSION} using Cinch v#{Cinch::VERSION} | #{@bot.config.source_url}"
        else
          m.ctcp_reply "GoBot v#{VERSION} using Cinch v#{Cinch::VERSION}"
        end
      end

      def ctcp_time(m)
        m.ctcp_reply Time.now.strftime('%a %b %d %H:%M:%S %Z %Y')
      end

      def ctcp_ping(m)
        m.ctcp_reply m.ctcp_args.join(' ')
      end

      def ctcp_clientinfo(m)
        m.ctcp_reply 'PING VERSION TIME CLIENTINFO'
      end
    end
  end
end
