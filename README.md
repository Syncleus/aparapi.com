```
bundle install or bundle update
bower install
bundle exec middleman serve
bundle exec middleman build
```

on Mac OSX The following is needed to properly execute the first line to get ffi t install (might need to repeat again without env variables after ffi installs if other packages fail.)

```
LDFLAGS="-L/usr/local/opt/libffi/lib" PKG_CONFIG_PATH="/usr/local/opt/libffi/lib/pkgconfig" bundle install --path vendor
```

Alternatively compile it using a docker container:

```
UID=${UID} GID=${GID} docker-compose up
```
