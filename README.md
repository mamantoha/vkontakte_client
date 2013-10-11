# vkontakte
Библиотека для авторизация клиентских приложений и для доступа к API ВКонтакте

## Использование

``` ruby
require 'vkontakte'
```

### Создание клиента
При клиентской авторизации ключ доступа к API `access_token` выдаётся приложению без необходимости раскрытия секретного ключа приложения.
Конструктор получает только один аргумент - идентификатор приложения ВКонтакте.
``` ruby
vk = Vkontakte::Client.new(CLIENT_ID)
```

### Авторизация по логину и паролю
Для вызова большинства методов требуется токен доступа (`access token`).

Метод `login!` принимает следующие аргументы:
* `email`: логин пользователя
* `pass`: пароль
* `permissions`: запрашиваемые [права доступа приложения](http://vk.com/dev/permissions)

``` ruby
vk.login!(email, pass, permissions: 'friends')
```

### Вызов методов
После успешной авторизации Вы можете [осуществлять запросы к API](http://vk.com/dev/api_requests) используя название метода из [списка функций API](http://vk.com/dev/methods).
Параметры соответствующего метода API передаются как хєш.
Следует заметить что метод вида `friends.get` нужно передавать как `friends_get`.
``` ruby
vk.api.friends_get(fields: 'online', order: 'name', name_case: 'dat')
```

### Авторизация по токену
Полезно сохранить полученный токен (и, при необходимости, id пользователя)
``` ruby
access_token = vk.access_token
user_id = vk.user_id
```
чтобы использовать их повторно
``` ruby
api = Vkontakte::API.new(access_token)
api.friends_get(fields: 'online', order: 'name', name_case: 'dat')
```
