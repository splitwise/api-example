class OauthController < ApplicationController

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
      session[:access_token] = session[:request_token].get_access_token(:oauth_verifier => params[:oauth_verifier])
      redirect_to action: 'balance_over_time'
    else
      render :text => "Looks like something went wrong - sorry!"
    end
  end

  def balance_over_time
    unless session[:access_token]
      redirect_to login_path
    end
  end

  def expenses_over_time
    unless session[:access_token]
      redirect_to login_path
    end
  end

  def expenses_by_category
    unless session[:access_token]
      redirect_to login_path
    end
  end

  def get_balance_over_time
    if session[:access_token]
      if params[:format] == 'google-charts'
        render text: JSON.unparse(Oauth.get_balance_over_time_google_charts_format(session[:access_token]))
      else
        render text: JSON.unparse(Oauth.get_balance_over_time(session[:access_token]))
      end
    else
      redirect_to login_path
    end
  end

  def get_expenses_over_time
    if session[:access_token]
      render text: JSON.unparse(Oauth.get_expenses_over_time(session[:access_token]))
    else
      redirect_to login_path
    end
  end

  def get_expenses_by_category
    if session[:access_token]
      render text: JSON.unparse(Oauth.get_expenses_by_category(session[:access_token]))
    else
      redirect_to login_path
    end
  end
end