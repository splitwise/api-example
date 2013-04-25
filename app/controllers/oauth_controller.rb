class OauthController < ApplicationController
  def index
    if session[:access_token] 
      render :text =>session[:access_token].get("https://secure.splitwise.com/api/v3.0/get_current_user").body
    else
      redirect_to login_path
    end
  end

  def login
    @consumer = OAuth::Consumer.new(ENV["SPLITWISE_API_KEY"], ENV["SPLITWISE_API_SECRET"], {
      :site               => ENV["SPLITWISE_SITE"],
      :scheme             => :header,
      :http_method        => :post,
      :authorize_path     => ENV["SPLITWISE_AUTHORIZE_URL"],
      :request_token_path => ENV["SPLITWISE_REQUEST_TOKEN_URL"],
      :access_token_path  => ENV["SPLITWISE_ACCESS_TOKEN_URL"]
    })

    @request_token = @consumer.get_request_token
    session[:request_token] = @request_token
    redirect_to @request_token.authorize_url
  end

  def callback
    if session[:request_token]
      puts "oauth_verifier:"
      p params[:oauth_verifier]
      session[:access_token] = session[:request_token].get_access_token(:oauth_verifier => params[:oauth_verifier])
      redirect_to root_path
    else
      render :text => "Looks like something went wrong - sorry!"
    end
  end
end