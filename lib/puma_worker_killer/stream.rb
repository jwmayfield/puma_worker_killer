require 'net/http'

module PumaWorkerKiller
  class Stream
    def initialize(url)
      @url = url
    end

    def quota(default)
      uri = URI(url)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new(uri.request_uri)
        http.request(request) do |response|
          response.read_body do |chunk|
            return quota_from_chunk(chunk) || default
          end
        end
      end
    end

    def watch
      uri = URI(url)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new(uri.request_uri)
        http.request(request) do |response|
          response.read_body do |chunk|
            return memory_size_from_chunk(chunk) || 0.0
          end
        end
      end
    end

    private

    def memory_size_from_chunk(chunk)
      line = chunk.split("\n").select { |line| line.include? 'sample#memory_total' }.last || 'no line'
      size = line.match(/sample#memory_total=([\d\.]+)/) || [nil, 0.0]
      size[1].to_f
    end

    def quota_from_chunk(chunk)
      line = chunk.split("\n").select { |line| line.include? 'sample#memory_quota' }.last || 'no line'
      size = line.match(/sample#memory_quota=([\d\.]+)/) || [nil, 0.0]
      size[1].to_f
    end

    attr_reader :url
  end
end
