# 🔥 Donation API Integration Guide

## Overview
This document outlines the integration of the new donation system with the updated database schema that includes payment session tracking and status management.

## 📋 Database Schema Updates

### Laravel Migration Applied
```php
Schema::table('donations', function (Blueprint $table) {
    $table->string('payment_session_id')->nullable();
    $table->string('status')->default('pending');
    $table->decimal('paid_amount', 10, 2)->nullable();
});
```

### Updated Donation Model Fields
- `payment_session_id` - Tracks the payment session from Thawani
- `status` - Donation status (pending, completed, failed, cancelled, expired)
- `paid_amount` - Actual amount paid (may differ from requested amount)

## 🚀 API Endpoints

### 1. Create Donation with Direct Payment (الأسهل)
**Endpoint:** `POST /api/v1/donations/with-payment`

**Description:** Creates a donation and initiates payment in a single request - the easiest approach.

**Request Body:**
```json
{
  "campaign_id": "123", // or "program_id" for programs
  "amount": 100.00,
  "donor_name": "أحمد محمد",
  "donor_email": "ahmed@example.com",
  "donor_phone": "+96812345678",
  "message": "تبرع خيري",
  "is_anonymous": false
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "donation_123",
    "payment_session_id": "thawani_session_456",
    "status": "pending",
    "amount": 100.00,
    "payment_url": "https://checkout.thawani.om/pay/...",
    "message": "تم إنشاء التبرع بنجاح"
  }
}
```

### 2. Create Separate Payment Session
**Endpoint:** `POST /api/v1/payments/create`

**Description:** Creates a payment session separately from the donation record.

**Request Body:**
```json
{
  "amount": 100.00,
  "client_reference_id": "donation_1234567890_1234",
  "return_url": "https://example.com/return",
  "currency": "OMR",
  "products": [
    {
      "name": "تبرع خيري",
      "quantity": 1,
      "unit_amount": 10000
    }
  ],
  "metadata": {
    "donor_name": "أحمد محمد",
    "donor_email": "ahmed@example.com",
    "donor_phone": "+96812345678",
    "message": "تبرع خيري",
    "item_id": "123",
    "item_type": "campaign"
  }
}
```

**Response:**
```json
{
  "success": true,
  "session_id": "thawani_session_456",
  "payment_url": "https://checkout.thawani.om/pay/...",
  "message": "تم إنشاء جلسة الدفع بنجاح"
}
```

### 3. Check Payment Status
**Endpoint:** `GET /api/v1/payments/status/{sessionId}`

**Description:** Checks the status of a payment session.

**Response:**
```json
{
  "success": true,
  "status": "completed",
  "session_id": "thawani_session_456",
  "amount": 100.00,
  "currency": "OMR",
  "transaction_id": "txn_789",
  "completed_at": "2024-01-15T10:30:00Z",
  "message": "تم الدفع بنجاح"
}
```

## 🔧 Flutter Implementation

### Updated Donation Model
```dart
class Donation {
  final String id;
  final String? paymentSessionId;
  final String status;
  final double? paidAmount;
  final String campaignId;
  final String donorName;
  final double amount;
  final DateTime date;
  final String? message;
  final bool isAnonymous;

  // Helper methods
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => status == 'expired';
}
```

### DonationService Usage

#### Method 1: Direct Payment (Recommended)
```dart
final donationService = DonationService();

try {
  final result = await donationService.createDonationWithPayment(
    itemId: campaign.id,
    itemType: 'campaign',
    amount: 100.0,
    donorName: 'أحمد محمد',
    donorEmail: 'ahmed@example.com',
    donorPhone: '+96812345678',
    message: 'تبرع خيري',
    isAnonymous: false,
  );
  
  // Handle success
  print('Donation created: ${result['id']}');
  print('Payment URL: ${result['payment_url']}');
  
} catch (e) {
  // Handle error
  print('Error: $e');
}
```

#### Method 2: Separate Payment Session
```dart
final donationService = DonationService();

// Step 1: Create payment session
final paymentResponse = await donationService.createPaymentSession(
  amount: 100.0,
  clientReferenceId: donationService.generateClientReferenceId(),
  returnUrl: donationService.generateReturnUrl(),
  donorName: 'أحمد محمد',
  donorEmail: 'ahmed@example.com',
  donorPhone: '+96812345678',
  message: 'تبرع خيري',
  itemId: campaign.id,
  itemType: 'campaign',
);

if (paymentResponse.success) {
  // Step 2: Redirect to payment URL
  // Launch payment URL in WebView or browser
  
  // Step 3: Check payment status
  final statusResponse = await donationService.checkPaymentStatus(
    paymentResponse.sessionId!,
  );
  
  if (statusResponse.isCompleted) {
    // Step 4: Create donation record
    final donation = await donationService.createDonationRecord(
      itemId: campaign.id,
      itemType: 'campaign',
      amount: 100.0,
      paymentSessionId: paymentResponse.sessionId!,
      donorName: 'أحمد محمد',
      donorEmail: 'ahmed@example.com',
      donorPhone: '+96812345678',
      message: 'تبرع خيري',
    );
  }
}
```

#### Method 3: Status Monitoring
```dart
// Poll payment status
Timer.periodic(Duration(seconds: 5), (timer) async {
  final statusResponse = await donationService.checkPaymentStatus(sessionId);
  
  if (statusResponse.isCompleted) {
    timer.cancel();
    // Update UI and create donation record
    await donationService.updateDonationStatus(
      donationId: donation.id,
      status: 'completed',
      paidAmount: statusResponse.amount,
    );
  } else if (statusResponse.isFailed || statusResponse.isCancelled) {
    timer.cancel();
    // Handle failed payment
  }
});
```

## 📱 UI Integration Examples

### Campaign Donation Screen
```dart
class CampaignDonationScreen extends StatefulWidget {
  final Campaign campaign;
  
  @override
  _CampaignDonationScreenState createState() => _CampaignDonationScreenState();
}

class _CampaignDonationScreenState extends State<CampaignDonationScreen> {
  final DonationService _donationService = DonationService();
  bool _isLoading = false;
  
  Future<void> _makeDonation(double amount) async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _donationService.createDonationWithPayment(
        itemId: widget.campaign.id,
        itemType: 'campaign',
        amount: amount,
        donorName: _donorNameController.text,
        donorEmail: _donorEmailController.text,
        donorPhone: _donorPhoneController.text,
        message: _messageController.text,
        isAnonymous: _isAnonymous,
      );
      
      // Navigate to payment WebView
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebView(
            paymentUrl: result['payment_url'],
            sessionId: result['payment_session_id'],
          ),
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
```

### My Donations Screen
```dart
class MyDonationsScreen extends StatefulWidget {
  @override
  _MyDonationsScreenState createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  final DonationService _donationService = DonationService();
  List<Donation> _donations = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadDonations();
  }
  
  Future<void> _loadDonations() async {
    try {
      final donations = await _donationService.getUserDonations();
      setState(() {
        _donations = donations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
  
  Widget _buildDonationCard(Donation donation) {
    return Card(
      child: ListTile(
        title: Text('تبرع بقيمة ${donation.amount} ريال'),
        subtitle: Text(donation.message ?? ''),
        trailing: _buildStatusChip(donation.status),
        onTap: () {
          // Show donation details
        },
      ),
    );
  }
  
  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'completed':
        color = Colors.green;
        text = 'مكتمل';
        break;
      case 'pending':
        color = Colors.orange;
        text = 'قيد الانتظار';
        break;
      case 'failed':
        color = Colors.red;
        text = 'فشل';
        break;
      default:
        color = Colors.grey;
        text = status;
    }
    
    return Chip(
      label: Text(text, style: TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }
}
```

## 🔄 Payment Flow Diagrams

### Method 1: Direct Payment Flow
```
User → App → API (/donations/with-payment) → Thawani → Payment Gateway → Success/Failure
```

### Method 2: Separate Session Flow
```
User → App → API (/payments/create) → Thawani Session → Payment Gateway → Status Check → Donation Record
```

## 🛠️ Error Handling

### Common Error Responses
```json
{
  "success": false,
  "error": "انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.",
  "status_code": 401
}
```

### Error Handling in Flutter
```dart
try {
  final result = await donationService.createDonationWithPayment(...);
} on Exception catch (e) {
  if (e.toString().contains('401')) {
    // Handle authentication error
    Navigator.pushReplacementNamed(context, '/login');
  } else if (e.toString().contains('422')) {
    // Handle validation error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('بيانات غير صحيحة')),
    );
  } else {
    // Handle general error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('حدث خطأ غير متوقع')),
    );
  }
}
```

## 📊 Status Tracking

### Payment Status Values
- `pending` - Payment initiated but not completed
- `completed` - Payment successful
- `failed` - Payment failed
- `cancelled` - Payment cancelled by user
- `expired` - Payment session expired

### Status Update Triggers
1. **Automatic Updates:** Backend webhooks from Thawani
2. **Manual Polling:** App checks status periodically
3. **User Actions:** Manual refresh in My Donations screen

## 🔐 Security Considerations

1. **Authentication:** All donation endpoints require valid JWT token
2. **Validation:** Server-side validation of all donation data
3. **Encryption:** HTTPS for all API communications
4. **Session Management:** Secure payment session handling

## 🧪 Testing

### Test Payment Data
```json
{
  "card_number": "4111111111111111",
  "expiry": "12/25",
  "cvv": "123"
}
```

### Test Scenarios
1. Successful donation with direct payment
2. Failed payment handling
3. Cancelled payment flow
4. Expired session handling
5. Anonymous donation creation
6. Status polling and updates

## 📝 Migration Notes

### Breaking Changes
- Donation model now includes `paymentSessionId`, `status`, and `paidAmount`
- Payment flow requires status tracking
- Error handling updated for new response formats

### Backward Compatibility
- Existing donation records will have default values:
  - `payment_session_id`: null
  - `status`: 'pending'
  - `paid_amount`: null

## 🚀 Deployment Checklist

- [ ] Run Laravel migration for donations table
- [ ] Update Flutter app with new DonationService
- [ ] Test all three payment methods
- [ ] Verify status tracking works correctly
- [ ] Test error handling scenarios
- [ ] Update UI components to show new status fields
- [ ] Configure webhook endpoints for automatic status updates

## 📞 Support

For technical support or questions about the donation API integration, please refer to the API documentation or contact the development team.
