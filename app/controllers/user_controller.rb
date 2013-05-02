class UserController < ApplicationController
  before_filter :check_for_credentials, except: [:login, :callback, :welcome]
  
  def check_for_credentials
    unless access_token
      redirect_to login_path
    end
  end

  def login
    @request_token = consumer.get_request_token
    Rails.cache.write(@request_token.token, @request_token.secret)
    redirect_to @request_token.authorize_url
  end

  def callback
    request_token = OAuth::RequestToken.new(consumer, params[:oauth_token], Rails.cache.read(params[:oauth_token]))
    access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
    session[:access_token] = access_token.token
    session[:access_token_secret] = access_token.secret
    after_callback
  rescue
    render :text => "Looks like something went wrong - sorry!"
  end

  def after_callback
    redirect_to action: 'balance_over_time'
  end

  def logout
    reset_session
    after_logout
  end

  def after_logout
    redirect_to action: 'welcome'
  end

  # Actions with views
  def welcome
    if access_token
      after_callback
    end
  end

  def balance_over_time
    @title = "Balance"
    @data = JSON.unparse(current_user.get_balance_over_time)
  end

  def balances_over_time_with_friends
    @title = "Balance with friends"
    @data = JSON.unparse(current_user.get_balances_over_time_with_friends)
  end

  def expenses_over_time
    @title = "Expenses"
    @data = JSON.unparse(current_user.get_expenses_over_time_cumulative)
  end

  def expenses_by_category
    @title = "Expenses by category"
    @data = JSON.unparse(current_user.get_expenses_by_category)
  end

  def expenses_by_category_over_time
    @title = "Category history"
    @data = JSON.unparse(current_user.get_expenses_by_category_over_time_cumulative)
  end

  def expenses_matching
    @title = "Search an expense"
    @data = JSON.unparse(current_user.get_expenses_matching_cumulative(params[:query]))
  end

  def get_expenses_matching 
    render text: JSON.unparse(current_user.get_expenses_matching_cumulative(params[:query]))
  end

  private

  def consumer
    @consumer ||= OAuth::Consumer.new(ENV["SPLITWISE_API_KEY"], ENV["SPLITWISE_API_SECRET"], {
      :site               => ENV["SPLITWISE_SITE"],
      :scheme             => :header,
      :http_method        => :post,
      :authorize_path     => ENV["SPLITWISE_AUTHORIZE_URL"],
      :request_token_path => ENV["SPLITWISE_REQUEST_TOKEN_URL"],
      :access_token_path  => ENV["SPLITWISE_ACCESS_TOKEN_URL"]
    })
  end

  def access_token
    if session[:access_token]
      @access_token ||= OAuth::AccessToken.new(consumer, session[:access_token], session[:access_token_secret])
    end
  end

  def current_user
    @current_user ||= User.new(access_token)
  end
end

=begin
  def get_balance_over_time
    if params[:format] == 'google-charts'
      render text: JSON.unparse(User.new(session[:access_token]).get_balance_over_time_google_charts_format)
    else
      render text: JSON.unparse(User.new(session[:access_token]).get_balance_over_time)
    end
  end

  def get_balances_over_time_with_friends
    render text: JSON.unparse(User.new(session[:access_token]).get_balances_over_time_with_friends)
  end

  def get_expenses_over_time
    render text: JSON.unparse(User.new(session[:access_token]).get_expenses_over_time)
  end

  def get_expenses_over_time_cumulative
    render text: JSON.unparse(User.new(session[:access_token]).get_expenses_over_time_cumulative)
  end

  def get_expenses_by_category
    render text: JSON.unparse(User.new(session[:access_token]).get_expenses_by_category)
  end

  def get_expenses_matching 
    render text: JSON.unparse(User.new(session[:access_token]).get_expenses_matching(params[:query]))
  end
=end
