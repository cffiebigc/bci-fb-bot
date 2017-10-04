require 'sucker_punch'
require 'haversine'

class LocationJob
  include SuckerPunch::Job

  def perform(bci_client, user_lat, user_long, user)
    @user = user
    stores = bci_client.beneficios.shopping['promotions']
    if stores.any?
      calculate_distance_to_stores(stores, user_lat, user_long)
    else
      say 'Al parecer ocurrió un problema, por favor intentalo más tarde'
    end
  end

  def calculate_distance_to_stores(stores, lat, long)
    distance_to_stores = {}
    stores.each do |store|
      next if store['latitude'].nil? || store['longitude'].nil?
      distance = Haversine.distance(lat, long, store['latitude'].to_f, store['longitude'].to_f).to_meters
      distance_to_stores[distance] = store
    end
    display_nearest_stores(distance_to_stores)
  end

  def display_nearest_stores(distance_to_stores)
    nearest_stores = Hash[distance_to_stores.sort_by { |key, val| key }]
    nearest_stores.first(3).each do |distance, store|
      say "a #{distance.round} metros está #{store['title']}: con un descuendo de #{store['discount']}%"
    end
  end
end
