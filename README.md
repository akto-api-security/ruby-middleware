# ruby-middleware

If you have a Ruby-on-Rails application, you can use `AktoMiddleware` to automatically populate API Inventory for you. 
`AktoMiddleware` will take a copy of API request-response and send to Akto for analysis. 

Here are the steps - 

1. Add `rdkafka` and `json` in your gem file.
2. Add `require_relative "../middleware/akto-middleware"` in your application.rb file
3. Add the following middleware in your Application:
```
config.middleware.insert_before ActionDispatch::Static, AktoRack::AktoMiddleware, {}
```
4. Restart your rails server. 
