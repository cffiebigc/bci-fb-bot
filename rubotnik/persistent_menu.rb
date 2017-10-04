# rubocop:disable all
module Rubotnik
  # Enables persistent menu for your bot
  class PersistentMenu
    def self.enable
      # Design your persistent menu here:
      Facebook::Messenger::Profile.set({
        persistent_menu: [
          {
            locale: 'default',
            # If this option is set to true,
            # user will only be able to interact with bot
            # through the persistent menu
            # (composing a message will be disabled)
            composer_input_disabled: false,
            call_to_actions: [
              {
                title: 'Indicadores Económicos',
                type: 'postback',
                payload: 'INDICADORES'
              },
              {
                title: 'Descuentos cercanos',
                type: 'postback',
                payload: 'DESCUENTOS'
              }
            ]
          }
        ]
        }, access_token: ENV['ACCESS_TOKEN'])
    end
  end
end
