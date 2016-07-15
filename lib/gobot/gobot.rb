require 'gobot/includes'

module GoBot
  class GoBot
    def initialize
      @bot = Configuration.parse

      if @bot.config.logging
        logfile = storage(File.join('logs', 'irc.log'))
        @bot.loggers << Cinch::Logger::FormattedLogger.new(File.open(logfile, 'w+'))
      end
    end

    def start
      @bot.start
    end

    def storage(path = nil)
      return File.join(@bot.config.storage, path) if path

      @bot.config.storage
    end
  end
end
