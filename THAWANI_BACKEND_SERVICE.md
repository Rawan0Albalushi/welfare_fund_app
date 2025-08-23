# Thawani Backend Service - Laravel

## Current Implementation
```php
class ThawaniService
{
    private string $apiKey;
    private string $baseUrl;

    public function __construct()
    {
        $this->apiKey = config('services.thawani.secret_key');
        $this->baseUrl = config('services.thawani.base_url');
    }

    public function createSession(array $data)
    {
        $client = new \GuzzleHttp\Client();

        $response = $client->post($this->baseUrl . '/checkout/session', [
            'headers' => [
                'Authorization' => 'Bearer ' . $this->apiKey,
                'Content-Type'  => 'application/json',
            ],
            'json' => $data,
        ]);

        return json_decode($response->getBody(), true);
    }
}
```

## Required Improvements

### 1. Error Handling
```php
public function createSession(array $data)
{
    try {
        $client = new \GuzzleHttp\Client();

        $response = $client->post($this->baseUrl . '/checkout/session', [
            'headers' => [
                'Authorization' => 'Bearer ' . $this->apiKey,
                'Content-Type'  => 'application/json',
            ],
            'json' => $data,
        ]);

        $result = json_decode($response->getBody(), true);
        
        // Log successful response
        \Log::info('Thawani session created successfully', [
            'session_id' => $result['session_id'] ?? null,
            'amount' => $data['amount'] ?? null
        ]);

        return $result;
        
    } catch (\GuzzleHttp\Exception\ClientException $e) {
        $errorResponse = json_decode($e->getResponse()->getBody(), true);
        \Log::error('Thawani API error', [
            'status' => $e->getResponse()->getStatusCode(),
            'error' => $errorResponse,
            'data' => $data
        ]);
        
        throw new \Exception('Failed to create Thawani session: ' . ($errorResponse['message'] ?? 'Unknown error'));
        
    } catch (\Exception $e) {
        \Log::error('Thawani service error', [
            'error' => $e->getMessage(),
            'data' => $data
        ]);
        
        throw new \Exception('Failed to create checkout session');
    }
}
```

### 2. Data Validation
```php
public function createSession(array $data)
{
    // Validate required fields
    $requiredFields = ['amount', 'client_reference_id', 'return_url', 'currency'];
    foreach ($requiredFields as $field) {
        if (!isset($data[$field])) {
            throw new \Exception("Missing required field: {$field}");
        }
    }

    // Validate amount (must be positive integer in baisa)
    if (!is_numeric($data['amount']) || $data['amount'] <= 0) {
        throw new \Exception('Amount must be a positive number in baisa');
    }

    // Validate currency
    if ($data['currency'] !== 'OMR') {
        throw new \Exception('Currency must be OMR');
    }

    // Validate return URL
    if (!filter_var($data['return_url'], FILTER_VALIDATE_URL)) {
        throw new \Exception('Invalid return URL');
    }

    // Continue with API call...
}
```

### 3. Complete Implementation
```php
class ThawaniService
{
    private string $apiKey;
    private string $baseUrl;

    public function __construct()
    {
        $this->apiKey = config('services.thawani.secret_key');
        $this->baseUrl = config('services.thawani.base_url');
    }

    public function createSession(array $data)
    {
        try {
            // Validate input data
            $this->validateSessionData($data);

            // Extract Thawani-specific data
            $thawaniData = [
                'amount' => $data['amount'],
                'client_reference_id' => $data['client_reference_id'],
                'return_url' => $data['return_url'],
                'currency' => $data['currency']
            ];

            // Store metadata for later use
            $metadata = $data['metadata'] ?? [];
            $this->storeSessionMetadata($data['client_reference_id'], $metadata);

            $client = new \GuzzleHttp\Client();

            $response = $client->post($this->baseUrl . '/checkout/session', [
                'headers' => [
                    'Authorization' => 'Bearer ' . $this->apiKey,
                    'Content-Type'  => 'application/json',
                ],
                'json' => $thawaniData,
            ]);

            $result = json_decode($response->getBody(), true);
            
            \Log::info('Thawani session created', [
                'session_id' => $result['session_id'] ?? null,
                'client_reference_id' => $data['client_reference_id'],
                'amount' => $data['amount']
            ]);

            return [
                'success' => true,
                'session_id' => $result['session_id'],
                'payment_url' => $result['payment_url'] ?? null,
                'message' => 'Payment session created successfully'
            ];

        } catch (\GuzzleHttp\Exception\ClientException $e) {
            $errorResponse = json_decode($e->getResponse()->getBody(), true);
            \Log::error('Thawani API error', [
                'status' => $e->getResponse()->getStatusCode(),
                'error' => $errorResponse,
                'data' => $data
            ]);
            
            return [
                'success' => false,
                'message' => 'Failed to create checkout session',
                'error' => $errorResponse['message'] ?? 'Unknown error'
            ];
            
        } catch (\Exception $e) {
            \Log::error('Thawani service error', [
                'error' => $e->getMessage(),
                'data' => $data
            ]);
            
            return [
                'success' => false,
                'message' => 'Failed to create checkout session',
                'error' => $e->getMessage()
            ];
        }
    }

    private function validateSessionData(array $data)
    {
        $requiredFields = ['amount', 'client_reference_id', 'return_url', 'currency'];
        foreach ($requiredFields as $field) {
            if (!isset($data[$field])) {
                throw new \Exception("Missing required field: {$field}");
            }
        }

        if (!is_numeric($data['amount']) || $data['amount'] <= 0) {
            throw new \Exception('Amount must be a positive number in baisa');
        }

        if ($data['currency'] !== 'OMR') {
            throw new \Exception('Currency must be OMR');
        }

        if (!filter_var($data['return_url'], FILTER_VALIDATE_URL)) {
            throw new \Exception('Invalid return URL');
        }
    }

    private function storeSessionMetadata(string $clientReferenceId, array $metadata)
    {
        // Store metadata in database or cache for later use
        // This will be used when payment completes
        \Cache::put("session_metadata_{$clientReferenceId}", $metadata, 3600); // 1 hour
    }

    public function checkSessionStatus(string $sessionId)
    {
        try {
            $client = new \GuzzleHttp\Client();

            $response = $client->get($this->baseUrl . '/checkout/session/' . $sessionId, [
                'headers' => [
                    'Authorization' => 'Bearer ' . $this->apiKey,
                    'Content-Type'  => 'application/json',
                ],
            ]);

            $result = json_decode($response->getBody(), true);
            
            return [
                'success' => true,
                'status' => $result['status'] ?? 'unknown',
                'amount' => $result['amount'] ?? null,
                'currency' => $result['currency'] ?? null,
                'session_id' => $sessionId
            ];

        } catch (\Exception $e) {
            \Log::error('Thawani status check error', [
                'session_id' => $sessionId,
                'error' => $e->getMessage()
            ]);
            
            return [
                'success' => false,
                'message' => 'Failed to check payment status',
                'error' => $e->getMessage()
            ];
        }
    }
}
```

## Controller Implementation
```php
class PaymentController extends Controller
{
    private ThawaniService $thawaniService;

    public function __construct(ThawaniService $thawaniService)
    {
        $this->thawaniService = $thawaniService;
    }

    public function createPaymentSession(Request $request)
    {
        try {
            $result = $this->thawaniService->createSession($request->all());
            
            return response()->json($result);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 422);
        }
    }

    public function checkPaymentStatus($sessionId)
    {
        try {
            $result = $this->thawaniService->checkSessionStatus($sessionId);
            
            return response()->json($result);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 422);
        }
    }
}
```

## Configuration
```php
// config/services.php
'thawani' => [
    'secret_key' => env('THAWANI_API_KEY'),
    'publishable_key' => env('THAWANI_PUBLISHABLE_KEY'),
    'base_url' => env('THAWANI_URL'),
],
```

## Routes
```php
// routes/api.php
Route::post('/v1/payments/create', [PaymentController::class, 'createPaymentSession']);
Route::get('/v1/payments/status/{sessionId}', [PaymentController::class, 'checkPaymentStatus']);
```
