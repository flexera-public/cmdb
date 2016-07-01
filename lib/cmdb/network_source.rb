module CMDB
  class NetworkSource < Source
    def initialize(uri, prefix=nil)
      @uri = uri
      @prefix = prefix
    end

    private

    # Perform a GET. On 2xx, parse response body as JSON and return 2xx.
    # On 3xx, 4xx, 5xx, return an Integer status code.
    #
    # @param [String] path
    # @return [Integer,Hash]
    def http_get(path, query:nil)
      @http ||= Net::HTTP.start(@uri.host, @uri.port)
      uri = @uri.dup
      uri.path = path
      uri.query = query unless query.nil? || query.empty?

      request = Net::HTTP::Get.new uri
      response = @http.request request
      case response.code.to_i
      when 200..299
        return JSON.parse(response.body)
      else
        debugger
        return response.code.to_i
      end
    end

    # Perform a PUT. JSON-encode request entity unless it is already a String.
    # On 2xx, return the actual request entity that was put. On 3xx, 4xx, 5xx,
    # return an Integer status code.
    #
    # @param [String] path
    # @param [String,Hash,Array,Numeric,Boolean] entity
    # @return [Integer,String]
    def http_put(path, entity)
      entity = JSON.dump(entity) unless entity.is_a?(String)

      @http ||= Net::HTTP.start(@uri.host, @uri.port)
      uri = @uri.dup
      uri.path = path

      request = Net::HTTP::Put.new uri
      request.body = entity
      response = @http.request request
      case response.code.to_i
      when 200.299
        entity
      else
        response.code.to_i
      end
    end

    # Lazily parse a value, which may be valid JSON or may be a bare string.
    def process_value(val)
      case val[0]
      when /\[|\{/
        JSON.load(val)
      else
        val
      end
    end

    # Convert the dotted notation to a slashed notation. If a @prefix is set, apply the prefix.
    def dot_to_slash(key)
      key = "#{@prefix}.#{key}" unless @prefix.nil? || @prefix.empty?
      key.split('.').join('/')
    end
  end
end