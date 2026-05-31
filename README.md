# TAMIS АГРО — full-stack e-commerce & content platform for agro-biopreparates

> Ukrainian agro-marketplace built on the **FARM stack** (FastAPI · React 19 · MongoDB) with a deep admin/CRM layer, Ukrainian-delivery integration (Nova Poshta / Укрпошта), Stripe payments, Google OAuth, Tiptap-powered blog and Figma-pixel-accurate marketing pages.

![stack](https://img.shields.io/badge/python-3.11+-3776AB?logo=python&logoColor=white)
![stack](https://img.shields.io/badge/FastAPI-0.110-009688?logo=fastapi&logoColor=white)
![stack](https://img.shields.io/badge/React-19-61DAFB?logo=react&logoColor=white)
![stack](https://img.shields.io/badge/TypeScript-5-3178C6?logo=typescript&logoColor=white)
![stack](https://img.shields.io/badge/MongoDB-7-47A248?logo=mongodb&logoColor=white)
![stack](https://img.shields.io/badge/Tailwind-3-38B2AC?logo=tailwindcss&logoColor=white)

---

## 📑 Table of contents

1. [What it is](#-what-it-is)
2. [Feature map](#-feature-map)
3. [Architecture](#-architecture)
4. [Repository layout](#-repository-layout)
5. [Data model](#-data-model)
6. [API surface](#-api-surface)
7. [Integration logic](#-integration-logic)
8. [Frontend routing & pages](#-frontend-routing--pages)
9. [Quick start — bootstrap.sh](#-quick-start--bootstrapsh)
10. [Manual setup](#-manual-setup)
11. [Environment variables](#-environment-variables)
12. [Test credentials](#-test-credentials)
13. [Common dev commands](#-common-dev-commands)
14. [Deployment notes](#-deployment-notes)
15. [Troubleshooting](#-troubleshooting)

---

## 🌱 What it is

**TAMIS АГРО** is a production-grade storefront for selling **biological plant-protection products** (biopreparates) to Ukrainian farmers. It is not a generic shop template — it is a domain-specific platform with:

- A **catalog** that links every product to one or more **crops (cultures)** and to **regional categories**, with per-package variants and bulk pricing.
- An **abandoned-cart / upsell engine** baked into a separate `sales` (CRM) module so the sales team can recover orders, push upsells and manage the funnel.
- A **rich content layer**: Tiptap blog with image uploads, FAQ, policies, partner directory ("Нам довіряють"), cultures glossary, reviews with photos, customer-callback forms.
- A **dual auth** model — JWT-based email/password **plus** Google OAuth for customers, and a separate elevated **admin** JWT used by the back-office.
- **Ukrainian delivery integrations**: Nova Poshta (cities, warehouses, ТТН candidates) and Укрпошта (lookups).
- **Stripe** card payments + an offline **payment-proof upload** (the buyer attaches a receipt photo for bank-transfer orders).
- A custom **Figma-driven design system** — components live under `frontend/src/components/welcome/...` and reflect the original Figma frames pixel-for-pixel (including the decorative perspective grid in *Нам довіряють*).

---

## 🧩 Feature map

| Surface                | Highlights                                                                                                                       |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| **Storefront**         | Hero, USP grid, catalog, single-product page, crop-based filtering, reviews carousel, FAQ, blog, contact, policies              |
| **Cart & Checkout**    | Persistent cart (guest + logged-in merge), multi-step checkout, Nova Poshta / Укрпошта address picker, Stripe + offline payment |
| **Customer account**   | Profile, address book, order history, order detail with payment-proof upload, password change                                    |
| **Auth**               | Email/password (bcrypt), JWT cookies, Google OAuth, password reset stubs                                                         |
| **Admin panel**        | Dashboard, products & categories CRUD, blog editor (Tiptap), FAQ, policies, partners, cultures, reviews moderation, users        |
| **Sales / CRM**        | Sales dashboard, orders pipeline, abandoned-cart recovery, upsell management, payment-proof verification                         |
| **Content & SEO**      | Tiptap blog with media uploads, partner directory with logos, dynamic culture pages, OG-friendly metadata                        |
| **Notifications**      | In-app notification model + admin notification center                                                                            |
| **Design system**      | Figma-accurate sections, mobile-only decorative perspective grid (radial-gradient depth), shadcn/ui primitives                   |

---

## 🏛 Architecture

```
                            ┌───────────────────────────────────┐
                            │            Browser                 │
                            │  React 19 + TS + Tailwind + shadcn │
                            └──────────────┬────────────────────┘
                                           │   HTTPS, fetch() with credentials
                                           │   Base URL = REACT_APP_BACKEND_URL
                                           ▼
                            ┌───────────────────────────────────┐
                            │       FastAPI 0.110 (Uvicorn)      │
                            │   /api/* gateway → 25+ routers     │
                            └──┬────────┬────────────┬──────────┘
                               │        │            │
                               │        │            └─► Static /uploads/* (blog, reviews,
                               │        │                products, payment_proofs)
                               │        │
                               │        ▼
                               │   ┌──────────────────────────┐
                               │   │ Third-party integrations  │
                               │   │  • Nova Poshta REST       │
                               │   │  • Укрпошта REST          │
                               │   │  • Stripe API             │
                               │   │  • Google OAuth 2.0       │
                               │   │  • Emergent LLM (opt)     │
                               │   └──────────────────────────┘
                               ▼
                            ┌──────────────────────────────────┐
                            │           MongoDB 7              │
                            │   Database: $DB_NAME             │
                            │   Collections: products, orders, │
                            │   carts, users, blog_posts,      │
                            │   reviews, cultures, partners,   │
                            │   faq, policies, contact_*,      │
                            │   notifications, sales_*, ...    │
                            └──────────────────────────────────┘
```

### Backend internals

* **`server.py`** wires Motor → MongoDB, mounts the `/api` `APIRouter`, includes every feature router, runs all `seed_*_if_empty()` hooks on startup and serves the upload directories under `/uploads/*`.
* Each feature owns a file (`<feature>_routes.py`) that **builds its own router** with a `build_<feature>_router(db)` factory taking the shared Motor handle — this is what allows a single Mongo connection to be reused everywhere without globals.
* The **`sales/`** subpackage is a self-contained CRM module with its own router, security helpers and Mongo migrations (`migrate_orders_payment_fields`, `seed_demo_upsells_if_empty`).
* JWT signing is shared (`JWT_SECRET` / `JWT_ALG`) but **two audiences** exist: customer (`auth_routes.py`) and admin (`admin_routes.py`).

### Frontend internals

* CRA-style React 19 + TypeScript, **Tailwind 3** for utilities, **shadcn/ui** as the component primitives layer, custom **Figma components** under `src/components/welcome/`.
* `App.tsx` declares all routes; the storefront, customer profile and `/admin/*` are split into clear layouts (`ProfileLayout`, `AdminLayout`).
* Network calls always use `import.meta.env.REACT_APP_BACKEND_URL` (or `process.env.REACT_APP_BACKEND_URL`) — never hard-coded.
* Decorative assets live in `frontend/public/` (logos, partner SVGs, the **`trust-grid-pattern.svg`** that drives the *Нам довіряють* depth effect).

---

## 📂 Repository layout

```
.
├── backend/
│   ├── server.py                  # Uvicorn entrypoint, router wiring, startup seeds
│   ├── requirements.txt
│   ├── auth_routes.py             # customer auth (email/pwd + Google OAuth)
│   ├── admin_routes.py            # admin JWT, admin-only guards
│   ├── cart_routes.py             # persistent cart (guest + user merge)
│   ├── orders_routes.py           # order lifecycle, payment-proof uploads
│   ├── profile_routes.py          # /me, profile updates, password change
│   ├── addresses_routes.py        # saved delivery addresses
│   ├── np_routes.py               # Nova Poshta proxy (cities, warehouses)
│   ├── up_routes.py               # Укрпошта proxy
│   ├── blog_routes.py             # Tiptap-backed CMS + image uploads
│   ├── reviews_routes.py          # product reviews + photo uploads
│   ├── cultures_routes.py         # crop directory (рослини, культури)
│   ├── trusted_partners_routes.py # "Нам довіряють" directory
│   ├── faq_routes.py              # FAQ entries
│   ├── policies_routes.py         # legal pages
│   ├── inside_routes.py           # "Все про …" tabbed marketing blocks
│   ├── contact_info_routes.py     # contact details (phones, addr, schedule)
│   ├── contact_messages_routes.py # contact-form submissions
│   ├── callback_routes.py         # "Замовити дзвінок"
│   ├── products/                  # products router + security + upload helpers
│   └── sales/                     # CRM subpackage
│       ├── router.py
│       ├── dashboard.py
│       ├── orders_admin.py
│       ├── carts_admin.py
│       ├── upsells_admin.py
│       ├── models.py
│       └── security.py
│
├── frontend/
│   ├── package.json
│   ├── public/                    # static assets, logos, trust-grid-pattern.svg
│   └── src/
│       ├── App.tsx                # router root
│       ├── App.css / index.css
│       ├── ScrollToTop.tsx
│       ├── components/
│       │   ├── ui/                # shadcn primitives
│       │   └── welcome/           # Figma-derived sections (frame-component*)
│       └── pages/
│           ├── desktop1.tsx       # home (Welcome) — composed from frame-components
│           ├── catalog.tsx        # product catalog with filters
│           ├── cultures.tsx       # crop directory
│           ├── blog.tsx / blog-post.tsx
│           ├── about.tsx, contacts.tsx
│           ├── checkout.tsx
│           ├── profile*.tsx       # profile / orders / addresses
│           └── admin/             # AdminDashboard, AdminProducts, AdminBlog,
│                                  # AdminOrders, AdminSalesDashboard, …
│
├── .env.example                   # root-level pointer
├── backend/.env.example
├── frontend/.env.example
├── bootstrap.sh                   # one-shot dev setup
├── .gitignore
└── README.md                      # ← you are here
```

---

## 🗃 Data model

The most relevant collections (created lazily by the seed hooks):

| Collection            | Purpose                                                                          |
| --------------------- | -------------------------------------------------------------------------------- |
| `users`               | Customers (bcrypt password hash, addresses, OAuth ids)                           |
| `admins`              | Back-office users (separate JWT audience)                                        |
| `products`            | SKUs, variants, prices, gallery, linked cultures & categories                    |
| `product_categories`  | Catalog taxonomy                                                                 |
| `cultures`            | Crop directory (іконка, опис, related products)                                   |
| `trusted_partners`    | "Нам довіряють" logos & URLs                                                     |
| `carts`               | Persistent carts (`anonymous_id` or `user_id`)                                    |
| `orders`              | Orders + delivery info + payment status + payment-proof paths                    |
| `addresses`           | Saved delivery addresses per user                                                |
| `blog_posts`          | Tiptap JSON content, slug, SEO meta, cover image                                 |
| `reviews`             | Product reviews with star rating + photo paths                                   |
| `faq`                 | FAQ items grouped by section                                                     |
| `policies`            | Legal pages (Privacy, ToS…)                                                      |
| `inside_tabs`         | "Все про продукт" tabbed content blocks                                          |
| `contact_info`        | Static contact details                                                           |
| `contact_messages`    | Submissions from the contact form                                                |
| `callbacks`           | "Замовити дзвінок" requests                                                      |
| `notifications`       | In-app admin notifications                                                       |
| `sales_upsells`       | Upsell offers shown post-purchase                                                |
| `sales_*`             | CRM dashboards & funnels                                                         |

---

## 🔌 API surface

All endpoints live under the **`/api`** prefix. A non-exhaustive map (every router file declares 1-12 endpoints):

```
GET    /api/                          health
GET    /api/status                    legacy health checks

# Auth
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/logout
GET    /api/auth/me
GET    /api/auth/google/start
GET    /api/auth/google/callback
GET    /api/auth/test-credentials     ← dev-only helper

# Catalog
GET    /api/products              ?category=&culture=&search=
GET    /api/products/{slug}
GET    /api/product-categories
GET    /api/cultures

# Cart / Orders
GET    /api/cart
POST   /api/cart/items
PATCH  /api/cart/items/{id}
DELETE /api/cart/items/{id}
POST   /api/orders                   create order from cart
GET    /api/orders/{id}
POST   /api/orders/{id}/payment-proof (multipart upload)

# Profile
GET    /api/profile
PATCH  /api/profile
POST   /api/profile/password
GET    /api/addresses    POST /api/addresses    PATCH /api/addresses/{id}    DELETE /api/addresses/{id}

# Content
GET    /api/blog                 ?page=&search=
GET    /api/blog/{slug}
GET    /api/reviews              ?product=
GET    /api/faq
GET    /api/policies/{slug}
GET    /api/inside-tabs
GET    /api/trusted-partners
GET    /api/contact-info
POST   /api/contact-messages
POST   /api/callbacks

# Delivery
GET    /api/np/cities            ?q=
GET    /api/np/warehouses        ?city_ref=
GET    /api/up/...               (Укрпошта)

# Admin (JWT-guarded)
POST   /api/admin/login
*      /api/admin/...            full CRUD for every collection above

# Sales / CRM
GET    /api/sales/dashboard
GET    /api/sales/orders
PATCH  /api/sales/orders/{id}
GET    /api/sales/abandoned-carts
*      /api/sales/upsells
```

Use the admin panel under `/admin` (frontend) for an interactive surface over these endpoints.

---

## 🔗 Integration logic

### 1. Nova Poshta (Ukrainian delivery)

* Backend file: `np_routes.py`
* Reads `NOVA_POSHTA_API_KEY`. If missing → endpoints return a graceful empty result so the storefront still loads.
* Frontend uses these endpoints inside the checkout to populate the **city autocomplete** and the **warehouse picker**.

### 2. Укрпошта

* Backend file: `up_routes.py`. Same pattern as Nova Poshta.

### 3. Stripe

* `STRIPE_API_KEY` enables card payments at checkout (Payment Intents).
* `STRIPE_WEBHOOK_SECRET` lets the backend verify async webhooks (`payment_intent.succeeded`, `…failed`) and update the order status atomically.

### 4. Google OAuth (customer login)

* `GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_CLIENT_SECRET`, `GOOGLE_OAUTH_REDIRECT_URI`.
* Flow lives in `auth_routes.py`: `GET /api/auth/google/start` → redirect to Google → `GET /api/auth/google/callback` → user is upserted into `users` and a JWT cookie is set.

### 5. Emergent LLM (optional)

* `EMERGENT_LLM_KEY` unlocks AI helpers (blog draft generation, product copy rewrites). Strictly opt-in — no feature *requires* it.

### 6. Auth model

* Two JWTs are signed with the same `JWT_SECRET` + `JWT_ALG` but carry different audience claims; the corresponding helper functions live in `auth_routes.py` / `admin_routes.py` / `sales/security.py` / `products/security.py`.
* `JWT_EXPIRES_DAYS` defaults to `30`.

### 7. File uploads

* Each upload-capable router defines its own directory (`UPLOAD_DIR`, `REVIEWS_UPLOAD_DIR`, `PRODUCTS_UPLOAD_DIR`, `PAYMENT_PROOF_DIR`).
* Files are served back via FastAPI `StaticFiles` mounts in `server.py`.
* For production, put a CDN or Nginx in front to offload static delivery.

---

## 🖥 Frontend routing & pages

| Route                    | Component                  | Notes                                    |
| ------------------------ | -------------------------- | ---------------------------------------- |
| `/`                      | `pages/desktop1.tsx`       | Welcome / home (Figma frame composition) |
| `/catalog`               | `pages/catalog.tsx`        | Catalog with filters                     |
| `/cultures`              | `pages/cultures.tsx`       | Crop directory                           |
| `/blog`, `/blog/:slug`   | `pages/blog*.tsx`          | Tiptap-rendered posts                    |
| `/about`, `/contacts`    | static marketing pages     |                                          |
| `/checkout`              | `pages/checkout.tsx`       | Multi-step + NP/UP pickers + Stripe      |
| `/profile/*`             | `pages/profile*.tsx`       | Customer dashboard                       |
| `/admin/*`               | `pages/admin/Admin*.tsx`   | Back-office (JWT-protected)              |

---

## 🚀 Quick start — `bootstrap.sh`

The repo ships with an opinionated one-shot script:

```bash
# 1. Clone the repo
git clone https://github.com/ank645390-star/aggro.git
cd aggro

# 2. Run the bootstrap (installs deps, copies env templates, seeds Mongo)
chmod +x bootstrap.sh
./bootstrap.sh

# 3. Start the services
#    Terminal 1
cd backend && source .venv/bin/activate \
  && uvicorn server:app --host 0.0.0.0 --port 8001 --reload

#    Terminal 2
cd frontend && yarn start

# 4. Open http://localhost:3000
```

Bootstrap flags:

| Flag              | Effect                                  |
| ----------------- | --------------------------------------- |
| `--skip-backend`  | Only install frontend deps              |
| `--skip-frontend` | Only install backend deps               |
| `--reset-env`     | Overwrite existing `.env` from template |
| `-h`, `--help`    | Show inline help                        |

Prerequisites: **Python 3.11+**, **Node 18+**, **Yarn**, **MongoDB** (local or remote via `MONGO_URL`).

---

## 🛠 Manual setup

### Backend

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env       # then edit .env
uvicorn server:app --host 0.0.0.0 --port 8001 --reload
```

### Frontend

```bash
cd frontend
yarn install
cp .env.example .env       # then edit .env
yarn start
```

### MongoDB

Any reachable MongoDB ≥ 5 works. Easiest options:

```bash
# local dev — Docker
docker run -d --name tamis-mongo -p 27017:27017 mongo:7

# or — MongoDB Atlas free tier (paste the SRV string into MONGO_URL)
```

On the **first** backend startup the seed hooks populate demo data (products, FAQ, partners, cultures, blog posts, reviews, policies, demo upsells).

---

## 🔑 Environment variables

The truth lives in `backend/.env.example` and `frontend/.env.example`. Most-used ones:

| Variable                     | Side     | Required | Description                                                |
| ---------------------------- | -------- | -------- | ---------------------------------------------------------- |
| `MONGO_URL`                  | backend  | ✅        | MongoDB connection string                                  |
| `DB_NAME`                    | backend  | ✅        | Logical DB name                                            |
| `CORS_ORIGINS`               | backend  | ✅        | Comma-separated allow-list (`*` for dev)                    |
| `JWT_SECRET`, `JWT_ALG`      | backend  | ✅        | JWT signing                                                |
| `JWT_EXPIRES_DAYS`           | backend  |          | Default `30`                                               |
| `SITE_BASE_URL`              | backend  |          | Used in absolute URLs                                      |
| `NOVA_POSHTA_API_KEY`        | backend  |          | Enables NP lookups                                         |
| `STRIPE_API_KEY` + webhook   | backend  |          | Enables card payments                                      |
| `GOOGLE_OAUTH_*`             | backend  |          | Enables Google login                                       |
| `EMERGENT_LLM_KEY`           | backend  |          | Enables AI helpers                                         |
| `UPLOAD_DIR` etc.            | backend  |          | Override upload locations                                  |
| `REACT_APP_BACKEND_URL`      | frontend | ✅        | Where the React app calls the API                          |
| `WDS_SOCKET_PORT`            | frontend |          | Webpack DevServer (default `443` for Emergent preview)     |
| `ENABLE_HEALTH_CHECK`        | frontend |          | Toggles dev-only health pings                              |

---

## 👤 Test credentials

After the first seed:

| Role     | Email             | Password    |
| -------- | ----------------- | ----------- |
| Customer | `test@tamis.ua`   | `test1234`  |
| Admin    | `admin@tamis.ua`  | `admin1234` |

The `GET /api/auth/test-credentials` endpoint returns the customer pair (dev-only).

---

## 🧪 Common dev commands

```bash
# Backend hot-reload (already in bootstrap message)
uvicorn server:app --host 0.0.0.0 --port 8001 --reload

# Run Python linter
ruff check backend/

# Frontend dev / build / lint
cd frontend
yarn start
yarn build
yarn lint

# Drop the demo DB and re-seed
mongosh "$MONGO_URL" --eval 'db.getSiblingDB("'"$DB_NAME"'").dropDatabase()'
# …then restart the backend; seed hooks repopulate it.
```

---

## ☁️ Deployment notes

* **Backend** can be run by any ASGI server (Uvicorn, Hypercorn, Gunicorn-Uvicorn-workers). Place a reverse-proxy (Nginx / Caddy / Traefik) in front for TLS + static `uploads/` handling.
* **Frontend** is a static build (`yarn build` → `frontend/build/`). Ship it through any CDN (Vercel, Netlify, Cloudflare Pages, S3 + CloudFront). Just make sure **`REACT_APP_BACKEND_URL`** is set at **build time**.
* **MongoDB**: use a managed service (Atlas) in production. Add an index on every query path you observe (start with `products.slug`, `orders.user_id`, `carts.anonymous_id`, `blog_posts.slug`).
* **Secrets**: never commit `.env`. Use your hosting platform's secret manager. For Emergent: configure via the platform UI; for Docker / k8s: use sealed-secrets or SSM Parameter Store.

---

## 🩺 Troubleshooting

| Symptom                                                          | Likely cause / fix                                                                                 |
| ---------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `ModuleNotFoundError: emergentintegrations`                       | Optional dep — install only if you set `EMERGENT_LLM_KEY` and want AI features.                    |
| Frontend 404 on `/api/...`                                       | `REACT_APP_BACKEND_URL` is wrong or build was made with the old value (CRA inlines envs at build). |
| `pymongo.errors.ServerSelectionTimeoutError`                     | Mongo not reachable — check `MONGO_URL`.                                                           |
| Google login redirect mismatch                                   | `GOOGLE_OAUTH_REDIRECT_URI` must match the URI added in Google Cloud Console **exactly**.          |
| Stripe webhook signature failed                                  | `STRIPE_WEBHOOK_SECRET` mismatch with the endpoint configured in the Stripe dashboard.             |
| Trust-grid "depth" effect missing on mobile                      | Browser cached old SVG — bump the `?v=` suffix on `trust-grid-pattern.svg` in the CSS.             |
| `JWT signature verification failed` right after env change       | Restart the backend so the new `JWT_SECRET` is loaded; existing tokens become invalid by design.   |

---

## 📜 License

Proprietary © TAMIS АГРО. Contact the repository owner for licensing terms.
