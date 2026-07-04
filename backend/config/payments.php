<?php

return [

    'gateway' => env('PAYMENT_GATEWAY', 'fake_azul'),

    'environment' => env('PAYMENT_ENV', 'test'),

    'fake_azul' => [
        'enabled' => env('FAKE_AZUL_ENABLED', true),
        'force_result' => env('FAKE_AZUL_FORCE_RESULT', 'approved'),
        'default_brand' => env('FAKE_AZUL_DEFAULT_BRAND', 'VISA'),
        'default_expiration' => env('FAKE_AZUL_DEFAULT_EXPIRATION', '203412'),
        'default_card_mask' => env('FAKE_AZUL_DEFAULT_CARD_MASK', '426055******5872'),
        'fake_auth_code' => env('FAKE_AZUL_FAKE_AUTH_CODE', 'OK1234'),
        'fake_azul_order_id' => env('FAKE_AZUL_FAKE_AZUL_ORDER_ID', '99999999'),
        'fake_rrn' => env('FAKE_AZUL_FAKE_RRN', '202606270001'),
    ],

    'rules' => [
        'booking_min_free_cancel_hours' => env('BOOKING_MIN_FREE_CANCEL_HOURS', 24),
        'provider_payout_release_days' => env('PROVIDER_PAYOUT_RELEASE_DAYS', 3),
        'andando_commission_rate' => env('ANDANDO_COMMISSION_RATE', 0.15),
        'customer_policy_refund_percent' => env('CUSTOMER_POLICY_REFUND_PERCENT', 95),
        'customer_policy_cancellation_fee_percent' => env('CUSTOMER_POLICY_CANCELLATION_FEE_PERCENT', 5),
    ],

];