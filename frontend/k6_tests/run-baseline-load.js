import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
    vus: 100,
    duration: '1m',
    thresholds: {
        'http_req_failed': ['rate<0.05'], // Request failures under 5%
        'http_req_duration': ['p(95)<1500'] // 95% of requests must complete below 1.5s
    },
};

export default function () {
    // Target the backend API URL (via environment variables or fallback)
    const url = __ENV.API_BASE_URL || 'http://127.0.0.1:3000/api/status';

    const res = http.get(url);
    
    check(res, {
        'status is 200': (r) => r.status === 200,
    });
    
    // Slight sleep to simulate real user wait time between requests
    sleep(1);
}
