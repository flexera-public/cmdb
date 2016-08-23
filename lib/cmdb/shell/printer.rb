module CMDB::Shell
  class Printer
    def initialize(out=STDOUT, err=STDERR)
      @out = out
      @err = err
      @c = Text.new(!@out.tty?)
    end

    # Print an informational message.
    def info(str)
      @out.puts @c.white(str)
    end

    # Print an error message.
    def error(str)
      @err.puts @c.bright_red(str)
      self
    end

    # Display a single CMDB value.
    def value(obj)
      @out.puts '  ' + color_value(obj, 76)
      self
    end

    # Display a table of keys/values.
    def keys_values(h, prefix:nil)
      wk = h.keys.inject(0) { |ax, e| e.size > ax ? e.size : ax }
      wv = h.values.inject(0) { |ax, e| es = e.inspect.size; es > ax ? es : ax }
      width = @c.tty_columns
      half = width / 2 - 2
      wk = [wk, half].min
      wv = [wv, half].min
      re = (width - wk - wv)
      wv += re if re > 0

      h.each do |k, v|
        @out.puts format('  %s%s', color_key(k, wk+1, prefix:prefix), color_value(v, wv))
      end

      self
    end

    # @return [String] human-readable CMDB prompt
    def prompt(cmdb)
      pwd = '/' + cmdb.pwd.join('/')
      pwd = pwd[0...40] + '...' if pwd.size >= 40
      'cmdb:' +
        @c.green(pwd) +
        @c.default('> ')
    end

    private

    # Colorize a key and right-pad it to fit a minimum size. Append a ':'
    # to make it YAML-esque.
    def color_key(k, size, prefix:nil)
      v = k.to_s
      v.sub(prefix, '') if prefix && v.index(prefix) == 0
      suffix = ':'
      if v.size + 1 > size
        v = v[0...size-4]
        suffix = '...:'
      end
      pad = [0, size - v.size - suffix.size].max
      @c.blue(v) << suffix << (' ' * pad)
    end

    # Colorize a value and right-pad it to fit a minimum size.
    def color_value(v, size)
      case v
      when Symbol
        vv = v.to_s
      when nil
        vv = 'null'
      else
        vv = v.inspect
      end
      vv << (' ' * [0, size - vv.size].max)

      case v
      when Symbol
        @c.blue(vv)
      when String
        @c.bright_green(vv)
      when Numeric
        @c.bright_magenta(vv)
      when true, false
        @c.cyan(vv)
      when nil
        @c.yellow(vv)
      when Array
        str = @c.bold('[')
        remain = size-2
        v.each_with_index do |e, i|
          ei = e.inspect
          if remain >= ei.size + 3
            str << ',' if i > 0
            str << color_value(e, ei.size)
          elsif remain >= 3
            str << @c.default('...')
            remain = 1
          end
          remain -= (ei.size + 1)
        end
        str << @c.bold(']')

        str
      else
        @c.default(vv)
      end

    end
  end
end
