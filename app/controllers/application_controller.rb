class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :get_communities
  def get_communities
  	@communities = Community.all
  end
end
