class UserController < ApplicationController
  before_filter :check_for_credentials, except: [:login, :callback, :welcome]
  
  def check_for_credentials
    unless session[:access_token]
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
      session[:access_token] = session[:request_token].get_access_token(:oauth_verifier => params[:oauth_verifier])
      after_callback
    else
      render :text => "Looks like something went wrong - sorry!"
    end
  end

  def after_callback
    redirect_to action: 'balance_over_time'
  end

  def logout
    session[:access_token] = nil
    after_logout
  end

  def after_logout
    redirect_to action: 'welcome'
  end

  # Actions with views
  def welcome
    if session[:access_token]
      after_callback
    end
  end

  def balance_over_time
    @title = "Api Example \u00B7 Balance"
    @data = JSON.unparse(User.new(session[:access_token]).get_balance_over_time)
  end

  def balances_over_time_with_friends
    @title = "Api Example \u00B7 Balance with friends"
    @data = JSON.unparse(User.new(session[:access_token]).get_balances_over_time_with_friends)
  end

  def expenses_over_time
    @title = "Api Example \u00B7 Expenses"
    @data = JSON.unparse(User.new(session[:access_token]).get_expenses_over_time_cumulative)
  end

  def expenses_by_category
    @title = "Api Example \u00B7 Expenses by category"
    @data = JSON.unparse(User.new(session[:access_token]).get_expenses_by_category)
  end

  def expenses_by_category_over_time
    @title = "Api Example \u00B7 Category history"
    @data = JSON.unparse(User.new(session[:access_token]).get_expenses_by_category_over_time_cumulative)
  end

  def expenses_matching
    @title = "Api Example \u00B7 Search an expense"
    @data = JSON.unparse(User.new(session[:access_token]).get_expenses_matching_cumulative(params[:query]))
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
