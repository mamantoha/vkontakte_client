# vkontakte

Библиотека для авторизация клиентских приложений и для доступа к API ВКонтакте

## Использование

``` ruby
require 'vkontakte'
```

## Регистрация приложения

Вам необходимо зарегистрировать свое приложение, чтобы использовать все возможности API ВКонтакте.

Откройте страницу «Управление» в левом меню, затем нажмите «Создать приложение» — Вы попадете на страницу https://vk.com/editapp?act=create

Нужно выбрать Standalone-приложение.

После подтверждения действия Вы попадете на страницу с информацией о приложении.
Откройте вкладку "Настройки" в меню слева. Вы увидите поле "ID приложения", в котором будет указано число, например, 5490057.
Это число — идентификатор приложения, он же `API_ID`, `APP_ID`, `CLIENT_ID`, оно потребуется Вам в дальнейшей работе.

### Создание клиента

При клиентской авторизации ключ доступа к API `access_token` выдаётся приложению без необходимости раскрытия секретного ключа приложения.
Конструктор получает только один аргумент - идентификатор приложения ВКонтакте - `CLIENT_ID`.

``` ruby
vk = Vkontakte::Client.new(CLIENT_ID)
```

### Авторизация по логину и паролю

Для работы с большинством методов API Вам необходимо передавать в запросе `access_token` — специальный ключ доступа.

Эта библиотека поддерживаем [Implicit flow](https://vk.com/dev/implicit_flow_user) способ получения ключа доступа по OAuth 2.0:

Метод `login!` принимает следующие аргументы:
* `email`: логин пользователя
* `pass`: пароль
* `permissions`: запрашиваемые [права доступа приложения](https://vk.com/dev/permissions)

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

Чтобы избежать появления ошибок, Вы можете предварительно проверять состояние пользователя методом `account.getInfo`.

```ruby
vk.api.account_getInfo
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
