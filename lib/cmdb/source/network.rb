module CMDB
  class Source::Network < Source
    # @param [URI] uri
    # @param [String] dot-notation prefix of all keys
    def initialize(uri, prefix)
      @uri = uri
      @prefix = prefix
    end

    private

    # Perform a GET. On 2xx, attempt to parse response body as JSON if it
    # looks like a JSON document, else return raw response body as String.
    #
    # On 3xx, 4xx, 5xx, return an Integer status code.
    #
    # @param [String] path
    # @return [Integer,Hash]
    # @raise [JSON::ParserError] if response is malformed or invalid JSON
    def http_get(path, query:nil)
      @http ||= Net::HTTP.start(@uri.host, @uri.port)
      uri = @uri.dup
      uri.path = path
      uri.query = query unless query.nil? || query.empty?

      request = Net::HTTP::Get.new uri
      response = @http.request request
      case response.code.to_i
      when 200..299
        if response.body =~ /^[\[\{]/
          return JSON.parse(response.body)
        else
          return response.body
        end
      else
        return response.code.to_i
      end
    end

    # Perform a PUT. JSON-encode request entity unless it is already a String.
    # On 2xx, return the actual request entity that was put. On 3xx, 4xx, 5xx,
    # return an Integer status code.
    #
    # @param [String] path
    # @param [String,Hash,Array,Numeric,Boolean] entity
    # @return [Integer,String] the response entity for responses with 2xx status; the status code for responses with any other status
    def http_put(path, entity)
      entity = JSON.dump(entity) unless entity.is_a?(String)

      @http ||= Net::HTTP.start(@uri.host, @uri.port)
      uri = @uri.dup
      uri.path = path

      request = Net::HTTP::Put.new uri
      request.body = entity
      response = @http.request request
      case response.code.to_i
      when 200..299
        entity
      else
        response.code.to_i
      end
    end

    # Convert dotted notation to slash-separated notation (i.e. path components)
    # without an initial slash.
    def dot_to_slash(key)
      key.split('.').join('/')
    end
  end
end