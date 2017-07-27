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

  task :return_emails, [:max_droping_date] => [:environment] do |t, args|
    max_droping_date = Date.parse(args[:max_droping_date])

    # for each droper
    #   get all her products droped before the max droping date
    #   send an email to the droper with a list of all products

    CYCLE = 0.5.seconds

    shop_url = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_PASSWORD']}@#{ENV['SHOPIFY_SHOP_NAME']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url

    products_count = ShopifyAPI::Product.count
    nb_pages = (products_count / 250.0).ceil

    dropings = Hash.new

    start_time = Time.now
    1.upto(nb_pages) do |page|
      unless page == 1
        stop_time = Time.now
        processing_duration = stop_time - start_time
        wait_time = (CYCLE - processing_duration).ceil
        sleep wait_time if wait_time > 0
        start_time = Time.now
      end
      products = ShopifyAPI::Product.find(
        :all,
        params: {
          limit: 250,
          page: page
        }
      )
      products.each do |product|
        variant = product.variants.first
        next if variant.inventory_quantity < 1 || product.published_at.nil? || variant.sku.nil?
        droper_code = variant.sku.gsub(/[^a-zA-Z]/, "")
        dropings[droper_code] ||= Hash.new
        dropings[droper_code][Date.parse(product.created_at).to_s] ||= Array.new
        dropings[droper_code][Date.parse(product.created_at).to_s].push(product)
      end
    end

    dropings.each do |droper_code, droper_dates|

      # puts "#{droper_code}:"
      droper_dates.each do |droper_date, products_count|
        # puts "  #{droper_date}: #{products_count} articles en vente"
        puts "#{droper_code};#{droper_date};#{products_count}"
      end
      # puts ""
    end
  end
end
