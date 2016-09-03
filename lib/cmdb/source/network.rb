module CMDB
  # Abstract base class for sources that are backed by an HTTP k/v store.
  # Contains reusable HTTP request logic.
  class Source::Network < Source
    # @return [URI] HTTP base location of this source (minus path)
    attr_reader :http_url

    # Construct a new HTTP source. The logical URI is transformed into an
    # HTTP base URL by preserving the hostname, overriding the port (unless
    # the URI already has a specific port), replacing the scheme with http
    # and eliminating the path.
    #
    # @param [String,URI] uri logical description of this source
    # @param [Integer] port default HTTP port if not specified in URI
    # @param [String] dot-notation prefix of all keys
    def initialize(uri, port, prefix)
      super(uri, prefix)
      @http_url = URI.parse("http://%s:%s" % [@uri.host, @uri.port || port])
    end

    private

    # Perform a GET. On 2xx, return the response body as a String.
    # On 3xx or 4xx return an Integer status code. On 5xx, retry up to
    # the specified number of times, then return an Integer status code.
    #
    # @param [String] path
    # @return [Integer,String]
    def http_get(path, query:nil, retries:3)
      @http ||= Net::HTTP.start(@http_url.host, @http_url.port)
      url = @http_url.dup
      url.path = path
      url.query = query unless query.nil? || query.empty?

      request = Net::HTTP::Get.new url
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

      @http ||= Net::HTTP.start(@http_url.host, @http_url.port)
      url = @http_url.dup
      url.path = path

      request = Net::HTTP::Put.new url
      request.body = entity
      response = @http.request request

      response.code.to_i
    end

    # Perform a DELETE.
    # Return status code from HTTP response.
    #
    # @return [Integer] HTTP status code
    # @param [String] path
    def http_delete(path, query:nil)
      @http ||= Net::HTTP.start(@http_url.host, @http_url.port)
      url = @http_url.dup
      url.path = path
      url.query = query unless query.nil? || query.empty?

      request = Net::HTTP::Delete.new url
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
    # slash. Remove prefix if it is present in the dot-notation key.
    def dot_to_slash(key)
      pieces = CMDB.split(key)
      pieces.shift if pieces[0] == @prefix
      pieces.join('/')
    end

    # Convert a slash-separated URI path or subpath to dotted notation,
    # discarding initial slash. Does not account for prefix in any way!
    def slash_to_dot(path)
      pieces = path.split('/')
      pieces.shift if pieces[0].empty?
      CMDB.join(pieces)
    end
  end
end
