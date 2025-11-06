# Requestkit

Local HTTP request toolkit for development. Test Stripe webhooks, GitHub hooks or any HTTP endpoint locally. Your data stays private, works offline and runs fast without network latency.


![Screenshot of the Requestkit UI, listing POST requests to Stripe, GitHub, Twilio and Shopify](https://raw.githubusercontent.com/Rails-Designer/requestkit/HEAD/.github/screenshot.jpg)


**Sponsored By [Rails Designer](https://railsdesigner.com/)**

<a href="https://railsdesigner.com/" target="_blank">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/Rails-Designer/requestkit/HEAD/.github/logo-dark.svg">
    <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/Rails-Designer/requestkit/HEAD/.github/logo-light.svg">
    <img alt="Rails Designer" src="https://raw.githubusercontent.com/Rails-Designer/requestkit/HEAD/.github/logo-light.svg" width="240" style="max-width: 100%;">
  </picture>
</a>


## Installation

If you have a Ruby environment available, you can install Requestkit globally:
```bash
gem install requestkit
```


## Usage

Start the server:
```bash
requestkit
```

This starts Requestkit on `http://localhost:4000`. Send any HTTP request to test:
```bash
curl -X POST http://localhost:4000/stripe/webhook \
  -H "Content-Type: application/json" \
  -d '{"event": "payment.succeeded", "amount": 2500}'
```

Open `http://localhost:4000` in your browser to see all captured requests with headers and body.


### Custom Port

```bash
requestkit --port 8080
```


### Persistent Storage

By default, requests are stored in memory and cleared when you stop the server. Use file storage to persist across restarts:
```bash
requestkit --storage file
```

Requests are saved to `~/.config/requestkit/requestkit.db`.


### Custom Database Path

```bash
requestkit --storage file --database-path ./my-project.db
```


## Configuration

Create a configuration file to set defaults:

**User-wide settings** (`~/.config/requestkit/config.yml`):

```yaml
port: 5000
storage: file
```

**Project-specific settings** (`./.requestkit.yml`):

```yaml
storage: memory
default_namespace: my-rails-app
```

Configuration precedence: CLI flags > project config > user config > defaults


### Available Options

| Option | Description | Default |
|--------|-------------|---------|
| `port` | Server port | `4000` |
| `storage` | Storage type: `memory` or `file` | `memory` |
| `database_path` | Database file location | `~/.config/requestkit/requestkit.db` |
| `default_namespace` | Default namespace for root requests | `default` |


## Namespaces

Requestkit automatically organizes requests by namespace using the first path segment:
```bash
# Namespace: stripe
curl http://localhost:4000/stripe/payment-webhook

# Namespace: github
curl http://localhost:4000/github/push-event
```

Filter by namespace in the web UI. Requests to `/` use the `default_namespace` from your config.


## Help

```bash
requestkit help
```


## License

Perron is released under the [MIT License](https://opensource.org/licenses/MIT).
