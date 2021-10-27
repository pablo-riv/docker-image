Geocoder.configure(
  # geocoding options
  timeout: 3,
  lookup: :google,
  # language: :en,
  use_https: true,
  # :http_proxy   => nil,         # HTTP proxy server (user:pass@host:port)
  # :https_proxy  => nil,         # HTTPS proxy server (user:pass@host:port)
  api_key: 'AIzaSyBLjlaTDht84siimhFJ6XvfR8KxAU-fQ6o',
  # :cache        => nil,         # cache object (must respond to #[], #[]=, and #keys)
  # :cache_prefix => "geocoder:", # prefix (string) to use for all cache keys

  # exceptions that should not be rescued by default
  # (if you want to implement custom error handling);
  # supports SocketError and TimeoutError
  # :always_raise => [],

  # calculation options
  units: :km
  # :distances => :linear    # :spherical or :linear
)
