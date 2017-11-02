class Sale < ActiveRecord::Base
  belongs_to :droper

  validates :code, presence: true

  paginates_per 100

  default_scope { order(id: :desc) }

  validates :code, uniqueness: { message: "Cet article a déjà été signalé comme vendu" }

  def self.build_from_csv(row)
    item = Sale.new
    if row[0].present?
      item.code         = row[0].upcase.delete(' ')
      item.product      = row[1]
      item.amount       = ((row[2].gsub(',', '.').to_f)*100).to_i
      item.sold_at      = DateTime.parse(row[4])
      droper_code  = item.code.upcase.match(/[A-Z]+/).to_s
      item.droper       = Droper.find_or_create_by(code: droper_code)
    end
    item
  end

  def price
    self.amount.to_f / 100.0
  end
end
