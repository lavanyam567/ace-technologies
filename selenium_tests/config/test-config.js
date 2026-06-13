'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  Ace Technologies – Selenium Test Suite  ·  Central Configuration
// ─────────────────────────────────────────────────────────────────────────────

const path = require('path');

const BASE_URL   = process.env.E2E_BASE_URL   || 'http://127.0.0.1:4173/';
const HEADLESS   = process.env.HEADLESS !== 'false';
const TIMEOUT_MS = Number(process.env.E2E_TIMEOUT_MS || 15000);
const SLOW_MS    = Number(process.env.E2E_SLOW_MS    || 500);

const CONFIG = {
  // ── Application ──────────────────────────────────────────────────────────
  app: {
    name:    'Ace Technologies',
    baseUrl: BASE_URL,
    title:   'Ace Technologies - IT & Security Solutions',
  },

  // ── Browser ───────────────────────────────────────────────────────────────
  browser: {
    headless: HEADLESS,
    windowSize: { width: 1366, height: 768 },
    pageLoadTimeout:   12000,
    scriptTimeout:     15000,
    implicitTimeout:   1000,
    chromeArgs: [
      '--disable-gpu',
      '--disable-dev-shm-usage',
      '--no-sandbox',
      '--disable-extensions',
      '--disable-infobars',
      '--disable-notifications',
      '--allow-running-insecure-content',
      '--disable-software-rasterizer',
      '--disable-background-timer-throttling',
      '--disable-backgrounding-occluded-windows',
      '--disable-renderer-backgrounding',
      '--memory-pressure-off',
    ],
  },

  // ── Timeouts ──────────────────────────────────────────────────────────────
  timeouts: {
    assertion:  TIMEOUT_MS,
    navigation: 12000,
    animation:  800,
    slow:       SLOW_MS,
    flutterBoot: 4000,
  },

  // ── Paths ─────────────────────────────────────────────────────────────────
  paths: {
    root:      path.resolve(__dirname, '..'),
    reports:   path.resolve(__dirname, '../reports'),
    evidence:  path.resolve(__dirname, '../reports/evidence'),
    buildWeb:  path.resolve(__dirname, '../../build/web'),
  },

  // ── Test Credentials (non-production) ────────────────────────────────────
  credentials: {
    validEmail:    process.env.TEST_EMAIL    || 'test@acetechnologies.com',
    validPassword: process.env.TEST_PASSWORD || 'Test@123456',
    invalidEmail:  'notanemail',
    invalidPassword: 'wrong',
    adminEmail:    process.env.ADMIN_EMAIL   || 'admin@acetechnologies.com',
  },

  // ── Viewport presets ─────────────────────────────────────────────────────
  viewports: {
    mobile:  { width: 390,  height: 844,  label: 'Mobile (390×844)'  },
    tablet:  { width: 768,  height: 1024, label: 'Tablet (768×1024)' },
    laptop:  { width: 1366, height: 768,  label: 'Laptop (1366×768)' },
    desktop: { width: 1920, height: 1080, label: 'Desktop (1920×1080)'},
  },

  // ── Core app routes ───────────────────────────────────────────────────────
  routes: {
    home:            '/',
    products:        '/products',
    services:        '/services',
    about:           '/about',
    cart:            '/cart',
    account:         '/account',
    login:           '/login',
    signup:          '/signup',
    profile:         '/profile',
    settings:        '/settings',
    orders:          '/orders',
    checkout:        '/checkout',
    checkoutAddress: '/checkout/address',
    checkoutPayment: '/checkout/payment',
    wishlist:        '/wishlist',
    compare:         '/compare',
    recent:          '/recent',
    deals:           '/deals',
    notifications:   '/notifications',
    serviceHistory:  '/service-history',
    adminOrders:     '/admin/orders',
    search:          '/search',
    productFilter:   '/products/filter',
    productSample:   '/product/sample-product',
    serviceSample:   '/service/sample-service',
  },

  // ── API endpoints (Supabase REST) ─────────────────────────────────────────
  api: {
    supabaseUrl:     process.env.SUPABASE_URL  || '',
    supabaseAnonKey: process.env.SUPABASE_ANON_KEY || '',
    endpoints: {
      products: '/rest/v1/products',
      services: '/rest/v1/services',
      orders:   '/rest/v1/orders',
      profiles: '/rest/v1/profiles',
    },
  },

  // ── Performance thresholds ────────────────────────────────────────────────
  performance: {
    maxPageLoadMs:      8000,
    maxFCPMs:           5000,
    maxTTIMs:           10000,
    maxLCPMs:           6000,
    minLighthouseScore:  50,
  },

  // ── Accessibility ─────────────────────────────────────────────────────────
  accessibility: {
    minContrastRatio: 4.5,
  },
};

module.exports = CONFIG;
