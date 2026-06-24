import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  stages: [
    { duration: "20s", target: 15 },
    { duration: "1m", target: 15 },
    { duration: "20s", target: 0 },
  ],
};

const SUPABASE_URL = "https://bjjvvqlztmfjskxsykmz.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_SnFXOvSnXEqQ_3cLPVX0lw_4zqjwyyf";

export default function () {
  const res = http.get(`${SUPABASE_URL}/rest/v1/products?select=*`, {
    headers: {
      apikey: SUPABASE_ANON_KEY,
      Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
    },
  });

  check(res, {
    "status is 200": (r) => r.status === 200,
    "response time < 1s": (r) => r.timings.duration < 1000,
  });

  sleep(1);
}

export function handleSummary(data) {
  const httpReqs = data.metrics.http_reqs || { values: { count: 0, rate: 0 } };
  const httpReqDuration = data.metrics.http_req_duration || { values: { avg: 0, min: 0, med: 0, max: 0, 'p(90)': 0, 'p(95)': 0 } };
  const httpReqFailed = data.metrics.http_req_failed || { values: { rate: 0, passes: 0, fails: 0 } };
  const checks = data.metrics.checks || { values: { rate: 0, passes: 0, fails: 0 } };

  const durationSec = Math.round((data.state.testRunDurationMs || 0) / 100) / 10;
  const totalReqs = httpReqs.values.count;
  const failedReqs = httpReqFailed.values.passes || 0;
  const successReqs = totalReqs - failedReqs;
  const errorRateStr = (httpReqFailed.values.rate * 100).toFixed(2) + "%";

  const vusMax = data.metrics.vus_max ? (data.metrics.vus_max.values.max || 0) : 0;

  // Print results matching the format in the user's screenshot
  const consoleSummary = `
----------------------------------------------------------------------
                          FINAL RESULTS
----------------------------------------------------------------------
⏱  Test Duration       : ${durationSec}s
👥  Virtual Users       : ${vusMax}
📊  Total Requests      : ${totalReqs}
✅  Successful Requests : ${successReqs}
❌  Failed Requests     : ${failedReqs}
📉  Error Rate          : ${errorRateStr}
⚡  Request Rate        : ${httpReqs.values.rate.toFixed(1)} RPS
⏱  Average Response    : ${httpReqDuration.values.avg.toFixed(1)}ms
⏱  Min Response Time   : ${httpReqDuration.values.min.toFixed(1)}ms
⏱  Median Response Time: ${httpReqDuration.values.med.toFixed(1)}ms
⏱  Max Response Time   : ${httpReqDuration.values.max.toFixed(1)}ms
⏱  p(90) Response Time : ${httpReqDuration.values['p(90)'].toFixed(1)}ms
⏱  p(95) Response Time : ${httpReqDuration.values['p(95)'].toFixed(1)}ms
----------------------------------------------------------------------
`;

  return {
    'stdout': consoleSummary, // Prints to stdout in GitHub Actions console
    'summary.json': JSON.stringify(data), // Saves to summary.json for the XLSX generator
  };
}
