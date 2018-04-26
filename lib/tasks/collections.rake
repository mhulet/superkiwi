namespace :collections do
  task to_csv: :environment do
    CYCLE = 0.5.seconds

    shop_url = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_PASSWORD']}@#{ENV['SHOPIFY_SHOP_NAME']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url

    collections_count = ShopifyAPI::SmartCollection.count
    nb_pages = (collections_count / 250.0).ceil

    puts "collection ID,collection title,products count,rules"

    start_time = Time.now
    1.upto(nb_pages) do |page|
      unless page == 1
        stop_time = Time.now
        processing_duration = stop_time - start_time
        wait_time = (CYCLE - processing_duration).ceil
        sleep wait_time if wait_time > 0
        start_time = Time.now
      end
      collections = ShopifyAPI::SmartCollection.find(
        :all,
        params: {
          limit: 250,
          page: page
        }
      )
      collections.each do |collection|
        products_count = ShopifyAPI::Product.count(
          collection_id: collection.id
        )
        rules = collection.rules.collect { |rule| "#{rule.column} #{rule.relation} #{rule.condition}" }
        puts "#{collection.id};#{collection.title};#{products_count};#{rules.join(',')}"
      end
    end
  end
end
