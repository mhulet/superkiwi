class Sale < ActiveRecord::Base
  belongs_to :droper

  # attr_accessible :amount, :wrong_amount, :code, :product, :sold_at, :droper_id

  validates :code, presence: true

  paginates_per 100

  default_scope { order(id: :desc) }

  validates_uniqueness_of :code

  def self.build_from_csv(row)
    item = Sale.new
    if row[0].present?
      item.code = row[0].upcase.delete(' ')
      item.product = row[1]
      item.amount = ((row[2].gsub(',', '.').to_f)*100).to_i
      item.sold_at = DateTime.parse(row[4])
    end
    item
  end

  def price
    self.amount.to_f / 100.0
  end
end