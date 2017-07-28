module ApplicationHelper
  def product_size(product)
    size_option = product.options.select { |o| o.name == "Taille" }
    if size_option.any?
      return size_option.first.values.join(", ")
    end
    return nil
  end
end
