class PostAnalyticsService
  def initialize(user)
    @user = user
    @posts = user.posts
  end

  def calculate_stats
    # Problema intencional para debugging
    # binding.pry  # Para pry

    {
      total_posts: @posts.count,
      published_posts: @posts.published.count,
      avg_content_length: calculate_avg_length,
      most_recent: @posts.recent.first&.title
    }
  rescue => e
    Rails.logger.error "Error in PostAnalyticsService: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    {}
  end

  private

  def calculate_avg_length
    return 0 if @posts.empty?

    # Problema intencional de performance
    sleep(0.5) # Simular operación lenta
    lengths = @posts.pluck(:content).map(&:length)
    lengths.sum / lengths.size
  end
end
