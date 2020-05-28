require "gds_api/content_store"
require "gds_api/publishing_api"
require "gds_api/search"

module Services
  def self.content_store
    @content_store ||= GdsApi::ContentStore.new(
      Plek.new.find("content-store"),
    )
  end

  def self.publishing_api
    @publishing_api ||= GdsApi::PublishingApi.new(
      Plek.new.find("publishing-api"),
      bearer_token: ENV["PUBLISHING_API_BEARER_TOKEN"] || "example",
    )
  end

  def self.rummager
    @rummager ||= GdsApi::Search.new(Plek.find("search"))
  end
end
