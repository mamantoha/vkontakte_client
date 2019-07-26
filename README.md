# vkontakte

Ruby library for authorization of client applications and for access to the VK API

## Usage

``` ruby
require 'vkontakte'
```

## Application registration

You must register your application in order to use all the capabilities of API VKontakte.

Open the page “Managed apps” in the left menu, then press “Create an app”. You will be directed to the page <https://vk.com/editapp?act=create>.

You need to choose _Standalone-app_.

After confirming the action, you will be redirected to the page with information about the app. Open the page "Settings" in the left-hand menu and you will see the field "ID applications", in which a number will be located. For example, `5490057`. This number is the application identification, a.k.a. `API_ID`, `APP_ID`, `client_id`, and you will need it for your future work.

### Initialize Vkontakte client

With client authorization, the access key to the API `access_token`.
The constructor takes only one argument - the VK application ID - `CLIENT_ID`.

``` ruby
vk = Vkontakte::Client.new(CLIENT_ID)
```

### Login and password authorization

In general, for API identification, a special access key is used which is called `access_token`. This token is a string of numbers and Latin letters which you send to the server along with the request.

This library supports the [Implicit flow](https://vk.com/dev/implicit_flow_user) way to obtain an OAuth 2.0 access key:
th 2.0:

The `login!` method takes the following arguments:

* `email`: user login
* `pass`: user password
* `permissions`: requeste [application permissions](https://vk.com/dev/permissions)

``` ruby
vk.login!(email, pass, permissions: 'friends')
```

### API Requests

After successful authorization, you can [make requests to the API](http://vk.com/dev/api_requests) using the method name from the [API function list](http://vk.com/dev/methods).

The parameters of the corresponding API method are passed as `Hash`.
Note that a method like `friends.get` needs to be passed as `friends_get`.

``` ruby
vk.api.friends_get(fields: 'online', order: 'name', name_case: 'dat')
```

To avoid errors, you can pre-check the status of the user using the `account.getInfo` method.

```ruby
vk.api.account_getInfo
```

### Token Authorization

It is useful to save the received `access_token` (and, if necessary, the `user_id`) to reuse them

``` ruby
access_token = vk.access_token
user_id = vk.user_id
```

``` ruby
api = Vkontakte::API.new(access_token)
api.friends_get(fields: 'online', order: 'name', name_case: 'dat')
```
