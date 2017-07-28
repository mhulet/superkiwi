class Return
  include ActiveModel::Model

  attr_accessor :max_date, :giving_date

  validates :max_date, presence: true
  validates :giving_date, presence: true
end
