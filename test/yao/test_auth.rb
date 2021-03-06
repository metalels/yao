class TestAuth < Test::Unit::TestCase
  include AuthStub

  def setup
    @auth_url = "http://endpoint.example.com:12345"
    username = "udzura"
    tenant   = "example"
    password = "XXXXXXXX"

    stub_auth_request(@auth_url, username, password, tenant)

    Yao.config.set :auth_url, @auth_url
    @token = Yao::Auth.new(tenant_name: tenant, username: username, password: password)
  end

  def teardown
  end

  def test_auth_successful
    cli = Yao.default_client.pool["default"]
    assert { cli.url_prefix.to_s == "http://endpoint.example.com:12345/" }
  end

  def test_service_sclients_initialized
    %w(compute network image identity).each do |service|
      cli = Yao.default_client.pool[service]
      assert { !cli.nil? }
    end
  end

  def test_nova_tenant_logged_in
    tenant_id = "b598bf98671c47e1b955f8c9660e3c44"
    cli = Yao.default_client.compute
    assert { cli.url_prefix.to_s == "http://nova-endpoint.example.com:8774/v2/#{tenant_id}" }
  end

  def test_neutron_prefix_added
    cli = Yao.default_client.network
    assert { cli.url_prefix.to_s == "http://neutron-endpoint.example.com:9696/v2.0" }
  end

  def test_token_is_valid
    assert { @token.token == "aaaa166533fd49f3b11b1cdce2430000" }
    assert { @token.expire_at - @token.issued_at == 3600 }
    assert { @token.endpoints.size == 4 }
  end

  def test_hooked_by_configure_block
    auth = Yao::Auth
    stub(auth).new

    Yao.configure do
      auth_url    "http://endpoint.example.com:12345"
      tenant_name "example"
      username    "udzura"
      password    "XXXXXXXX"
    end
    assert_received(auth) {|a| a.new }
  end
end
