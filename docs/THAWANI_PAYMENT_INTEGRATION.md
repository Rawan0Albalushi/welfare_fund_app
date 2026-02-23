# Thawani Payment Integration Guide (English)

This document describes how the **Student Welfare Fund** app integrates with **Thawani** (ثواني) for payments, and lists all **payment-related APIs** and flows. Use it to implement the same flow in a separate web or mobile app.

---

## 1. Overview

- **Payment gateway:** Thawani Pay (Oman).
- **Backend role:** The Laravel backend creates Thawani checkout sessions and stores donations. The frontend never talks to Thawani directly; it only calls the backend APIs and redirects the user to the checkout URL returned by the backend.
- **Currency:** OMR (Omani Rial). Thawani uses **baisa** (1 OMR = 1000 baisa) in product amounts; the backend or your payload may convert OMR → baisa.
- **Flow:** Create donation/session → get checkout URL → redirect user → user pays on Thawani → user returns to success/cancel URL → frontend calls confirm API.

---

## 2. Base URLs (payment-related)

| Purpose | URL |
|--------|-----|
| API v1 base | `{APP_URL}/api/v1` |
| Create donation with payment | `{APP_URL}/api/v1/donations/with-payment` |
| Anonymous donation with payment | `{APP_URL}/api/v1/donations/anonymous-with-payment` |
| Create payment session (standalone) | `{APP_URL}/api/v1/payments/create` |
| Create payment for existing donation | `{APP_URL}/api/v1/payments/create-with-donation` |
| Check payment status | `{APP_URL}/api/v1/payments/status/{sessionId}` |
| Confirm payment (after success) | `{APP_URL}/api/v1/payments/confirm` |
| Success redirect (backend page) | `{APP_URL}/api/v1/payments/success` |
| Cancel redirect (backend page) | `{APP_URL}/api/v1/payments/cancel` |

`{APP_URL}` is your backend base (e.g. `https://welfare-student.maksab.om`). Success/cancel URLs are typically configured on the **backend** for Thawani; the backend may redirect the user to your web app using `return_origin`.

---

## 3. End-to-end payment flow

### 3.1 Donation with payment (campaign/program)

1. **Frontend** calls **POST** `/api/v1/donations/with-payment` with:
   - `program_id` **or** `campaign_id` (integer)
   - `amount` (OMR, number)
   - Optional: `donor_name`, `donor_email`, `donor_phone`, `note`, `message`, `is_anonymous`
   - Optional: `return_origin` (your web app origin, e.g. `https://your-site.com`) so the backend can redirect the user back after payment

2. **Backend** creates the donation and a Thawani checkout session, then returns:
   - `payment_url` / `checkout_url` / `redirect_url` (Thawani checkout URL)
   - `session_id` (Thawani session id)
   - `donation_id` (your donation id)

3. **Frontend** redirects the user to the checkout URL (same tab, new tab, or in-app WebView).

4. User completes or cancels payment on Thawani. Thawani redirects the user to the backend’s **success** or **cancel** URL (e.g. `.../payments/success` or `.../payments/cancel`). The backend may then redirect to `return_origin` with query params (e.g. `?session_id=...&status=success`).

5. **Frontend** (when it detects success, e.g. on success page or via `status=success`):
   - Calls **POST** `/api/v1/payments/confirm` with body `{ "session_id": "<session_id>" }` (and optionally `donation_id` if your backend expects it).
   - Backend verifies the session with Thawani and marks the donation as paid.

6. Show a “Thank you” or success screen.

### 3.2 Anonymous donation with payment

Same as above, but use **POST** `/api/v1/donations/anonymous-with-payment`. No auth header. Backend may require at least `donor_name` or `donor_phone`; the app sends `donor_name: "متبرع"` if not provided. Include `return_origin` for web so the user can be sent back to your site.

### 3.3 Standalone payment session (no donation created first)

1. **POST** `/api/v1/payments/create` with body (see section 5). Backend creates a Thawani session (and may create a donation internally).
2. Use returned `payment_url` and `session_id` as in steps 3–6 above.

### 3.4 Payment for an existing donation

1. **POST** `/api/v1/payments/create-with-donation` with `donation_id` and `amount_omr`, optional `return_origin`.
2. Backend returns checkout URL and session id; then same redirect → confirm flow as above.

---

## 4. Payment-related APIs (reference)

### 4.1 Create donation with payment

**POST** `{APP_URL}/api/v1/donations/with-payment`

**Headers:**  
`Content-Type: application/json`  
`Accept: application/json`  
`Authorization: Bearer <token>` (optional; if user is logged in)

**Request body (JSON):**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| program_id | int | One of program_id or campaign_id | Program id |
| campaign_id | int | One of program_id or campaign_id | Campaign id |
| amount | number | Yes | Amount in OMR |
| is_anonymous | boolean | No | Default false |
| donor_name | string | No | |
| donor_email | string | No | |
| donor_phone | string | No | |
| note | string | No | |
| message | string | No | (same as note in some backends) |
| return_origin | string | No | Web app origin for redirect after payment (e.g. `https://your-site.com`) |

**Success response (200/201):**

- `data.payment_session.payment_url` or `data.payment_session.redirect_url` or top-level `payment_url` / `checkout_url`
- `data.payment_session.session_id` or top-level `session_id`
- `data.donation.donation_id` or `data.donation.id` or top-level `donation_id`

If the donation was created but the Thawani session failed, the response may still be 200 with `ok: false` or a `payment_error` field and `donation_id`; show an error and optionally let the user retry payment.

---

### 4.2 Anonymous donation with payment

**POST** `{APP_URL}/api/v1/donations/anonymous-with-payment`

**Headers:**  
`Content-Type: application/json`  
`Accept: application/json`  
(No auth.)

**Request body (JSON):** Same as 4.1 (program_id or campaign_id, amount, donor_name, donor_phone, note, message, return_origin). `is_anonymous` is implicitly true.

**Response:** Same shape as 4.1 (payment_url, session_id, donation_id when successful).

---

### 4.3 Create payment session (standalone)

**POST** `{APP_URL}/api/v1/payments/create`

**Headers:**  
`Content-Type: application/json`  
`Accept: application/json`  
`Authorization: Bearer <token>` (optional)

**Request body (JSON):**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| products | array | Yes | e.g. `[{ "name": "Donation", "quantity": 1, "unit_amount": 1000 }]` — `unit_amount` in **baisa** |
| client_reference_id | string | No | See “client_reference_id rules” below |
| program_id | int | No | |
| campaign_id | int | No | |
| donor_name | string | No | |
| note | string | No | |
| return_origin | string | No | Web app origin |
| type | string | No | e.g. `quick` or `gift` |

**Response:** Contains `session_id` and `payment_url` (or `redirect_url`). The app infers success when both are present.

---

### 4.4 Create payment for existing donation

**POST** `{APP_URL}/api/v1/payments/create-with-donation`

**Request body (JSON):**

- `donation_id` (string/number)
- `amount_omr` (number)
- `return_origin` (string, optional)

**Response:** Same as 4.3 (checkout URL and session_id).

---

### 4.5 Check payment status

**GET** `{APP_URL}/api/v1/payments/status/{sessionId}`

**Headers:**  
`Accept: application/json`  
`Authorization: Bearer <token>` (optional)

**Response (200):** Backend may return:

- `success` (boolean)
- `status` or `payment_status` or `donation_status` or `payment_status_fromThawani`: e.g. `paid`, `unpaid`, `pending`, `completed`, `cancelled`, `failed`, `expired`
- `session_id`, `amount`, `currency`, `transaction_id`, `completed_at`, `message`, `error`

The app maps statuses to: **completed** (paid/success/completed), **pending** (unpaid/pending/awaiting_payment), **cancelled**, **failed**, **expired**, **unknown**.

---

### 4.6 Confirm payment (after user returns from Thawani)

**POST** `{APP_URL}/api/v1/payments/confirm`

**Headers:**  
`Content-Type: application/json`  
`Accept: application/json`  
`Authorization: Bearer <token>` (optional but recommended if user is logged in)

**Request body (JSON):**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| session_id | string | Yes* | Thawani session id (*or donation_id if backend supports it) |
| donation_id | string | No | Some backends use this instead of or with session_id |

**Response (200):** Backend confirms with Thawani and updates the donation; response body is backend-specific (e.g. `success`, `message`).

**Usage:** Call this when the user lands on your success page or when you detect success (e.g. from `return_origin` redirect with `status=success`). Do not rely only on the redirect; the confirm step ensures the backend marks the donation as paid.

---

## 5. client_reference_id (Thawani requirement)

Thawani accepts **only** the following characters in `client_reference_id`:

- English letters  
- Digits  
- Spaces  
- Arabic characters  

**Not allowed:** hyphens (`-`), underscores (`_`), and any other special characters.

If your backend sends a donation id like `DN_ec9458ae-7849-49e8-bdc3-d0803e411bd3` to Thawani, Thawani will reject it. Options:

- **Backend:** Sanitize before calling Thawani, e.g. remove `-` and `_`, or use a simple id like `donation123`.
- **Frontend:** If you ever generate the reference yourself, use only allowed characters (e.g. `donation` + timestamp + digits, no `-` or `_`).

Example (backend-style):  
`DN_ec9458ae-7849-49e8-bdc3-d0803e411bd3` → `DNec9458ae784949e8bdc3d0803e411bd3`  
or use `donation` + numeric id: `donation10`.

---

## 6. Success and cancel URLs

- **Success URL:** Backend exposes e.g. `{APP_URL}/api/v1/payments/success`. Thawani redirects the user here after successful payment. The backend can then redirect to your web app (e.g. using `return_origin` + query params like `?session_id=...&status=success`).
- **Cancel URL:** Backend exposes e.g. `{APP_URL}/api/v1/payments/cancel`. Thawani redirects here when the user cancels. Again, the backend may redirect to your app with something like `status=cancel`.

These URLs are usually configured in the backend (and in Thawani dashboard), not sent from the frontend on each request. The frontend only needs to:

1. Redirect the user to the **checkout URL** returned by the backend.
2. On the success path (your success page or when you get `status=success`), call **POST** `/api/v1/payments/confirm` with `session_id`.

---

## 7. Web-specific behaviour (from the app)

- **return_origin:** For web, the app sends `return_origin` = current site origin (e.g. `window.location.origin`) so the backend can redirect the user back after payment.
- **Redirect:** On web, the app opens the Thawani checkout URL in the **same tab** (`_self`). After payment, the user is on the backend success/cancel URL (then possibly redirected to your site).
- **Confirm:** After redirect (or after a short delay if the app stays on the same page), the app calls **POST** `/payments/confirm` with the stored `session_id`.

For your own web app:

1. Store `session_id` (and optionally `donation_id`) before redirecting to checkout.
2. On the page the user lands on after payment (e.g. `/donation/success?session_id=...`), call **POST** `/api/v1/payments/confirm` with that `session_id`.
3. Then show the thank-you message.

---

## 8. Mobile (in-app) flow (from the app)

- The app opens the checkout URL in an **in-app WebView**.
- Success URL: `{APP_URL}/api/v1/payments/success`  
  Cancel URL: `{APP_URL}/api/v1/payments/cancel`
- When the WebView loads the success URL, the app detects success and calls **POST** `/payments/confirm` with the stored `session_id`, then shows the success screen.
- When the user cancels (cancel URL), the app shows a “Payment cancelled” message.

---

## 9. Error handling

- **422:** Validation error; show `message` or `errors` from the response body.
- **401:** Unauthorized; for “with-payment” you can still support anonymous donations; for confirm, prompt login if needed.
- **404 on status/confirm:** Session or donation not found; show a friendly message and optionally offer to retry or contact support.
- **Donation created but payment session failed:** Backend may return 200 with `payment_error` and `donation_id`; show the error and optionally a “Retry payment” using create-with-donation for that `donation_id`.

---

## 10. Quick reference: which API to use

| Scenario | API |
|---------|-----|
| Donate to campaign/program (logged in or not) | POST `/donations/with-payment` |
| Anonymous donate to campaign/program | POST `/donations/anonymous-with-payment` |
| Quick donate (no specific campaign; backend may use default campaign) | POST `/donations/with-payment` with campaign_id (e.g. 1) or POST `/payments/create` |
| Create Thawani session only (backend creates donation) | POST `/payments/create` |
| Pay for an existing donation | POST `/payments/create-with-donation` |
| After user returns from Thawani success | POST `/payments/confirm` with `session_id` |
| Check if payment is paid | GET `/payments/status/{sessionId}` |

All endpoints are under **`{APP_URL}/api/v1`** and use **JSON**; send **Bearer token** when the user is logged in and the endpoint supports it.
