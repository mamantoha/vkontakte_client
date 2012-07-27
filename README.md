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
* `scope`: запрашиваемые [права доступа приложения](http://vkontakte.ru/developers.php?o=-1&p=%CF%F0%E0%E2%E0%20%E4%EE%F1%F2%F3%EF%E0%20%EF%F0%E8%EB%EE%E6%E5%ED%E8%E9)

``` ruby
vk.login!(email, pass, scope = 'friends')
```

### Вызов методов
После успешной авторизации Вы можете [осуществлять запросы к API](http://vk.com/developers.php?oid=-1&p=%D0%92%D1%8B%D0%BF%D0%BE%D0%BB%D0%BD%D0%B5%D0%BD%D0%B8%D0%B5_%D0%B7%D0%B0%D0%BF%D1%80%D0%BE%D1%81%D0%BE%D0%B2_%D0%BA_API) используя название метода из [списка функций API](http://vk.com/developers.php?oid=-1&p=%D0%9E%D0%BF%D0%B8%D1%81%D0%B0%D0%BD%D0%B8%D0%B5_%D0%BC%D0%B5%D1%82%D0%BE%D0%B4%D0%BE%D0%B2_API).
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