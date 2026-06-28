<?php

return [

    'gateway' => env('PAYMENT_GATEWAY', 'fake_azul'),

    'environment' => env('PAYMENT_ENV', 'test'),

    'azul' => [

        'payment_page' => [
            'enabled' => env('AZUL_PAYMENT_PAGE_ENABLED', false),
            'environment' => env('AZUL_PAYMENT_PAGE_ENV', 'test'),
            'url' => env('AZUL_PAYMENT_PAGE_URL'),
            'merchant_id' => env('AZUL_MERCHANT_ID'),
            'merchant_name' => env('AZUL_MERCHANT_NAME', 'AndanDO'),
            'merchant_type' => env('AZUL_MERCHANT_TYPE', 'ECommerce'),
            'currency_code' => env('AZUL_CURRENCY_CODE', '$'),
            'private_key' => env('AZUL_PRIVATE_KEY'),
            'approved_url' => env('AZUL_PAYMENT_PAGE_APPROVED_URL'),
            'declined_url' => env('AZUL_PAYMENT_PAGE_DECLINED_URL'),
            'cancel_url' => env('AZUL_PAYMENT_PAGE_CANCEL_URL'),
            'save_to_datavault' => env('AZUL_SAVE_TO_DATAVAULT', 1),
            'tokenization_amount' => env('AZUL_TOKENIZATION_AMOUNT', '100'),
            'tokenization_itbis' => env('AZUL_TOKENIZATION_ITBIS', '000'),
            'payment_method_return_url' => env('AZUL_PAYMENT_METHOD_RETURN_URL'),
        ],

        'webservices' => [
            'enabled' => env('AZUL_WEBSERVICES_ENABLED', false),
            'environment' => env('AZUL_WEBSERVICES_ENV', 'test'),
            'url' => env('AZUL_WEBSERVICES_URL'),
            'channel' => env('AZUL_WEBSERVICES_CHANNEL', 'EC'),
            'store' => env('AZUL_WEBSERVICES_STORE'),
            'auth1' => env('AZUL_WEBSERVICES_AUTH1'),
            'auth2' => env('AZUL_WEBSERVICES_AUTH2'),
            'timeout' => env('AZUL_WEBSERVICES_TIMEOUT', 120),
        ],

    ],

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

        // Comisión total de AndanDO cuando la experiencia se completa.
        // Ej: 0.15 = 15%, proveedor recibe 85%.
        'andando_commission_rate' => env('ANDANDO_COMMISSION_RATE', 0.15),

        // Política de devolución al cliente cuando cancela dentro del período permitido
        // luego de que ya se cobró.
        'customer_policy_refund_percent' => env('CUSTOMER_POLICY_REFUND_PERCENT', 95),

        // Retención de AndanDO en cancelación con devolución parcial.
        // Ej: 5% retenido, cliente recibe 95%.
        'customer_policy_cancellation_fee_percent' => env('CUSTOMER_POLICY_CANCELLATION_FEE_PERCENT', 5),
    ],

];