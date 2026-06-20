@extends('emails.layouts.app')

@section('content')

<h1 style="font-size:36px; line-height:1.1; color:#003b88; margin:0 0 16px;">
    ¡Tu perfil fue <span style="color:#ef233c;">aprobado</span>! 🎉
</h1>

<p style="font-size:16px; line-height:1.7;">
    Hola <strong>{{ $user->name }}</strong>,
</p>

<p style="font-size:16px; line-height:1.7;">
    Tu solicitud como afiliado en AndanDO fue aprobada correctamente.
    Ya puedes comenzar a gestionar tus experiencias desde tu panel.
</p>

<table width="100%" cellpadding="0" cellspacing="0"
       style="border:1px solid #e5e7eb; border-radius:16px; margin:30px 0;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin-top:0;">
                Información del afiliado
            </h3>

            <p><strong>Negocio:</strong> {{ $provider?->business_name ?? 'No especificado' }}</p>
            <p><strong>Tipo de negocio:</strong> {{ $provider?->businessType?->name ?? 'No especificado' }}</p>
            <p><strong>Estado:</strong> Aprobado</p>
        </td>
    </tr>
</table>

<table width="100%" cellpadding="0" cellspacing="0"
       style="background:#f1f6ff; border-radius:16px; margin-bottom:30px;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin-top:0;">
                Próximos pasos
            </h3>

            <p>✓ Completa o revisa tu perfil de afiliado.</p>
            <p>✓ Publica tus experiencias.</p>
            <p>✓ Configura horarios, precios y cupos.</p>
            <p>✓ Mantente atento a nuevas reservas.</p>
        </td>
    </tr>
</table>

<div style="text-align:center;">
    <a href="{{ $actionUrl ?? '#' }}"
       style="background:#ef233c;
              color:white;
              padding:14px 34px;
              border-radius:8px;
              text-decoration:none;
              font-weight:bold;
              display:inline-block;">
        Ir a mi panel
    </a>
</div>

@endsection