class MobsController < ApplicationController
  def index
    @mobs = Mob.all

    # Debug partial parameter for testing
    if params[:pry] == 'true'
      binding.pry if defined?(Pry)
    end

    if params[:debugger] == 'true'
      binding.break
    end

    # variables y asignaciones de ejemplo para practicar con debugger en vscode
    a = 1
    b = 2
    c = 3
    d = 4
    e = 5
    f = 6
    pi = Math::PI
    phi = (1 + Math.sqrt(5)) / 2
    eulers_number = Math::E
    golden_ratio = phi

    if params[:byebug] == 'true'
      byebug
    end

    if params[:irb] == 'true'
      irb
    end
  end

  def show
    @mob = Mob.find(params[:id])
    
    # Get additional information from Minecraft Fandom API
    @wiki_info = MinecraftApiService.get_mob_info(@mob.name)
    
    # Debug options for API testing
    if params[:pry] == 'true'
      binding.pry if defined?(Pry)
    end
    
    if params[:debugger] == 'true'
      binding.break
    end
    
  rescue ActiveRecord::RecordNotFound
    redirect_to mobs_path, alert: "Mob not found"
  end

  def debug_error
    # Intentional error for debugging practice
    raise StandardError, "This is a debugging exercise error!"
  end
end
