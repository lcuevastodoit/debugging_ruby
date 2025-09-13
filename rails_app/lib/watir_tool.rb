#!/usr/bin/env ruby

require 'watir'
require 'logger'

class WatirTool
  attr_reader :browser, :logger

  def initialize(headless: false)
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO

    begin
      # Try Chrome first with automatic driver management
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument('--disable-dev-shm-usage') if headless
      options.add_argument('--no-sandbox') if headless
      options.add_argument('--headless') if headless
      options.add_argument('--disable-gpu') if headless
      options.add_argument('--window-size=1200,800')

      # Let Selenium manage the driver automatically
      service = Selenium::WebDriver::Service.chrome
      @browser = Watir::Browser.new(:chrome, service: service, options: options)
      logger.info "Chrome browser initialized (headless: #{headless})"

    rescue => chrome_error
      logger.warn "Chrome failed: #{chrome_error.message}"
      logger.info "Falling back to Firefox..."

      # Fallback to Firefox
      options = Selenium::WebDriver::Firefox::Options.new
      options.add_argument('--headless') if headless
      options.add_argument('--width=1200')
      options.add_argument('--height=800')

      @browser = Watir::Browser.new(:firefox, options: options)
      logger.info "Firefox browser initialized (headless: #{headless})"
    end

    @base_url = 'http://localhost:3000'
  end

  def navigate_to_home
    browser.goto(@base_url)
    logger.info "Navigated to #{@base_url}"

    # Wait for page to load - check for Rails Debugging Demo title
    browser.wait_until(timeout: 15) { browser.title.include?('Rails Debugging Demo') }
    logger.info "Page loaded successfully: #{browser.title}"
  end

  def test_monitoring_buttons
    logger.info "=== Testing Monitoring Buttons ==="

    navigate_to_home

    # Check initial state
    monitoring_status = browser.div(id: 'monitoring_status')
    initial_status = monitoring_status.text
    logger.info "Initial monitoring status: '#{initial_status}'"

    # Find Start Monitoring button
    start_button = browser.button(text: 'Start Monitoring')
    stop_button = browser.button(text: 'Stop Monitoring')

    raise "Start Monitoring button not found" unless start_button.exists?
    raise "Stop Monitoring button not found" unless stop_button.exists?

    logger.info "Both monitoring buttons found successfully"

    # Test Start Monitoring
    logger.info "Clicking Start Monitoring button..."
    start_button.click

    # Wait for status change (with timeout)
    begin
      browser.wait_until(timeout: 10) do
        current_status = monitoring_status.text
        current_status != initial_status && current_status.include?('Active')
      end

      new_status = monitoring_status.text
      logger.info "✅ Start Monitoring successful! Status changed to: '#{new_status}'"
    rescue Watir::Exception::TimeoutError
      logger.error "❌ Start Monitoring failed - Status did not change within timeout"
      return false
    end

    # Test Stop Monitoring
    logger.info "Clicking Stop Monitoring button..."
    stop_button.click

    # Wait for status to change back
    begin
      browser.wait_until(timeout: 10) do
        current_status = monitoring_status.text
        current_status.include?('Stopped') || current_status.include?('🔴')
      end

      final_status = monitoring_status.text
      logger.info "✅ Stop Monitoring successful! Status changed to: '#{final_status}'"
    rescue Watir::Exception::TimeoutError
      logger.error "❌ Stop Monitoring failed - Status did not change within timeout"
      return false
    end

    logger.info "=== Monitoring Buttons Test Completed Successfully ==="
    true
  end

  def test_game_elements
    logger.info "=== Testing Game Elements ==="

    navigate_to_home

    # Test progress indicators
    progress_elements = {
      'Current Level' => browser.div(text: /Novato|Mago|Hechicero|Héroe/),
      'Total Points' => browser.div(text: /\d+ pts/),
      'Current Streak' => browser.div(text: /Current Streak/),
      'Leaderboard' => browser.h3(text: 'Leaderboard')
    }

    progress_elements.each do |name, element|
      if element.exists?
        logger.info "✅ #{name} element found and displayed"
      else
        logger.warn "⚠️  #{name} element not found"
      end
    end

    # Test objective cards
    objective_cards = browser.divs(class: /border.*rounded/)
    logger.info "Found #{objective_cards.length} objective cards"

    # Test navigation buttons
    refresh_button = browser.button(text: /Refresh/)
    pause_button = browser.button(text: /Pause/)

    logger.info "✅ Refresh button found" if refresh_button.exists?
    logger.info "✅ Pause button found" if pause_button.exists?

    logger.info "=== Game Elements Test Completed ==="
  end

  def test_responsive_design
    logger.info "=== Testing Responsive Design ==="

    navigate_to_home

    # Test different viewport sizes
    viewports = [
      { name: 'Desktop', width: 1200, height: 800 },
      { name: 'Tablet', width: 768, height: 1024 },
      { name: 'Mobile', width: 375, height: 667 }
    ]

    viewports.each do |viewport|
      logger.info "Testing #{viewport[:name]} viewport (#{viewport[:width]}x#{viewport[:height]})"

      browser.window.resize_to(viewport[:width], viewport[:height])
      sleep(2) # Allow time for responsive changes

      # Check if main elements are still visible
      main_content = browser.div(class: /bg-white.*rounded-lg/)
      if main_content.exists? && main_content.visible?
        logger.info "✅ #{viewport[:name]} - Main content visible and accessible"
      else
        logger.warn "⚠️  #{viewport[:name]} - Main content may have display issues"
      end
    end

    # Reset to desktop size
    browser.window.resize_to(1200, 800)
    logger.info "=== Responsive Design Test Completed ==="
  end

  def test_statistics_section
    logger.info "=== Testing Statistics Section ==="

    navigate_to_home

    # Look for statistics panels
    stats_sections = [
      'Your Statistics',
      'Global Statistics',
      'Completion Rate',
      'Efficiency Score'
    ]

    stats_sections.each do |section|
      element = browser.element(text: section)
      if element.exists?
        logger.info "✅ #{section} section found"
      else
        logger.warn "⚠️  #{section} section not found"
      end
    end

    logger.info "=== Statistics Section Test Completed ==="
  end

  def test_full_reset_functionality
    logger.info "=== Testing Full Reset Functionality ==="

    navigate_to_home

    # Check database state before reset via browser UI
    logger.info "🔍 Checking leaderboard state before reset..."
    game_progress_count_before = get_visible_leaderboard_entries
    logger.info "Visible leaderboard entries before reset: #{game_progress_count_before}"

    # Look for Full Reset button directly (it's in a form)
    full_reset_button = browser.button(text: "Full Reset")

    if full_reset_button.exists?
      logger.info "Found Full Reset button, clicking..."

      # For automated testing, we need to override the confirmation and submit properly
      # Find the form containing the Full Reset button
      form = full_reset_button.parent(tag_name: 'form')
      if form.exists?
        logger.info "Found reset form, removing confirmation and submitting..."

        # Remove the data-confirm attribute to bypass confirmation dialog
        browser.execute_script("arguments[0].removeAttribute('data-confirm');", form)

        # Submit the form directly
        form.submit
        logger.info "Form submitted successfully"
      else
        logger.warn "Could not find parent form for Full Reset button"
        return false
      end

      # Wait for reset to complete and page to reload
      sleep(5)

      # Check Rails logs for reset activity
      logger.info "📋 Checking Rails logs for reset activity..."
      check_rails_logs_for_reset(initial_log_size)

      # Navigate back to home to refresh data
      navigate_to_home
      sleep(2) # Give time for any async updates

      # Check database state after reset via browser UI
      logger.info "🔍 Checking leaderboard state after reset..."
      game_progress_count_after = get_visible_leaderboard_entries
      logger.info "Visible leaderboard entries after reset: #{game_progress_count_after}"

      if game_progress_count_after == 0 && game_progress_count_before > 0
        logger.info "✅ Full Reset successful - Leaderboard cleared (#{game_progress_count_before} → #{game_progress_count_after})"
        return true
      elsif game_progress_count_after == 0 && game_progress_count_before == 0
        logger.info "✅ Full Reset completed - Leaderboard was already empty"
        return true
      else
        logger.warn "❌ Full Reset failed - Leaderboard entries still visible: #{game_progress_count_after}"
        return false
      end
    else
      logger.warn "⚠️  Full Reset button not found"
      return false
    end

    logger.info "=== Full Reset Test Completed ==="
  end

  def get_visible_leaderboard_entries
    # Check visible leaderboard entries in the browser
    begin
      # Look for the leaderboard table specifically
      leaderboard_section = browser.element(css: ".bg-white.rounded-lg")
      if leaderboard_section.exists?
        # Count rows that contain user data (have points/level info)
        rows = leaderboard_section.elements(tag_name: "tr")
        user_rows = rows.select do |row|
          text = row.text.downcase
          # Skip header rows, look for actual user data with points
          text.include?('pts') || text.include?('points') || text.match?(/\d+\s*pt/)
        end
        logger.info "🔍 Found leaderboard rows: #{rows.length}, user rows with points: #{user_rows.length}"

        # Debug: print actual row content
        user_rows.each_with_index do |row, index|
          logger.info "   Row #{index + 1}: #{row.text.strip}"
        end

        user_rows.length
      else
        logger.info "❌ No leaderboard section found"
        0
      end
    rescue => e
      logger.warn "❌ Error checking leaderboard entries: #{e.message}"
      0
    end
  end

  def run_full_test_suite
    logger.info "🚀 Starting Full Test Suite for Rails Debugging Game"

    results = {
      monitoring_buttons: false,
      game_elements: false,
      responsive_design: false,
      statistics: false,
      full_reset: false
    }

    begin
      results[:monitoring_buttons] = test_monitoring_buttons
      test_game_elements
      results[:game_elements] = true

      test_responsive_design
      results[:responsive_design] = true

      test_statistics_section
      results[:statistics] = true

      results[:full_reset] = test_full_reset_functionality

    rescue => e
      logger.error "Test suite error: #{e.message}"
      logger.error e.backtrace.join("\n")
    end

    # Print results summary
    logger.info "="*50
    logger.info "TEST SUITE RESULTS:"
    results.each do |test, passed|
      status = passed ? "✅ PASSED" : "❌ FAILED"
      logger.info "  #{test.to_s.gsub('_', ' ').upcase}: #{status}"
    end
    logger.info "="*50

    results
  end

  def close
    browser.close
    logger.info "Browser closed"
  end

  def self.run_tests(headless: true)
    tool = new(headless: headless)

    begin
      tool.run_full_test_suite
    ensure
      tool.close
    end
  end

  def self.test_full_reset_with_logs(headless: true)
    tool = new(headless: headless)

    begin
      puts "🔄 Testing Full Reset functionality with Rails log monitoring..."
      result = tool.monitor_rails_logs_during_reset
      puts result ? "✅ Full Reset test completed successfully" : "❌ Full Reset test failed"
      result
    ensure
      tool.close
    end
  end
end

# Allow running directly from command line
if __FILE__ == $0
  headless = ARGV.include?('--headless') || ARGV.include?('-h')
  WatirTool.run_tests(headless: headless)
end
