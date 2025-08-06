# db/seeds.rb
require 'csv'
require 'open-uri'
require "nokogiri"

puts "Starting to seed electronics data..."

# Path to your CSV file
csv_file_path = Rails.root.join('db', 'electronics.csv')

# Check if file exists
unless File.exist?(csv_file_path)
  puts "Error: #{csv_file_path} not found!"
  exit
end

# Clear existing data completely
puts "Clearing existing products and categories..."
Product.destroy_all
Category.destroy_all

# Reset the primary key sequence (for PostgreSQL)
if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
  ActiveRecord::Base.connection.reset_pk_sequence!('products')
  ActiveRecord::Base.connection.reset_pk_sequence!('categories')
end

# Helper method to parse dates safely
def parse_date(date_string)
  return nil if date_string.blank?
  begin
    DateTime.parse(date_string)
  rescue
    Time.current
  end
end

# Helper method to generate realistic prices based on brand and product type
def extract_or_generate_price(product_name, brand)
  # Generate realistic prices based on brand prestige and product type
  base_price = case brand&.downcase
  when 'apple'
    product_name.downcase.include?('iphone') ? rand(699..1299) : rand(199..2499)
  when 'microsoft'
    product_name.downcase.include?('surface') ? rand(899..2199) : rand(99..699)
  when 'samsung'
    product_name.downcase.include?('galaxy') ? rand(599..1199) : rand(149..899)
  when 'sony'
    rand(99..799)
  when 'dell', 'hp', 'lenovo'
    rand(299..1499)
  when 'nintendo', 'xbox', 'playstation'
    rand(199..499)
  else
    # Determine price based on product type keywords
    name_lower = product_name.downcase
    if name_lower.include?('laptop') || name_lower.include?('computer')
      rand(399..1299)
    elsif name_lower.include?('phone') || name_lower.include?('smartphone')
      rand(199..899)
    elsif name_lower.include?('tablet') || name_lower.include?('ipad')
      rand(149..699)
    elsif name_lower.include?('keyboard') || name_lower.include?('mouse')
      rand(29..199)
    elsif name_lower.include?('monitor') || name_lower.include?('display')
      rand(149..599)
    else
      rand(49..399)
    end
  end
  
  # Add some price variation
  (base_price * (0.85 + rand(0.3))).round(2)
end

# Helper method to create meaningful product description
def create_product_description(row)
  description_parts = []
  
  # Add brand and manufacturer info
  description_parts << "Brand: #{row['brand']}" if row['brand'].present?
  description_parts << "Manufacturer: #{row['manufacturer']}" if row['manufacturer'].present? && row['manufacturer'] != row['brand']
  description_parts << "Model: #{row['manufacturerNumber']}" if row['manufacturerNumber'].present?
  
  # Add physical specifications
  description_parts << "Dimensions: #{row['dimension']}" if row['dimension'].present?
  description_parts << "Weight: #{row['weight']}" if row['weight'].present?
  description_parts << "Available Colors: #{row['colors']}" if row['colors'].present?
  
  # Add product identifiers if available
  description_parts << "UPC: #{row['upc']}" if row['upc'].present? && row['upc'] != '0'
  description_parts << "EAN: #{row['ean']}" if row['ean'].present? && row['ean'] != '0'
  
  # Create a meaningful description
  base_description = "High-quality #{row['brand']} product featuring advanced technology and reliable performance."
  full_description = [base_description, description_parts.join(" | ")].join("\n\n")
  
  # Ensure description isn't too long
  full_description.length > 500 ? full_description[0..497] + "..." : full_description
end

# Helper method to download and attach image
def attach_image_from_url(product, image_url)
  return unless image_url.present? && image_url.include?('http')
  
  begin
    # Clean the URL - take first valid URL
    clean_url = image_url.split(',').first&.strip
    return unless clean_url && clean_url.match?(/\Ahttps?:\/\//)
    
    # Skip certain problematic domains
    skip_domains = ['barcodable.com', 'placeholder', 'box.gif']
    return if skip_domains.any? { |domain| clean_url.include?(domain) }
    
    # Download and attach the image with timeout
    downloaded_image = URI.open(clean_url, read_timeout: 10)
    filename = "product_#{product.id}_#{SecureRandom.hex(4)}.jpg"
    
    product.image.attach(
      io: downloaded_image,
      filename: filename,
      content_type: 'image/jpeg'
    )
    
    puts "  ✅ Image attached for #{product.name}"
  rescue => e
    puts "  ⚠️  Image attachment failed for #{product.name}: #{e.message}"
  end
end

# Create categories from unique category names in CSV
puts "Creating categories from CSV data..."
categories = {}
category_names = Set.new

# First pass: collect all unique category names
CSV.foreach(csv_file_path, headers: true, encoding: 'utf-8') do |row|
  next if row['categories'].blank?
  
  # Split categories and clean them
  category_list = row['categories'].split(',').map(&:strip).reject(&:blank?)
  
  # Take meaningful categories (skip very generic ones)
  meaningful_categories = category_list.select do |cat|
    cat.length >= 3 && 
    !['Electronics', 'Computers', 'All', 'Name Brands'].include?(cat) &&
    !cat.match?(/^\d+$/) # Skip numeric categories
  end
  
  # Add first 2 most specific categories
  meaningful_categories.first(2).each { |cat| category_names.add(cat) }
end

# Create category records
category_names.each do |cat_name|
  category = Category.create!(name: cat_name)
  categories[cat_name] = category
  puts "Created category: #{cat_name}"
end

# Ensure we have at least one fallback category
if categories.empty?
  fallback = Category.create!(name: 'Electronics')
  categories['Electronics'] = fallback
  puts "Created fallback category: Electronics"
end

puts "\nCreating unique products (limit: 100)..."

# Track unique products by name to avoid duplicates
seen_products = Set.new
products_created = 0
products_skipped = 0
target_products = 100

CSV.foreach(csv_file_path, headers: true, encoding: 'utf-8') do |row|
  # Break if we've reached our target
  break if products_created >= target_products
  
  begin
    # Skip if essential data is missing
    next if row['name'].blank? || row['brand'].blank?
    
    # Create a unique identifier for the product
    product_identifier = "#{row['name'].strip}_#{row['brand'].strip}".downcase
    
    # Skip if we've already seen this product
    if seen_products.include?(product_identifier)
      products_skipped += 1
      next
    end
    
    seen_products.add(product_identifier)
    
    # Find the best category for this product
    category = nil
    if row['categories'].present?
      category_list = row['categories'].split(',').map(&:strip).reject(&:blank?)
      
      # Find the first category that exists in our categories hash
      category_name = category_list.find { |cat| categories[cat] }
      category = categories[category_name] if category_name
    end
    
    # Use fallback category if none found
    category ||= categories.values.first
    
    # Skip if still no category (shouldn't happen)
    next unless category
    
    # Generate price
    price = extract_or_generate_price(row['name'], row['brand'])
    
    # Create meaningful description
    description = create_product_description(row)
    
    # Create the product with meaningful data
    product = Product.create!(
      name: row['name'].strip,
      description: description,
      price_cents: (price * 100).to_i, # Convert to cents for Money gem
      category: category,
      created_at: parse_date(row['dateAdded']),
      updated_at: parse_date(row['dateUpdated'])
    )
    
    # Attach image if available (async to avoid blocking)
    if row['imageURLs'].present?
      image_urls = row['imageURLs'].split(',')
      first_image_url = image_urls.first&.strip
      attach_image_from_url(product, first_image_url) if first_image_url.present?
    end
    
    products_created += 1
    
    # Show progress every 25 products
    puts "Created #{products_created} products..." if products_created % 25 == 0
    
  rescue ActiveRecord::RecordInvalid => e
    puts "❌ Failed to create product #{row['name']}: #{e.message}"
    products_skipped += 1
  rescue => e
    puts "❌ Unexpected error creating product #{row['name']}: #{e.message}"
    products_skipped += 1
  end
end

# Final summary
puts "\n" + "="*50
puts "✅ SEEDING COMPLETED!"
puts "="*50
puts "📊 Categories created: #{Category.count}"
puts "📊 Products created: #{products_created}"
puts "⏭️  Products skipped (duplicates/errors): #{products_skipped}"
puts "📈 Total rows processed: #{products_created + products_skipped}"

puts "\n🎯 Sample products created:"
Product.includes(:category).limit(5).each do |product|
  puts "  - #{product.name} (#{product.category.name}) - $#{product.price}"
end

puts "\n📈 Products by category:"
Category.joins(:products).group('categories.name').count.each do |category, count|
  puts "  - #{category}: #{count} products"
end

puts "\n🏁 Database seeding completed successfully!"

# === 2. Scrape from external site ===
def scrape_and_seed_from_web
  puts "🌐 Scraping products from web..."

  url = 'https://webscraper.io/test-sites/e-commerce/allinone/computers/laptops'
  html = URI.open(url)
  doc = Nokogiri::HTML(html)

  doc.css('.thumbnail').each do |card|
    name = card.at_css('.title')&.text&.strip
    price = card.at_css('.price')&.text&.gsub(/[^\d.]/, '')&.to_f
    description = card.at_css('.description')&.text&.strip
    image_url = card.at_css('img')&.[]('src')
    full_image_url = URI.join(url, image_url).to_s rescue nil

    next if name.blank? || price.blank?

    category = Category.find_or_create_by!(name: "Web Laptops")

    next if Product.exists?(name: name, category: category)

    product = Product.create!(
      name: name,
      description: description || "Web-scraped product",
      price_cents: (price * 100).to_i,
      category: category
    )

    attach_image_from_url(product, full_image_url)
    puts "🌍 Scraped and created: #{name}"
  end
rescue => e
  puts "❌ Web scraping failed: #{e.message}"
end

# Run scraping after CSV import
scrape_and_seed_from_web

puts "✅ Seeding complete!"