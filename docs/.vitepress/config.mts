import { defineConfig } from 'vitepress'

const SITE_URL = 'https://aim-dart.dev'
const SITE_NAME = 'Aim Framework'
const SITE_DESCRIPTION_EN = 'A lightweight, fast web framework for Dart. Build modern server-side applications with simple API, type safety, and modular design.'

// JSON-LD 構造化データ
const jsonLdSoftware = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "Aim Framework",
  "applicationCategory": "DeveloperApplication",
  "operatingSystem": "Cross-platform",
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "USD"
  },
  "description": SITE_DESCRIPTION_EN,
  "url": SITE_URL,
  "author": {
    "@type": "Organization",
    "name": "Aim Contributors",
    "url": "https://github.com/aim-dart"
  },
  "programmingLanguage": "Dart",
  "softwareVersion": "0.0.6",
  "license": "https://opensource.org/licenses/MIT"
}

const jsonLdWebSite = {
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": SITE_NAME,
  "url": SITE_URL,
  "description": SITE_DESCRIPTION_EN,
  "inLanguage": ["en", "ja"],
  "potentialAction": {
    "@type": "SearchAction",
    "target": `${SITE_URL}/search?q={search_term_string}`,
    "query-input": "required name=search_term_string"
  }
}

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Aim",
  description: SITE_DESCRIPTION_EN,
  cleanUrls: true,
  lang: 'en-US',

  // SEO
  head: [
    // Favicon
    ['link', { rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' }],
    ['link', { rel: 'apple-touch-icon', sizes: '180x180', href: '/apple-touch-icon.png' }],

    // Primary Meta Tags
    ['meta', { name: 'theme-color', content: '#3178c6' }],
    ['meta', { name: 'author', content: 'Aim Contributors' }],
    ['meta', { name: 'keywords', content: 'Dart, web framework, serverside dart, Dart server, Dart backend, Dart HTTP, REST API, middleware, routing, hot reload, Dart フレームワーク, サーバーサイド Dart, ダート, Webフレームワーク, ミドルウェア, ルーティング' }],

    // Open Graph / Facebook
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:site_name', content: SITE_NAME }],
    ['meta', { property: 'og:title', content: 'Aim - Lightweight Web Framework for Dart' }],
    ['meta', { property: 'og:description', content: SITE_DESCRIPTION_EN }],
    ['meta', { property: 'og:image', content: `${SITE_URL}/og-image.png` }],
    ['meta', { property: 'og:image:width', content: '1200' }],
    ['meta', { property: 'og:image:height', content: '630' }],
    ['meta', { property: 'og:image:alt', content: 'Aim Framework - Dart Web Framework' }],
    ['meta', { property: 'og:url', content: SITE_URL }],
    ['meta', { property: 'og:locale', content: 'en_US' }],
    ['meta', { property: 'og:locale:alternate', content: 'ja_JP' }],

    // Twitter
    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
    ['meta', { name: 'twitter:title', content: 'Aim - Lightweight Web Framework for Dart' }],
    ['meta', { name: 'twitter:description', content: SITE_DESCRIPTION_EN }],
    ['meta', { name: 'twitter:image', content: `${SITE_URL}/og-image.png` }],

    // JSON-LD 構造化データ
    ['script', { type: 'application/ld+json' }, JSON.stringify(jsonLdSoftware)],
    ['script', { type: 'application/ld+json' }, JSON.stringify(jsonLdWebSite)],
  ],

  // Sitemap
  sitemap: {
    hostname: SITE_URL,
    lastmodDateOnly: false,
  },

  // ページごとの動的メタタグ設定
  transformPageData(pageData) {
    const canonicalUrl = `${SITE_URL}/${pageData.relativePath}`
      .replace(/index\.md$/, '')
      .replace(/\.md$/, '')

    pageData.frontmatter.head ??= []
    pageData.frontmatter.head.push(
      ['link', { rel: 'canonical', href: canonicalUrl }],
      ['meta', { property: 'og:url', content: canonicalUrl }]
    )
  },

  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    logo: '/logo.png',

    nav: [
      {
        text: 'v0.0.6',
        items: [
          { text: 'Changelog', link: 'https://github.com/aim-dart/aim/releases' },
          { text: 'Contributing', link: 'https://github.com/aim-dart/aim/blob/main/CONTRIBUTING.md' }
        ]
      }
    ],

    sidebar: [
      {
        text: 'Getting Started',
        collapsed: false,
        items: [
          { text: 'Installation', link: '/getting-started/installation' },
          { text: 'Quick Start', link: '/getting-started/quick-start' },
          { text: 'CLI Reference', link: '/getting-started/cli-reference' }
        ]
      },
      {
        text: 'Concepts',
        collapsed: false,
        items: [
          { text: 'Routing', link: '/concepts/routing' },
          { text: 'Middleware', link: '/concepts/middleware' },
          { text: 'Context', link: '/concepts/context' },
          { text: 'Request/Response', link: '/concepts/request-response' }
        ]
      },
      {
        text: 'Guides',
        collapsed: false,
        items: [
          { text: 'Testing', link: '/guides/testing' },
          { text: 'Best Practices', link: '/guides/best-practices' },
          { text: 'FAQ', link: '/guides/faq' }
        ]
      },
      {
        text: 'Middleware',
        collapsed: false,
        items: [
          { text: 'Overview', link: '/middleware/' },
          { text: 'CORS', link: '/middleware/cors' },
          { text: 'Cookie', link: '/middleware/cookie' },
          { text: 'Form', link: '/middleware/form' },
          { text: 'Multipart', link: '/middleware/multipart' },
          { text: 'Static Files', link: '/middleware/static' },
          { text: 'Logger', link: '/middleware/logger' },
          { text: 'SSE', link: '/middleware/sse' },
          { text: 'JWT Auth', link: '/middleware/jwt' },
          { text: 'Basic Auth', link: '/middleware/basic-auth' }
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/aim-dart/aim' }
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2025-present dosukoi-android & Aim Contributors.'
    },

    editLink: {
      pattern: 'https://github.com/aim-dart/aim/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
    },

    search: {
      provider: 'local'
    },
  }
})
