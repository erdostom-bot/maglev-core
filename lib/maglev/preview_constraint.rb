# frozen_string_literal: true

require 'uri'

module Maglev
  class PreviewConstraint
    # Kept for backwards compatibility: clients sending a wildcard Accept header
    # are routed anyway (see #page_request?), whatever their user agent.
    CRAWLER_USER_AGENTS = /Googlebot|Twitterbot|facebookexternalhit|LinkedInBot|Slackbot|Discordbot|
                           WhatsApp|TelegramBot|Pinterest|bingbot|Applebot|redditbot|Embedly/xo

    # Accept types meaning "I want a page" (link preview fetchers, curl, bots...)
    PAGE_ACCEPT_TYPES = %w[*/* text/html].freeze

    # Path extensions that may still be a page. Anything else (.js, .css, .png,
    # .json, .map...) is an asset and must not be swallowed by Maglev.
    PAGE_EXTENSIONS = %w[html htm xml].freeze

    attr_reader :preview_host

    def initialize(preview_host: nil)
      @preview_host = preview_host == true ? default_preview_host : preview_host
    end

    def matches?(request)
      !websocket?(request) && page_request?(request) && match_host?(request)
    end

    protected

    def default_preview_host
      return nil if Maglev.config.preview_host.blank?

      URI.parse(Maglev.config.preview_host).host # make sure we get only the host here
    end

    def page_request?(request)
      accepted_format?(request) || crawler?(request) || (page_path?(request) && wildcard_accept?(request))
    end

    def accepted_format?(request)
      %i[html xml].include?(request.format.symbol)
    end

    def crawler?(request)
      request.format.symbol.nil? && CRAWLER_USER_AGENTS.match?(request.user_agent)
    end

    # No Accept header, or one listing */* or text/html among its types
    def wildcard_accept?(request)
      accept = request.headers['HTTP_ACCEPT'].to_s
      return true if accept.blank?

      accept.split(',').any? { |type| PAGE_ACCEPT_TYPES.include?(type.split(';').first.to_s.strip.downcase) }
    end

    def page_path?(request)
      extension = File.extname(request.path).delete_prefix('.').downcase
      extension.empty? || PAGE_EXTENSIONS.include?(extension)
    end

    def websocket?(request)
      request.headers['HTTP_UPGRADE'] == 'websocket'
    end

    def match_host?(request)
      !preview_host || preview_host == request.host
    end
  end
end
