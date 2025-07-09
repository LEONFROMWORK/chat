class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:session][:email])
    if user
      session[:user_id] = user.id
      redirect_to root_path, notice: "Welcome back, #{user.name}!"
    else
      # Create new user if doesn't exist
      user = User.create(
        name: params[:session][:name],
        email: params[:session][:email]
      )
      if user.valid?
        session[:user_id] = user.id
        redirect_to root_path, notice: "Welcome, #{user.name}!"
      else
        flash.now[:alert] = "Please provide both name and email"
        render :new, status: :unprocessable_entity
      end
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "Logged out!"
  end
end