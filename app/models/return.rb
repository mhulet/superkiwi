class Return
  include ActiveModel::Model

  attr_accessor :max_date

  validates :max_date, presence: true
end
