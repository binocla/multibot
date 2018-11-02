require 'vkontakte_api'
  class ConfigVk
    VkontakteApi.configure do |config|
      config.api_version = '5.80'
      config.adapter = :net_http
    end
  end