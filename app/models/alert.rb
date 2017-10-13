class Alert < ApplicationRecord
  def self.available_collections
    {
      "1" => {
        title: "Mes petits habits",
        children: {
          "11" => {
            title: "Filles",
            children: {
              "111": {
                title: "0 mois"
              }
            }
          },
          "12" => {
            title: "Garçons"
          }
        }
      },
      "2" => {
        title: "Puériculture"
      }
    }
  end
end
