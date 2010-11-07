# -*- encoding: utf-8 -*-

require_relative '../lib/vkontakte'

if __FILE__ == $0
  APP_ID = '1915108'

  email = 'anton.linux@gmail.com'
  pass = ''

  # Заміна, щоб правильно передавалися символи
  tr = {"&#39;"  => "'",
        "&quot;" => "\"",
        "&amp;"  => "&",
        "&lt;"   => "<",
        "&qt;"   => ">"
  }


  vk = VK::DesktopAuth.new(APP_ID) { |auth| auth.login!(email, pass) }
  mid, sid, secret = vk.mid, vk.sid, vk.secret

  api = VK::API.new(APP_ID, mid, sid, secret)
  puts api.getProfiles({:uids => mid, :fields => 'photo_big,sex,country,city'})

  # Перший елемент масиву  - загальна кількість записів(створених не раніше вказаного timestamp). Відкидаємо його.
  activities = api.activity_getNews[1..-1]
  # Формуємо рядок з uid-ами для подальшого використання у функції getProfiles
  uids = activities.map{|i| i['uid']}.uniq.join(',')
  profiles = api.getProfiles(:uids => uids)
  activities.each do |activity|
    profile = profiles.find {|i| i['uid'] == activity['uid']}
    puts "[#{Time.at(activity['timestamp'])}] #{profile['first_name']} #{profile['last_name']}: #{activity['text'].strtr(tr)}"
  end

end
