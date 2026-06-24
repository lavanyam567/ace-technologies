'use strict';

const screenCatalog = [
  {
    route: '/',
    area: 'Home',
    navLabel: 'Home',
    anchors: ['Ace Technologies', 'Home Screen', 'One-Stop Solution', 'Products', 'Services', 'About Us'],
    ctas: ['Products', 'Services', 'About Us', 'Cart', 'Account'],
  },
  {
    route: '/products',
    area: 'Products',
    navLabel: 'Products',
    anchors: ['Products', 'Products Screen', 'HP Compaq', 'Samsung', 'Dahua', 'Hikvision', 'Laptops', 'Networking', 'Printers', 'Camera'],
    ctas: ['Filter', 'HP Compaq', 'Samsung'],
  },
  {
    route: '/services',
    area: 'Services',
    navLabel: 'Services',
    anchors: ['Services', 'Services Screen', 'Server installation', 'laptop installation', 'Firewall and security solutions', 'Door access configuration'],
    ctas: ['Server installation', 'Firewall and security solutions'],
  },
  {
    route: '/about',
    area: 'About',
    navLabel: 'About Us',
    anchors: ['About Us', 'Our Objective', 'Our Philosophy', 'Capabilities', 'Muralidharan P', 'Chennai', 'HP Compaq', 'Samsung', 'Dahua', 'Hikvision'],
    ctas: ['About Us'],
  },
  {
    route: '/cart',
    area: 'Cart',
    navLabel: 'Cart',
    anchors: ['Shopping Cart', 'Your cart is empty', 'cart is empty'],
    ctas: ['Checkout'],
  },
  {
    route: '/account',
    area: 'Account',
    navLabel: 'Account',
    anchors: ['Account Screen', 'Login to your account', 'Email', 'Password', 'Login', 'Create account'],
    ctas: ['Login', 'Create account'],
  },
  {
    route: '/signup',
    area: 'Authentication',
    anchors: ['Sign Up', 'Create Account', 'Email', 'Password', 'Confirm Password', 'Signup'],
    ctas: ['Signup'],
  },
  {
    route: '/search?q=laptop',
    area: 'Search',
    anchors: ['Search', 'laptop', 'Products'],
    ctas: ['Search'],
  },
  {
    route: '/products/filter',
    area: 'Catalog Tools',
    anchors: ['Filter', 'Sort'],
    ctas: ['Filter', 'Sort'],
  },
  {
    route: '/checkout',
    area: 'Checkout',
    anchors: ['Checkout', 'Select Address', 'Payment Method'],
    ctas: ['Select Address', 'Payment Method'],
  },
  {
    route: '/checkout/address',
    area: 'Checkout',
    anchors: ['Address Selection', 'Select Address', 'Add Address'],
    ctas: ['Add Address'],
  },
  {
    route: '/checkout/payment',
    area: 'Checkout',
    anchors: ['Payment Method', 'Payment', 'Pay Now'],
    ctas: ['Pay Now'],
  },
  {
    route: '/wishlist',
    area: 'Account Features',
    loginRequired: true,
    anchors: ['Wishlist Screen', 'Wishlist'],
    ctas: ['Wishlist'],
  },
  {
    route: '/compare',
    area: 'Account Features',
    loginRequired: true,
    anchors: ['Compare Products', 'Compare'],
    ctas: ['Compare'],
  },
  {
    route: '/recent',
    area: 'Account Features',
    loginRequired: true,
    anchors: ['Recently Viewed', 'Recent'],
    ctas: ['Recent'],
  },
  {
    route: '/deals',
    area: 'Home Extras',
    anchors: ['Featured Deals', 'Deals'],
    ctas: ['Deals'],
  },
  {
    route: '/notifications',
    area: 'Home Extras',
    anchors: ['Notifications'],
    ctas: ['Notifications'],
  },
  {
    route: '/service-history',
    area: 'Account Features',
    loginRequired: true,
    anchors: ['Bookings', 'Service History'],
    ctas: ['Service History'],
  },
  {
    route: '/settings',
    area: 'Account Features',
    loginRequired: true,
    anchors: ['Settings'],
    ctas: ['Settings'],
  },
  {
    route: '/profile',
    area: 'Account Features',
    loginRequired: true,
    anchors: ['Profile', 'Account Details'],
    ctas: ['Profile'],
  },
  {
    route: '/orders',
    area: 'Orders',
    loginRequired: true,
    anchors: ['My Orders', 'Orders', 'No orders found'],
    ctas: ['Orders'],
  },
  {
    route: '/admin/orders',
    area: 'Admin',
    anchors: ['Admin', 'Orders'],
    ctas: ['Orders'],
  },
];

const coreNavPairs = [
  ['/', 'Products', '/products'],
  ['/', 'Services', '/services'],
  ['/', 'About Us', '/about'],
  ['/', 'Cart', '/cart'],
  ['/', 'Account', '/account'],
  ['/products', 'Services', '/services'],
  ['/services', 'About Us', '/about'],
  ['/about', 'Cart', '/cart'],
  ['/cart', 'Account', '/account'],
  ['/account', 'Home', '/'],
];

const orientationRoutes = [
  '/',
  '/products',
  '/services',
  '/about',
  '/cart',
  '/account',
  '/search?q=laptop',
  '/products/filter',
  '/checkout',
  '/orders',
];

const journeyDefinitions = [
  { key: 'browse-main-tabs', title: 'Guest browse across all primary tabs', steps: ['/', '/products', '/services', '/about', '/cart', '/account'], loginRequired: false },
  { key: 'home-to-products-to-cart', title: 'Guest explores products and returns to cart', steps: ['/', '/products', '/cart'], loginRequired: false },
  { key: 'home-to-services-to-about', title: 'Guest explores services and company information', steps: ['/', '/services', '/about'], loginRequired: false },
  { key: 'account-validation-path', title: 'Guest opens account and validation surfaces correctly', steps: ['/account', '/signup', '/account'], loginRequired: false },
  { key: 'search-and-filter-path', title: 'Guest uses search then filter tools', steps: ['/products', '/search?q=laptop', '/products/filter'], loginRequired: false },
  { key: 'checkout-shell-path', title: 'Guest opens checkout shell pages', steps: ['/cart', '/checkout', '/checkout/address', '/checkout/payment'], loginRequired: false },
  { key: 'account-feature-tour', title: 'Signed-in user navigates account feature screens', steps: ['/profile', '/wishlist', '/compare', '/recent', '/settings', '/orders'], loginRequired: true },
  { key: 'service-history-tour', title: 'Signed-in user opens service history after account areas', steps: ['/profile', '/service-history', '/orders'], loginRequired: true },
  { key: 'deals-and-notifications', title: 'Guest explores home extras', steps: ['/', '/deals', '/notifications', '/'], loginRequired: false },
  { key: 'admin-smoke-path', title: 'Admin order screen remains readable', steps: ['/admin/orders', '/account'], loginRequired: false },
];

const authInputCases = [
  { label: 'empty-login', email: '', password: '', expected: 'Enter email and password' },
  { label: 'invalid-email-format', email: 'notanemail', password: 'wrong', expected: 'Account Screen' },
  { label: 'wrong-password', email: 'test@acetechnologies.com', password: 'wrong', expected: 'Account Screen' },
];

module.exports = {
  screenCatalog,
  coreNavPairs,
  orientationRoutes,
  journeyDefinitions,
  authInputCases,
};
