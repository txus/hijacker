module Hijacker
  class Logger < Handler

    def self.cli_options
      Proc.new {
        opt :without_classes, "Don't show classes of objects"
        opt :without_timestamps, "Don't show timestamps"
      }
    end

    ANSI = {:RESET=>"\e[0m", :BOLD=>"\e[1m", :UNDERLINE=>"\e[4m",
            :LGRAY=>"\e[0;37m", :GRAY=>"\e[1;30m",
            :RED=>"\e[31m",
            :GREEN=>"\e[32m", :LGREEN=>"\e[1;32m",
            :YELLOW=>"\e[33m",
            :BLUE=>"\e[34m", :LBLUE=>"\e[1;34m",
            :PURPLE=>"\e[35m", :LPURPLE=>"\e[1;35m",
            :CYAN=>"\e[36m", :LCYAN=>"\e[1;36m",
            :WHITE=>"\e[37m"}

    def handle(method, args, retval, raised, object)
      out = []
      out << ANSI[:BOLD] + ANSI[:UNDERLINE] + "#{Time.now}" unless opts[:without_timestamps]
      out << ANSI[:CYAN] + object[:inspect]
      out << ANSI[:LCYAN] + "(#{object[:class]})" unless opts[:without_classes]
      out << "received"
      out << ANSI[:RED] + ":#{method}"
      unless args.empty?
        out << "with"
        out << args.map do |arg|
          ANSI[:GREEN] + arg[:inspect] + ANSI[:LGREEN] + (opts[:without_classes] ? "" : " (#{arg[:class]})") +
          ANSI[:RESET]
        end.join(', ')
      end
      if raised
        out << "and raised"
        out << ANSI[:BLUE] + raised[:inspect]
        out << ANSI[:LBLUE] + "(#{raised[:class]})" unless opts[:without_classes]
        out << ANSI[:RESET] + "\n"
      else
        out << "and returned"
        out << ANSI[:BLUE] + retval[:inspect]
        out << ANSI[:LBLUE] + "(#{retval[:class]})" unless opts[:without_classes]
        out << ANSI[:RESET] + "\n"
      end
      stdout.print out.join("#{ANSI[:RESET]} ")
    end

    private

    def stdout
      $stdout
    end

  end

end
