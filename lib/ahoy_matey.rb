require "addressable/uri"
require "browser"
require "geocoder"
require "referer-parser"
require "request_store"
require "ahoy/version"
require "ahoy/controller"
require "ahoy/model"
require "ahoy/engine"

module Ahoy

  def self.visit_model
    @visit_model || ::Visit
  end

  def self.visit_model=(visit_model)
    @visit_model = visit_model
  end

  # TODO private
  # performance hack for referer-parser
  def self.referrer_parser
    @referrer_parser ||= RefererParser::Referer.new("https://github.com/ankane/ahoy")
  end

end

ActionController::Base.send :include, Ahoy::Controller
Mongoid::Document.send(:extend, Ahoy::Model) if defined?(Mongoid)

if defined?(Warden)
  Warden::Manager.after_set_user except: :fetch do |user, auth, opts|
    request = ActionDispatch::Request.new(auth.env)
    visit_token = request.cookies["ahoy_visit"] || request.headers["Ahoy-Visit"]
    if visit_token
      visit = Ahoy.visit_model.where(visit_token: visit_token).first
      if visit and !visit.user
        visit.user = user
        visit.save!
      end
    end
  end
end
