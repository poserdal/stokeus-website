# Stoke - Marketing Website

Coming soon page for stokeus.com

## Development

```bash
# Install dependencies
npm install

# Start dev server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## Deployment to GitHub Pages

1. Create a new repository on GitHub named `stokeus-website`
2. Initialize and push this code:

```bash
git remote add origin https://github.com/<your-username>/stokeus-website.git
git branch -M main
git add .
git commit -m "Initial commit: Coming soon page"
git push -u origin main
```

3. Enable GitHub Pages:
   - Go to repository Settings → Pages
   - Under "Source", select "GitHub Actions"
   - The site will automatically deploy on every push to main

4. Configure custom domain (optional):
   - In Settings → Pages → Custom domain, enter: `stokeus.com`
   - Configure DNS with your domain registrar:
     - Add A records pointing to GitHub Pages IPs:
       - 185.199.108.153
       - 185.199.109.153
       - 185.199.110.153
       - 185.199.111.153
     - Or add a CNAME record pointing to `<your-username>.github.io`

## Tech Stack

- [Astro](https://astro.build) - Static site generator
- TypeScript - Type safety
- GitHub Pages - Free hosting with automatic deployment

## Project Structure

```
/
├── public/          # Static assets
├── src/
│   └── pages/       # Pages and routes
│       └── index.astro
├── .github/
│   └── workflows/
│       └── deploy.yml  # GitHub Actions deployment
└── package.json
```
