require "csv"

class Search
  class Client
    def initialize(config = {})
      @config = config
    end

    def extra_terms_path
      Rails.root.join("data", @config[:extra_terms_filename])
    end

    def extra_terms_handle
      File.open(extra_terms_path)
    end

    def extra_terms
      return @extra_terms unless @extra_terms.nil?

      @extra_terms = {}
      begin
        CSV.new(extra_terms_handle).each do |row|
          @extra_terms[row[0].to_i] = row[1..].map(&:strip)
        end
      rescue StandardError => e
        Rails.logger.warn("Exception #{e.message} raised while searching for extra terms")
      end
      @extra_terms
    end

    def extra_terms_for_sector(sector)
      extra_terms[sector.correlation_id] || []
    end

    def activities_for_sector(sector)
      sector.activities.map(&:name)
    end
  end
end
