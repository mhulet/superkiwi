class SendAlertsJob < ActiveJob::Base
  queue_as :mailers

  def perform()
    puts "Alerts count: #{Alert.all.count}"
    Alert.all.find_each do |alert|
      puts "Processing alert #{alert.id}..."
      collections       = Hash.new
      should_be_alerted  = false
      alert.categories_ids.each do |collection_ids|
        # count products for collection
        # if > 0
        #   get all products (not just 250 first)
        #   get all products for parent collections

        # eg. collection_id = "subsubcategoryid,subcategoryid,categoryid" (with parent collections)
        # eg. collection_id = "789,456,123"
        collection_ids = collection_ids.split(',')
        collection_id = collection_ids.pop
        puts "  Check collection #{collection_id}..."

        if count_products(collection_id) > 0
          collection_products = products_for_collection(collection_id)
          puts "    #{collection_products.count} products in this collection"
          if collection_ids.any?
            collection_ids.each do |parent_collection_id|
              puts "    Checking parent collection #{parent_collection_id}..."
              collection_products =
                collection_products & products_for_collection(parent_collection_id)
            end
            puts "    reduced to #{collection_products.count} products " +
              "when intersected with parent collections"
          end

          if collection_products.any?
            should_be_alerted = true

            collection = ShopifyAPI::SmartCollection.find(collection_id)
            collections[collection_id] = {
              title: collection.title,
              handle: collection.handle,
              count: collection_products.count,
              products: collection_products
            }
            if collection_ids.any?
              collections[collection_id][:parents] = []
              collection_ids.each do |parent_collection_id|
                parent_collection = ShopifyAPI::SmartCollection.find(
                  parent_collection_id
                )
                collections[collection_id][:parents] << parent_collection.title
                # prepend handle when required
                case parent_collection_id
                when '330700294'
                  collections[collection_id][:handle] =
                    "filles/#{collection.handle}"
                when '330708358'
                  collections[collection_id][:handle] =
                    "garcons/#{collection.handle}"
                when '384538828'
                  collections[collection_id][:handle] =
                    "pyjamas-bodies-sous-vetements-1/#{collection.handle}"
                end
              end
            end
          end
        else
          puts "    -> no new products (won't alert customer)"
        end
      end
      if should_be_alerted
        CustomerMailer.alert(
          alert.customer_id, collections
        ).deliver_now
        alert.update_column(:sent_at, Time.now.utc)
      end
    end
  end

  private

  def count_products(collection_id)
    ShopifyAPI::Product.count(
      collection_id: collection_id,
      published_at_min: (Date.yesterday + 9.hours).utc.to_formatted_s(:iso8601)
    )
  end

  def products_for_collection(collection_id)
    products_count = count_products(collection_id)
    nb_pages = (products_count / 250.0).ceil
    products = []
    1.upto(nb_pages) do |page|
      products.concat(
        ShopifyAPI::Product.find(
          :all,
          params: {
            limit: 250,
            page: page,
            collection_id: collection_id,
            published_at_min: (Date.yesterday + 9.hours).utc.to_formatted_s(:iso8601)
          }
        )
      )
    end
    products
  end
end
