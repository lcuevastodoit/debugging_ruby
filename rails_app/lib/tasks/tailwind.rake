namespace :tailwind do
  desc 'Install Tailwind CSS'
  task :install do
    puts "Installing Tailwind CSS dependencies..."
    system "yarn add tailwindcss postcss autoprefixer"
    
    puts "Creating directories..."
    system "mkdir -p app/assets/builds"
    system "touch app/assets/builds/.keep"
    
    puts "Building Tailwind CSS..."
    system "yarn build:css"
    
    puts "Tailwind CSS has been installed successfully!"
  end
  
  desc 'Rebuild Tailwind CSS'
  task :rebuild => :environment do
    puts "Removing previous builds..."
    system "rm -f app/assets/builds/application.tailwind.css"
    
    puts "Rebuilding Tailwind CSS..."
    system "yarn build:css"
    
    puts "Tailwind CSS has been rebuilt successfully!"
  end
  
  desc 'Verify Tailwind configuration'
  task :verify => :environment do
    puts "Verifying Tailwind CSS configuration..."
    
    config_file = Rails.root.join('config/tailwind.config.js')
    if File.exist?(config_file)
      puts "✓ Found tailwind.config.js"
    else
      puts "✗ tailwind.config.js not found!"
    end
    
    css_file = Rails.root.join('app/assets/stylesheets/application.tailwind.css')
    if File.exist?(css_file)
      puts "✓ Found application.tailwind.css"
      content = File.read(css_file)
      if content.include?('@tailwind base') && content.include?('@tailwind components') && content.include?('@tailwind utilities')
        puts "✓ application.tailwind.css contains the required directives"
      else
        puts "✗ application.tailwind.css is missing some required directives!"
      end
    else
      puts "✗ application.tailwind.css not found!"
    end
    
    build_path = Rails.root.join('app/assets/builds')
    if Dir.exist?(build_path)
      puts "✓ builds directory exists"
    else
      puts "✗ builds directory not found!"
    end
    
    puts "\nTo rebuild Tailwind CSS, run: rails tailwind:rebuild"
  end
  
  desc 'Debug Tailwind CSS configuration and setup'
  task :debug => :environment do
    puts "\n=== TAILWIND CSS DEBUGGING ==="
    puts "Ruby version: #{RUBY_VERSION}"
    puts "Rails version: #{Rails.version}"
    
    puts "\n=== DIRECTORY STRUCTURE ==="
    system "find app/assets -type f | grep -v node_modules | sort"
    
    puts "\n=== TAILWIND CONFIG ==="
    config_file = Rails.root.join('config/tailwind.config.js')
    if File.exist?(config_file)
      puts File.read(config_file)
    else
      puts "tailwind.config.js not found!"
    end
    
    puts "\n=== PACKAGE.JSON ==="
    pkg_file = Rails.root.join('package.json')
    if File.exist?(pkg_file)
      puts File.read(pkg_file)
    else
      puts "package.json not found!"
    end
    
    puts "\n=== CSS FILE ==="
    css_file = Rails.root.join('app/assets/stylesheets/application.tailwind.css')
    if File.exist?(css_file)
      puts File.read(css_file)
    else
      puts "application.tailwind.css not found!"
    end
    
    puts "\n=== GENERATED CSS ==="
    build_file = Rails.root.join('app/assets/builds/application.tailwind.css')
    if File.exist?(build_file)
      puts "File exists: #{build_file}"
      puts "File size: #{File.size(build_file)} bytes"
      puts "Last modified: #{File.mtime(build_file)}"
      
      # Show first few lines to check if it's generated properly
      puts "\nFirst 10 lines of generated CSS:"
      puts File.readlines(build_file).first(10)
    else
      puts "Generated CSS file not found!"
    end
    
    puts "\n=== TROUBLESHOOTING STEPS ==="
    puts "1. Make sure tailwind.config.js has the correct content paths"
    puts "2. Verify application.tailwind.css has the proper @tailwind directives"
    puts "3. Check that your views are using Tailwind classes"
    puts "4. Ensure the asset pipeline is configured to include the builds directory"
    puts "5. Run 'rails tailwind:rebuild' to force a rebuild of the CSS"
  end
  
  desc 'Full restart of Tailwind CSS (rebuild and restart server)'
  task :restart => :environment do
    puts "Stopping any running processes..."
    system "pkill -f 'rails|tailwind' || true"
    
    puts "Rebuilding Tailwind CSS..."
    Rake::Task["tailwind:rebuild"].invoke
    
    puts "Starting development server with Tailwind CSS watching for changes..."
    # Using spawn to run in background
    spawn("cd #{Rails.root} && bin/dev")
    
    puts "Development server started!"
    puts "You can now view your application at: http://localhost:3000"
  end
end