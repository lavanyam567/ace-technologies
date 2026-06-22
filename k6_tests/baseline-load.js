'use strict';

import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';

const supabaseUrl = (__ENV.SUPABASE_URL || '').replace(/\/$/, '');
const supabaseAnonKey = __ENV.SUPABASE_ANON_KEY || '';
const restBaseUrl = __ENV.K6_REST_BASE_URL || `${supabaseUrl}/rest/v1`;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('SUPABASE_URL and SUPABASE_ANON_KEY are required for the k6 baseline test.');
}

const commonHeaders = {
  apikey: supabaseAnonKey,
  Authorization: `Bearer ${supabaseAnonKey}`,
  Accept: 'application/json',
};

export const options = {
  scenarios: {
    baseline_load: {
      executor: 'constant-vus',
      vus: Number(__ENV.BASELINE_VUS || '100'),
      duration: __ENV.BASELINE_DURATION || '1m',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.05'],
    checks: ['rate>0.95'],
    http_req_duration: ['p(95)<3000'],
    products_response_time: ['p(95)<3000'],
    services_response_time: ['p(95)<3000'],
    categories_response_time: ['p(95)<3000'],
    reviews_response_time: ['p(95)<3000'],
  },
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)'],
};

const totalApiRequests = new Counter('total_api_requests');
const failedRequests = new Rate('failed_requests');
const productsResponseTime = new Trend('products_response_time');
const servicesResponseTime = new Trend('services_response_time');
const categoriesResponseTime = new Trend('categories_response_time');
const reviewsResponseTime = new Trend('reviews_response_time');

function makeRequest(name, path, trendMetric, predicate, extraChecks = {}) {
  const url = `${restBaseUrl}${path}`;
  const response = http.get(url, { headers: commonHeaders, tags: { endpoint: name, path } });
  const ok = response && response.status === 200;

  totalApiRequests.add(1);
  trendMetric.add(response && response.timings ? response.timings.duration : 0);
  failedRequests.add(!ok);

  const bodyCheckName = `${name} - body looks valid`;
  const responseTimeCheckName = `${name} - response < 3 s`;
  check(response, {
    [`${name} - status 200`]: (res) => !!res && res.status === 200,
    [bodyCheckName]: (res) => !!res && !!res.body && predicate(res),
    [responseTimeCheckName]: (res) => !!res && !!res.timings && res.timings.duration < 3000,
    ...extraChecks,
  });
}

export default function () {
  group('Products API', () => {
    makeRequest(
      'GET /products',
      '/products?select=id,name,price,category,is_active&is_active=eq.true&limit=20',
      productsResponseTime,
      (res) => Array.isArray(res.json())
    );
  });

  group('Services API', () => {
    makeRequest(
      'GET /services',
      '/services?select=id,title,price,is_active&is_active=eq.true&limit=20',
      servicesResponseTime,
      (res) => Array.isArray(res.json())
    );
  });

  group('Categories API', () => {
    makeRequest(
      'GET /categories',
      '/categories?select=name,sort_order&order=sort_order.asc',
      categoriesResponseTime,
      (res) => Array.isArray(res.json())
    );
  });

  group('Reviews API', () => {
    makeRequest(
      'GET /reviews',
      '/reviews?select=id,product_id,rating,comment,created_at&limit=20',
      reviewsResponseTime,
      (res) => Array.isArray(res.json())
    );
  });

  sleep(Number(__ENV.K6_SLEEP_SECONDS || '0.2'));
}
