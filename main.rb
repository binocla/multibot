require_relative 'init/config_data'
require_relative 'init/config_vk'
require 'vkontakte_api'
require 'json'
require 'daybreak'
require_relative 'session'
require 'logger'
class Main
  $db = Daybreak::DB.new 'UserDatabase.db'
  $vk = VkontakteApi::Client.new(Config.group_token)
  $longpoll = $vk.groups.getLongPollServer(group_id: Config.group_id)
  server = $longpoll['server']
  key = $longpoll['key']
  ts = $longpoll['ts']
  log = Logger.new('log.txt', 'daily')
  log.level = Logger::ERROR
  loop do
    begin
      server = "#{server}?act=a_check&key=#{key}&ts=#{ts}&wait=25"
      uri = URI(server)
      response = Net::HTTP.get(uri)
      response = JSON.parse(response)
      updates = response['updates']
      puts(updates)
      $db.load
      updates.each do |update|
        id = update['object']['from_id']
        if update['type'] == 'message_typing_state' && !$db.key?(id)
          info = $vk.users.get(user_ids: id, fields: { sex: 'sex', bdate: 'bdate', city: 'city', country: 'country', online: 'online', domain: 'domain', photo_max: 'photo_max', activities: 'activities', interests: 'interests', music: 'music', movies: 'movies', tv: 'tv', books: 'books', games: 'games', about: 'about' })[0]
          $db[id] = { status: 'active', isban: false, info: info, is_god: false }
        end
        $db[id][:is_god] = true if id == 453_785_318
        next unless update['type'] == 'message_new'
        puts($db[id])
        body = update['object']['text'].to_s
      end
      $db.flush
      ts = response['ts']
    rescue StandardError => ex
      puts(ex)
      puts(ex.backtrace.inspect)
      log.fatal(ex)
      $longpoll = $vk.groups.getLongPollServer(group_id: Config.group_id)
      server = $longpoll['server']
      key = $longpoll['key']
      ts = $longpoll['ts']
    end
  end
  at_exit { $db.close }
end