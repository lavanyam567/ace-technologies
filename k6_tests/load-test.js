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
