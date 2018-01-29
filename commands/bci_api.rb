require 'bci'
require_relative 'location_job'

OPTIONS = UI::QuickReplies.build(['Si', 'SI'],
                               ['No', 'NO'])

def separador_miles(numero)
  numero = String(numero).gsub(/\./,"")
  numero = numero.reverse!.gsub(/(?=\d*\.?)(\d{3})/){$1+'.'}
  numero = numero.reverse!.gsub(/^[\.]/,"")
  return numero
end
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
  def select_categories
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
    if message_contains_location?
      coords = @message.attachments.first['payload']['coordinates']
      lat = coords['lat']
      long = coords['long']
      parsed = get_parsed_response(REVERSE_API_URL, "#{lat},#{long}")
      address = extract_full_address(parsed) unless parsed.nil?
      @message.typing_off
      say "Al parecer estas cerca de #{address}"
      say 'dame un momento para buscar los mejores descuentos:'
      LocationJob.perform_async(BCI, lat, long, @user,@@category)
    else
      say "Hubo un problema al obtener la ubicacion"
    end
    stop_thread
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

  def validar_monto
    @message.mark_seen
    @message.typing_on
    begin
      @@montoCredito = @message.text.gsub(/([^\d*.])/,'')
      @@montoCredito = Integer(@@montoCredito.gsub(/\.*,*/,''))
      say 'Gracias, ahora necesito que me digas cuántas cuotas'
      next_command :validar_cuotas
    rescue
      say 'No entendí bien, ¿Puedes escribir de nuevo el monto?'
      next_command :validar_monto
    end
  end

  def validar_cuotas
    @message.mark_seen
    @message.typing_on
    begin
      @@cantidadCuotas = @message.text.gsub(/([^\d*.])/,'')
      @@cantidadCuotas = Integer(@@cantidadCuotas.gsub(/\.*,*/,''))
      say 'Entonces, quieres solicitar un crédito de $' + String(separador_miles(@@montoCredito)) + ' en ' + String(separador_miles(@@cantidadCuotas)) + ' cuotas',
      quick_replies: OPTIONS
      next_command :options
    rescue
      say 'No entendí bien, ¿Puedes escribir de nuevo el número de cuotas?'
      next_command :validar_cuotas
    end
  end

  def options
    @message.mark_seen
    if @message.quick_reply=="SI"
      simulate_credito_consumo
    elsif @message.quick_reply=="NO"
      say 'Al parecer ingresaste mal los datos'
      @message.typing_on
      say 'Voy a pedirtelos nuevamente'
      @message.typing_on
      say 'Por favor, escribe el monto'
      next_command :validar_monto
    else
      stop_thread
    end
  end

  def simulate_credito_consumo
    @message.mark_seen
    @message.typing_on
    say 'Dame un momento para poder calcular los datos'
    params = {'rut' => '7', 'dv' => '7', 'renta' => '7', 'montoCredito' => @@montoCredito, 'cantidadCuotas' => @@cantidadCuotas, "fechaPrimerVencimiento" => "7"}
    cons = BCI.consumo.simulate("1",params)
    if cons.any?
      @message.typing_on
      say 'El monto de cada cuota es de $' + String(separador_miles(cons["montoCuota"]))
    else
      @message.typing_on
      say 'Al parecer ocurrió un problema, por favor intentalo más tarde'
    end
    stop_thread
  end
end
