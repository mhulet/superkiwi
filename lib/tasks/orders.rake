namespace :orders do
  task monthly_sales: :environment do
    CYCLE = 0.5.seconds

    shop_url = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_PASSWORD']}@#{ENV['SHOPIFY_SHOP_NAME']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url

    # for each order paid and fulfilled in the previous month
    #   for each product sold
    #     add a line for this product
    #     if this product has been restocked (with a refund)
    #       show this information

    #
    # entre le début et la fin du mois
    #   pour chaque commande mise à jour dans ce time range
    #     si la commande a été fulfillée dans le time range (complèetement ou partiellement)
    #       si elle a été payée
    #         on ajoute la commande à l'export
    #     si la commande a été payée dans le time range
    #       si elle est fulfillée (complètement ou partiellement)
    #         on ajoute la commande à l'export

    begin_date = Time.parse("2017-08-01T00:00:00+01:00")
    end_date   = Time.parse("2017-09-02T23:59:59+01:00")
    date_range = begin_date..end_date
    # puts "Période à traiter:"
    # puts "  Début: #{begin_date.to_s}"
    # puts "  Fin:   #{end_date.to_s}"

    orders_count = ShopifyAPI::Order.count(
      status: "any",
      updated_at_min: begin_date.iso8601
    )
    nb_pages = (orders_count / 250.0).ceil

    start_time = Time.now
    1.upto(nb_pages) do |page|
      unless page == 1
        stop_time = Time.now
        processing_duration = stop_time - start_time
        wait_time = (CYCLE - processing_duration).ceil
        sleep wait_time if wait_time > 0
        start_time = Time.now
      end
      orders = ShopifyAPI::Order.find(
        :all,
        params: {
          limit: 250,
          page: page,
          status: "any",
          updated_at_min: begin_date.iso8601
        }
      )
      orders.each do |order|
        # puts "Commande: #{order.id} (#{order.name})"
        next if !["paid", "refunded", "partially_refunded"].include?(order.financial_status)
        next if !["fulfilled", "partial"].include?(order.fulfillment_status)
        fulfilled_at  = order.fulfillments.select { |f| f.status == "success" }.last.updated_at rescue Time.now-99.year
        paid_at       = order.transactions.select { |t| t.status == "success" }.last.created_at rescue Time.now-99.year
        if (date_range === fulfilled_at)
          # puts "  La commande a été fulfillée durant la période (statut: #{order.fulfillment_status})"
          if (order.transactions.select { |t| t.status == "success" }.any?)
            # puts "  La commande a été paiée (statut: #{order.financial_status})"
            order_to_csv_line(order, paid_at, fulfilled_at)
          else
            # puts "  SKIP! LA COMMANDE N'A PAS ETE PAYEE (statut: #{order.financial_status})"
          end
        elsif (date_range === paid_at)
          # puts "  La commande a été paiée durant la période (statut: #{order.financial_status})"
          if (order.fulfillments.select { |f| f.status == "success" }.any?)
            # puts "  La commande a été fulfillée (statut: #{order.fulfillment_status})"
            order_to_csv_line(order, paid_at, fulfilled_at)
          else
            # puts "  SKIP! LA COMMANDE N'A PAS ETE FULFILLEE (statut: #{order.fulfillment_status})"
          end
        else
          # puts "  SKIP! LA COMMANDE NE DOIT PAS ETRE TRAITEE (statut: #{order.fulfillment_status} / #{order.financial_status})"
        end
      end
    end
  end

  def order_to_csv_line(order, paid_at, fulfilled_at)
    restocked_line_items = Array.new
    order.refunds.select { |r| r.restock }.each do |refund|
      refund.refund_line_items.each do |refund_line_item|
        restocked_line_items << refund_line_item.line_item_id
      end
    end
    order.line_items.each do |line_item|
      begin
        product     = ShopifyAPI::Product.find(line_item.product_id)
        status      = (restocked_line_items.include?(line_item.id) ? "restocké" : "confirmé")
        sold_amount = (status == "restocké" ? 0 : line_item.price)
        puts "#{order.name};#{paid_at[0..9]};#{fulfilled_at[0..9]};#{line_item.sku};#{line_item.price};#{status};#{sold_amount};#{product.published_at.nil? ? 'non' : 'oui'};#{product.variants.first.inventory_quantity};#{product.title}"
      rescue
        # product has been deleted, let's skip it
        # puts "  ATTENTION, LA COMMANDE CONTIENT UN ARTICLE QUI A ETE SUPPRIME"
      end
    end
  end
end
