module CMDB
  class Source::Network < Source
    # @param [URI] uri
    # @param [String] dot-notation prefix of all keys
    def initialize(uri, prefix)
      @uri = uri
      @prefix = prefix
    end

    private

    # Perform a GET. On 2xx, return the response body as a String.
    # On 3xx or 4xx return an Integer status code. On 5xx, retry up to
    # the specified number of times, then return an Integer status code.
    #
    # @param [String] path
    # @return [Integer,String]
    def http_get(path, query:nil, retries:3)
      @http ||= Net::HTTP.start(@uri.host, @uri.port)
      uri = @uri.dup
      uri.path = path
      uri.query = query unless query.nil? || query.empty?

      request = Net::HTTP::Get.new uri
      response = @http.request request

      case response.code.to_i
      when 200..299
        response.body
      when 500..599
        if retries > 0
          http_get(path, query:query, retries:retries-1)
        else
          response.code.to_i
        end
      else
        response.code.to_i
      end
    end

    # Perform a PUT. JSON-encode request entity unless it is already a String.
    # Return status code from HTTP response.
    #
    # @return [Integer] HTTP status code
    # @param [String] path
    # @param [String,Hash,Array,Numeric,Boolean] entity
    def http_put(path, entity)
      entity = JSON.dump(entity) unless entity.is_a?(String)

      @http ||= Net::HTTP.start(@uri.host, @uri.port)
      uri = @uri.dup
      uri.path = path

      request = Net::HTTP::Put.new uri
      request.body = entity
      response = @http.request request

      response.code.to_i
    end

    # Perform a DELETE.
    # Return status code from HTTP response.
    #
    # @return [Integer] HTTP status code
    # @param [String] path
    def http_delete(path)
      @http ||= Net::HTTP.start(@uri.host, @uri.port)
      uri = @uri.dup
      uri.path = path

      request = Net::HTTP::Delete.new uri
      response = @http.request request

      response.code.to_i
    end

    # Attempt to parse str as a JSON document or fragment. Fragments include
    # "bare" numbers, strings, `null`, `true`, `false` that occur outside of
    # a dictionary or array context, but exclude anything that is syntactically
    # invalid JSON (e.g. an unquoted string).
    #
    # @return [Object] JSON-parsed object, or the original string if parse fails
    # @param [String] str
    def json_parse(str)
      JSON.load(str)
    rescue JSON::ParserError
      str
    end

    # Convert dotted notation to slash-separated notation without an initial
    # slash. Remove prefix if appropriate; raise an error if the key name
    # does not begin with this source's prefix.
    def dot_to_slash(key)
      unless prefixed?(key)
        raise CMDB::BadKey.new(key, "Keys of this source must begin with #{prefix}.")
      end
      pieces = key.split(CMDB::SEPARATOR)
      pieces.shift
      pieces.join('/')
    end

    # Convert a slash-separated URI path or subpath to dotted notation. If there is an initial
    # slash, discard it. Prepend source's prefix to key name if not already present.
    def slash_to_dot(path)
      pieces = path.split('/')
      pieces.shift if pieces[0].empty?
      pieces.unshift(prefix) unless prefix.nil? || pieces[0] == prefix
      pieces.join(CMDB::SEPARATOR)
    end
  end
end
