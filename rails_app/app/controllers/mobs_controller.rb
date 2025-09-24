class MobsController < ApplicationController
  def index
    @mobs = Mob.all
    
    # Debug partial parameter for testing
    if params[:debug_partial] == 'true'
      binding.pry if defined?(Pry)
    end
  end

  def show
    @mob = Mob.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to mobs_path, alert: "Mob not found"
  end

  def debug_error
    # Intentional error for debugging practice
    raise StandardError, "This is a debugging exercise error!"
  end
end
