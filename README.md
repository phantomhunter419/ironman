# Press Line — Complete Setup Guide

> **One-time read.** Follow every step in order and you'll never need to ask about setup again.

---

## What you're building

A mobile-first ironing-service app hosted **free on GitHub Pages** with:
- **Supabase** as the database (Postgres + storage for screenshots)
- **Google & GitHub OAuth** for admin login (no passwords)
- **No build step** — just one `index.html` file

---

## Step 1 — Create a Supabase project

1. Go to **https://supabase.com** → sign up / log in
2. Click **New project**
3. Fill in:
   - **Name:** `press-line` (or anything you like)
   - **Database password:** generate a strong one, save it somewhere
   - **Region:** pick the one closest to you
4. Click **Create new project** — wait ~2 minutes for it to boot

---

## Step 2 — Run the database schema

1. In your Supabase project, go to **SQL Editor** (left sidebar)
2. Click **New query**
3. Open the file `supabase/schema.sql` from this repo
4. Copy **all** of its contents and paste into the editor
5. Click **Run** (or press `Cmd+Enter`)

You should see `Success. No rows returned`.

This creates:
- `areas` table (your service zones and per-garment rates)
- `orders` table (all bookings)
- All RLS (Row Level Security) policies

> [!IMPORTANT]
> If you see an error about `storage.objects`, that's fine — just continue. The storage policies will be set up in Step 4.

---

## Step 3 — Create the screenshots storage bucket

1. In Supabase, go to **Storage** (left sidebar)
2. Click **New bucket**
3. Set:
   - **Name:** `screenshots`  ← must be exactly this
   - **Public bucket:** ✅ toggle ON
4. Click **Save**

Now add the upload policy so customers can upload payment screenshots:

1. Still in Storage, click **Policies** tab (top right of the bucket list)
2. Click **New policy** under `storage.objects`
3. Choose **For full customization**
4. Fill in:
   - **Policy name:** `anyone can upload screenshots`
   - **Allowed operation:** INSERT
   - **Target roles:** `anon`, `authenticated`
   - **USING expression:** `bucket_id = 'screenshots'`
5. Click **Review** → **Save policy**

---

## Step 4 — Enable Google OAuth

### A. Create a Google OAuth app

1. Go to **https://console.cloud.google.com**
2. Create a new project (or use an existing one)
3. Go to **APIs & Services → OAuth consent screen**
   - User type: **External**
   - Fill in App name (e.g. "Press Line"), your email
   - Click **Save and Continue** through all steps (no scopes needed)
4. Go to **APIs & Services → Credentials**
5. Click **Create Credentials → OAuth client ID**
   - Application type: **Web application**
   - Name: `Press Line`
   - **Authorized redirect URIs** — add this (you'll get it from Supabase in the next sub-step):
     ```
     https://<your-project-ref>.supabase.co/auth/v1/callback
     ```
   - Find your project ref: in Supabase → **Settings → General → Reference ID**
   - So the full URI is: `https://abcdefghijkl.supabase.co/auth/v1/callback`
6. Click **Create**
7. Copy the **Client ID** and **Client secret**

### B. Add Google to Supabase

1. In Supabase → **Authentication → Providers**
2. Find **Google**, click to expand
3. Toggle **Enable** ON
4. Paste your **Client ID** and **Client secret**
5. Click **Save**

---

## Step 5 — Enable GitHub OAuth

### A. Create a GitHub OAuth app

1. Go to **https://github.com/settings/developers**
2. Click **OAuth Apps → New OAuth App**
3. Fill in:
   - **Application name:** `Press Line`
   - **Homepage URL:** `https://yourusername.github.io/press-line` (use your actual GitHub username)
   - **Authorization callback URL:**
     ```
     https://<your-project-ref>.supabase.co/auth/v1/callback
     ```
     (Same Supabase callback URL as Google above)
4. Click **Register application**
5. Copy the **Client ID**
6. Click **Generate a new client secret**, copy it immediately (you only see it once)

### B. Add GitHub to Supabase

1. In Supabase → **Authentication → Providers**
2. Find **GitHub**, click to expand
3. Toggle **Enable** ON
4. Paste your **Client ID** and **Client secret**
5. Click **Save**

---

## Step 6 — Get your Supabase keys

1. In Supabase → **Settings → API**
2. Copy these two values:
   - **Project URL** — looks like `https://abcdefghijkl.supabase.co`
   - **anon public key** — a long JWT string starting with `eyJ...`

---

## Step 7 — Create the GitHub repository

1. Go to **https://github.com/new**
2. Set:
   - **Repository name:** `press-line`
   - **Visibility:** Public ← required for free GitHub Pages
3. Click **Create repository**
4. Don't initialize with any files

---

## Step 8 — Fill in `index.html` and push

Open `index.html` in any text editor. Near the top of the `<script>` tag, find:

```javascript
const SUPABASE_URL      = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

Replace the placeholder strings with your real values from Step 6:

```javascript
const SUPABASE_URL      = 'https://abcdefghijkl.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

Save the file.

Now push everything to GitHub:

```bash
cd /Users/jaimane/press-line

git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/press-line.git
git push -u origin main
```

Replace `YOUR_GITHUB_USERNAME` with your actual GitHub username.

---

## Step 9 — Enable GitHub Pages

1. Go to your repo on GitHub → **Settings** tab
2. Scroll to **Pages** in the left sidebar
3. Under **Source**, select:
   - **Deploy from a branch**
   - Branch: **main**
   - Folder: **/ (root)**
4. Click **Save**

After 1–2 minutes, GitHub Pages will be live at:
```
https://YOUR_GITHUB_USERNAME.github.io/press-line/
```

You'll see the URL confirmed in the Pages settings screen.

---

## Step 10 — Add the GitHub Pages URL to Supabase and OAuth apps

This is the most commonly missed step. OAuth redirects only work for URLs you've pre-approved.

### In Supabase:

1. Go to **Authentication → URL Configuration**
2. Add to **Redirect URLs**:
   ```
   https://YOUR_GITHUB_USERNAME.github.io/press-line/
   ```
   Include the trailing slash.
3. Click **Save**

### In Google Cloud Console:

1. Go to **APIs & Services → Credentials → your OAuth client**
2. Under **Authorized JavaScript origins**, add:
   ```
   https://YOUR_GITHUB_USERNAME.github.io
   ```
3. Under **Authorized redirect URIs**, confirm this is there (from earlier):
   ```
   https://your-project-ref.supabase.co/auth/v1/callback
   ```
4. Click **Save**

### In GitHub OAuth App:

1. Go to **https://github.com/settings/developers → your app**
2. The Authorization callback URL should already be the Supabase one — no change needed.

---

## Step 11 — Test the app

1. Open `https://YOUR_GITHUB_USERNAME.github.io/press-line/` in your phone's browser
2. Tap **I'm a customer** → try booking a pickup
3. Go back → tap **I'm the admin** → tap **Continue with Google**
4. After signing in, you should be in the admin panel
5. Check **Dashboard** — you should see the order just placed
6. Tap the order in **Orders** tab → tap **Mark ironing done**

> [!TIP]
> If the Google login redirects back to the app but immediately shows the auth screen again, double-check that the GitHub Pages URL (with trailing slash) is in Supabase's Redirect URLs list.

---

## Step 12 — Add to phone home screen

To make it feel like a native app:

**iPhone (Safari):**
1. Open the GitHub Pages URL in Safari
2. Tap the Share icon at the bottom
3. Tap **Add to Home Screen**
4. Give it a name (e.g. "Press Line") and tap **Add**

**Android (Chrome):**
1. Open the URL in Chrome
2. Tap the three-dot menu
3. Tap **Add to Home screen** or **Install app**

The app will launch full-screen with no browser chrome.

---

## Updating the app later

Whenever you change `index.html`, just commit and push:

```bash
git add index.html
git commit -m "Update: describe what changed"
git push
```

GitHub Pages redeploys automatically (usually within 60 seconds).

---

## Troubleshooting

| Problem | Fix |
|--------|-----|
| "Setup required" screen | You haven't replaced the placeholder constants in `index.html` |
| OAuth redirects to blank page | GitHub Pages URL not added to Supabase → Authentication → URL Configuration |
| "Invalid login" on Google | Supabase Google provider not enabled, or client ID/secret wrong |
| Orders don't appear for admin | Check browser console for Supabase errors; likely an RLS policy issue |
| Screenshot upload fails | Check that the `screenshots` bucket exists and is public |
| Page shows old version | Hard-refresh with `Cmd+Shift+R` (iPhone: close tab, reopen) |

---

## Security notes

- The **Supabase anon key** is safe to expose in client-side code — it's designed to be public. Supabase RLS policies control what it can access.
- **Any Google/GitHub account** that signs in through the OAuth flow becomes an "admin". For a single-person business this is fine. If you want to restrict to specific emails, add a check in the Supabase Auth dashboard under **Users** and manually block unwanted accounts.
- Customer phone numbers are stored in plaintext. This is standard for a service business but keep it in mind.
