<p align="right">
  <img width="100" height="100" alt="ascii bird" src="https://github.com/user-attachments/assets/830d04bd-f21d-49b5-b427-e903b623b50c" />
</p>

# 🐦‍⬛ JSON hub

We have [RSSHub](https://github.com/DIYgod/RSSHub) for RSS - now [**JSON hub**](https://github.com/Seryiza/JSONhub) for JSON.

## Hmm?

JSON hub has simple and independent scripts to get (parse, scrap) information as JSON from web services you use (YouTube, Reddit, Steam, Marketplaces, etc).

Without dependencies, without shared functions, and I try to maintain them stupid but it works.

## Usage

You can use it via DevTools (copy-paste to DevTools Console) or external tools (execute JS in playwright).

## Available scripts

| Script | Description |
| ---    | ---         |
| `scripts/youtube-subscriptions.js` | exports your YouTube subscriptions as a JSON array |

## Development

### Setup

```bash
nix develop
bun install
```

### Browser

The Nix shell makes `google-chrome-stable` and `playwright-cli` share the same profile at `.jsonhub/chrome-profile` by default.

So the usual flow is:

```bash
# open chrome, log in, close it
google-chrome-stable https://youtube.com

# run playwright-cli to experiment or test with the same account
bunx playwright-cli open https://youtube.com/feed
bunx playwright-cli snapshot
bunx playwright-cli close
```

### Testing

Fixture files live in `test/`.

Naming:
- `test/<script-name>.contains.json`

Behavior:
- `make test-via-playwright <script-name>` loads the matching fixture
- a fixture may be a single object or an array of objects
- matching is partial: each fixture object only needs to be contained inside one output object
