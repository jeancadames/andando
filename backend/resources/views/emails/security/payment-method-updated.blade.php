@extends('emails.layouts.app')

@section('content')

@php
    $actionLabels = [
        'created' => 'agregaste una nueva tarjeta',
        'default_updated' => 'cambiaste tu tarjeta principal',
        'deleted' => 'eliminaste una tarjeta',
    ];

    $actionText = $actionLabels[$action] ?? 'actualizaste tus métodos de pago';
@endphp

<h1 style="font-size:36px; color:#003b88; margin-bottom:16px;">
    Método de pago actualizado 💳
</h1>

<p style="font-size:16px; line-height:1.7;">
    Hola <strong>{{ $user->name }}</strong>,
</p>

<p style="font-size:16px; line-height:1.7;">
    Te confirmamos que {{ $actionText }} en tu cuenta AndanDO.
</p>

<table width="100%" cellpadding="0" cellspacing="0"
       style="border:1px solid #e5e7eb; border-radius:16px; margin:30px 0;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin-top:0;">
                Detalles
            </h3>

            <p><strong>Acción:</strong> {{ ucfirst($actionText) }}</p>

            @if ($paymentMethod)
                <p><strong>Marca:</strong> {{ strtoupper($paymentMethod->brand ?? 'Tarjeta') }}</p>
                <p><strong>Terminación:</strong> **** {{ $paymentMethod->last4 }}</p>
                <p><strong>Titular:</strong> {{ $paymentMethod->holder_name }}</p>
                <p><strong>Vencimiento:</strong>
                    {{ str_pad((string) $paymentMethod->expiry_month, 2, '0', STR_PAD_LEFT) }}/{{ substr((string) $paymentMethod->expiry_year, -2) }}
                </p>
            @else
                <p><strong>Tarjeta:</strong> Método eliminado</p>
            @endif

            <p><strong>Fecha:</strong> {{ now()->format('d/m/Y h:i A') }}</p>
        </td>
    </tr>
</table>

<table width="100%" cellpadding="0" cellspacing="0"
       style="background:#f1f6ff; border-radius:16px; margin-bottom:30px;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin-top:0;">
                Seguridad
            </h3>

            <p>✓ AndanDO no guarda el número completo de tu tarjeta.</p>
            <p>✓ Nunca almacenamos tu código CVV.</p>
            <p>✓ Si no reconoces esta acción, contacta soporte inmediatamente.</p>
        </td>
    </tr>
</table>

<div style="text-align:center;">
    <a href="mailto:soporte@andando.do"
       style="background:#ef233c;
              color:white;
              padding:14px 34px;
              border-radius:8px;
              text-decoration:none;
              font-weight:bold;
              display:inline-block;">
        Contactar soporte
    </a>
</div>

@endsection