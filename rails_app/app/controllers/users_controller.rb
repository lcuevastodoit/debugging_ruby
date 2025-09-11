class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    @users = User.includes(:posts).all
    Rails.logger.info "Loading #{@users.count} users"

    # Problema intencional para backtrace
    raise "Intentional error for debugging" if params[:debug] == "error"

    respond_to do |format|
      format.html
      format.json { render json: @users }
    end
  end

  def show
    @analytics = PostAnalyticsService.new(@user).calculate_stats
    Rails.logger.info "User #{@user.id} analytics: #{@analytics}"
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      Rails.logger.info "User created successfully: #{@user.inspect}"
      redirect_to @user, notice: 'User created successfully'
    else
      Rails.logger.error "User creation failed: #{@user.errors.full_messages}"
      render :new
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: 'User updated successfully'
    else
      render :edit
    end
  end

  def destroy
    @user.destroy
    redirect_to users_path, notice: 'User deleted successfully'
  end

  private

  def set_user
    @user = User.find(params[:id])
    Rails.logger.info "Found user: #{@user.inspect}"
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "User not found: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to users_path, alert: 'User not found'
  end

  def user_params
    params.require(:user).permit(:name, :email, :active)
  end
end
