require 'bci'
require_relative 'location_job'
# Everything in this module will become private methods for Dispatch classes
# and will exist in a shared namespace.
module BciApi
  # State 'module_function' before any method definitions so
  # commands are mixed into Dispatch classes as private methods.
  module_function

  BCI = Bci::Client.new({ key: ENV['BCI_API_KEY'] })
  REVERSE_API_URL = 'https://maps.googleapis.com/maps/api/geocode/json?latlng='.freeze

  def economic_indicators
    say 'Dejame preguntarle a BCI acerca de los indicadores económicos'
    @message.typing_on unless @message.nil?
    kpis = BCI.stats.indicators['kpis']
    if kpis.any?
      list_indicators(kpis)
    else
      say 'Al parecer ocurrió un problema, por favor intentalo más tarde'
    end
  end

  def list_indicators(kpis)
    say 'Aqui tienes los indicadores económicos:'
    kpis.each do |kpi|
      say "#{kpi['title']}: #{kpi['price']}"
    end
  end

  # Lookup based on location data from user's device
  # Lookup based on location data from user's device
  def lookup_location
    case @message.quick_reply
    when 'SHOP'
      @@category = 'Shopping'
    when 'STORE'
      @@category = 'Tienda'
    when 'HEALTH'
      @@category = 'Salud'
    when 'ONLINE'
      @@category = 'Online'
    when 'VIEWS'
      @@category = 'Panoramas'
    when 'FLAVORS'
      @@category = 'Sabores'
    else
      @@category = ''
    end
    say 'comparteme tu ubicación para poder ayudarte',
    quick_replies: UI::QuickReplies.location
    next_command :handle_user_location
  end

  def handle_user_location
    @message.typing_on
    coords = @message.attachments.first['payload']['coordinates']
    lat = coords['lat']
    long = coords['long']
    parsed = get_parsed_response(REVERSE_API_URL, "#{lat},#{long}")
    address = extract_full_address(parsed) unless parsed.nil?
    @message.typing_off
    say "Al parecer estas cerca de #{address}"
    say 'dame un momento para buscar los mejores descuentos:'
    LocationJob.perform_async(BCI, lat, long, @user)
  end

  # Talk to API
  def get_parsed_response(url, query)
    response = HTTParty.get(url + query)
    parsed = JSON.parse(response.body)
    parsed['status'] != 'ZERO_RESULTS' ? parsed : nil
  end

  def extract_full_address(parsed)
    parsed['results'].first['formatted_address']
  end
end
