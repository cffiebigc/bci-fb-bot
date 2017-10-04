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
    say 'Aqui tienes los descuentos cercanos a tu ubicación:'
    nearest_stores = Hash[distance_to_stores.sort_by { |key, val| key }]
    nearest_stores.first(3).each do |distance, store|
      UI::FBCarousel.new(store_template(store, distance)).square_images.send(@user)
    end
  end

  def store_template(store, distance)
    puts store['covers'].first
    [
      {
        title: "#{store['discount']}% descuento en #{store['title']}",
        # Horizontal image should have 1.91:1 ratio
        image_url: store['covers'].first || 'https://bci.modyocdn.com/uploads/d8ad8d0e-e049-4eea-b81d-9fb14cdce367/original/descuentos-generico-descuento_.jpg',
        subtitle: "a #{distance.round} metros de tu ubicación, en #{store['location_street']}",
        default_action: {
          type: 'web_url',
          url: store['url']
        },
        buttons: [
          {
            type: :web_url,
            url: store['url'],
            title: 'Sitio web'
          }
        ]
      }
    ]
  end
end
