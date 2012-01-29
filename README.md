# vkontakte

## Example
 
``` ruby
require 'vkontakte'
vk = Vkontakte::Client.new(CLIENT_ID, CLIENT_SECRET)
vk.login!(email, pass)
friends = vk.api.friends_get(:fields => 'online')
```