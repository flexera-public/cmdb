module CMDB::Shell
  # Adapted from pry: https://github.com/pry/pry
  class Text
    COLORS = {
      'black'   => 0,
      'red'     => 1,
      'green'   => 2,
      'yellow'  => 3,
      'blue'    => 4,
      'purple'  => 5,
      'magenta' => 5,
      'cyan'    => 6,
      'white'   => 7
    }.freeze

    def initialize(plain)
      @plain = plain
      trap('SIGWINCH') { @width = nil } unless @plain
    end

    COLORS.each_pair do |color, value|
      define_method color do |text|
        @plain && text || "\033[0;#{30+value}m#{text}\033[0m"
      end

      define_method "bright_#{color}" do |text|
        @plain && text || "\033[1;#{30+value}m#{text}\033[0m"
      end
    end

    # Remove any color codes from _text_.
    #
    # @param  [String, #to_s] text
    # @return [String] _text_ stripped of any color codes.
    def strip_color(text)
      text.to_s.gsub(/\e\[.*?(\d)+m/ , '')
    end

    # Returns _text_ as bold text for use on a terminal.
    #
    # @param [String, #to_s] text
    # @return [String] _text_
    def bold(text)
      @plain && text || "\e[1m#{text}\e[0m"
    end

    # Returns `text` in the default foreground colour.
    # Use this instead of "black" or "white" when you mean absence of colour.
    #
    # @param [String, #to_s] text
    # @return [String]
    def default(text)
      text.to_s
    end
    alias_method :bright_default, :bold

    # @return [Integer] screen width (number of columns)
    def width
      if @plain
        65_535
      else
        @width ||= Integer(`stty size`.chomp.split(/ +/)[1]) rescue 80
      end
    end
  end
end
