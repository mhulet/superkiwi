# encoding: utf-8

require "csv"

namespace :dropers do
  task :import => :environment do
    shop_url = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_PASSWORD']}@#{ENV['SHOPIFY_SHOP_NAME']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url
    dropers_csv_path = "lib/assets/dropers.csv"
    CSV.foreach(dropers_csv_path, headers: true) do |row|
      customer = ShopifyAPI::Customer.search(query: "email:#{row['email']}")
      if !customer.any?
        ap "Create customer: #{row['code']}"
        tags = "déposant, ref-#{row['code']}"
        if !row['iban'].nil? && !row['iban'].empty?
          tags = "#{tags}, compte-#{row['iban']}"
        end
        if !row['commissionnable'].nil? && row['commissionnable'].to_s == "0"
          tags = "#{tags}, sans-commission"
        end
        ShopifyAPI::Customer.create(
          accepts_marketing:  true,
          first_name:         (!row['firstname'].nil? ? row['firstname'] : nil),
          last_name:          (!row['lastname'].nil? ? row['lastname'] : nil),
          email:              row['email'],
          tags:               tags,
          note:               "Compte client créé pour un déposant"
        )
        ap " + create collection for customer"
        ShopifyAPI::SmartCollection.create(
          handle:             row['code'].downcase,
          published_scope:    "global",
          title:              row['code'],
          rules:              [
                                {
                                  "column":     "tag",
                                  "relation":   "equals",
                                  "condition":  row['code']
                                }
                              ],
          sort_order:         "created-desc"
        )
      end
    end
  end

  task :clean => :environment do
    CYCLE = 0.5.seconds
    active_dropers_csv_path = "lib/assets/active_dropers.csv"
    active_dropers_codes = []
    CSV.foreach(active_dropers_csv_path, headers: true) do |row|
      active_dropers_codes << row['code']
    end
    shop_url = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_PASSWORD']}@#{ENV['SHOPIFY_SHOP_NAME']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url
    customers_count = ShopifyAPI::Customer.count
    nb_pages = (customers_count / 50.0).ceil
    start_time = Time.now
    9.upto(nb_pages) do |page|
      ap "Page #{page}/#{nb_pages}"
      stop_time = Time.now
      processing_duration = stop_time - start_time
      wait_time = (CYCLE - processing_duration).ceil
      sleep wait_time if wait_time > 0
      start_time = Time.now
      customers = ShopifyAPI::Customer.find(:all, params: { page: page })
      customers.each do |customer|
        customer_tags = customer.tags.split(", ")
        if customer_tags.include?("déposant")
          customer_tags.each do |customer_tag|
            if customer_tag.starts_with?("ref-")
              droper_code = customer_tag.split("-").last
              if !active_dropers_codes.include?(droper_code) && customer.state == "disabled"
                # customer is an inactive droper and has not been invited yet
                  ap "Delete customer #{droper_code} (#{customer.id})"
                begin
                  customer.destroy
                  ShopifyAPI::SmartCollection.find(:all, params: { handle: droper_code.downcase }).first.destroy
                rescue Exception => e
                  customer.tags = "Défaut"
                  customer.save
                  ap "EXCEPTION: #{e.inspect}"
                end
              end
            end
          end
        end
      end
    end
  end
end
