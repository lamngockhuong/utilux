# Utilux Website

Documentation website for Utilux built with Astro + Tailwind CSS v4.

## Tech Stack

- **Framework:** [Astro](https://astro.build) v5
- **Styling:** [Tailwind CSS](https://tailwindcss.com) v4
- **Package Manager:** pnpm

## Project Structure

```
website/
├── src/
│   ├── components/       # Reusable components
│   │   ├── CopyButton.astro
│   │   └── ScriptCard.astro
│   ├── layouts/
│   │   └── BaseLayout.astro
│   ├── pages/
│   │   ├── index.astro         # Home page
│   │   ├── docs/index.astro    # Documentation
│   │   └── catalog/            # Script catalog
│   │       ├── index.astro
│   │       └── [slug].astro
│   └── styles/
│       └── global.css
├── public/               # Static assets
├── astro.config.mjs
├── tailwind.config.mjs
└── package.json
```

## Commands

| Command        | Action                                 |
| :------------- | :------------------------------------- |
| `pnpm install` | Install dependencies                   |
| `pnpm dev`     | Start dev server at `localhost:4321`   |
| `pnpm build`   | Build production site to `./dist/`     |
| `pnpm preview` | Preview build locally before deploying |

## Development

```bash
# Install dependencies
pnpm install

# Start development server
pnpm dev

# Build for production
pnpm build
```

## Pages

| Route            | Description                   |
| :--------------- | :---------------------------- |
| `/`              | Home - features, quick start  |
| `/docs`          | Documentation - usage, config |
| `/catalog`       | Script catalog with search    |
| `/catalog/:slug` | Individual script details     |

## Data Source

Script data is loaded from `../registry/manifest.json` at build time.
