@extends('emails.layouts.app')

@section('content')

<h1 style="font-size:36px; line-height:1.1; color:#003b88; margin:0 0 16px;">
    Tu solicitud necesita <span style="color:#ef233c;">revisión</span>
</h1>

<p style="font-size:16px; line-height:1.7;">
    Hola <strong>{{ $user->name }}</strong>,
</p>

<p style="font-size:16px; line-height:1.7;">
    Revisamos tu solicitud como afiliado en AndanDO, pero por el momento no pudo ser aprobada.
</p>

<table width="100%" cellpadding="0" cellspacing="0"
       style="border:1px solid #e5e7eb; border-radius:16px; margin:30px 0;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin-top:0;">
                Detalles de la revisión
            </h3>

            <p><strong>Negocio:</strong> {{ $provider?->business_name ?? 'No especificado' }}</p>
            <p><strong>Estado:</strong> No aprobado</p>
            <p><strong>Motivo:</strong> {{ $verificationRequest->rejection_reason ?? $provider?->rejection_reason ?? 'No especificado' }}</p>
        </td>
    </tr>
</table>

<table width="100%" cellpadding="0" cellspacing="0"
       style="background:#f1f6ff; border-radius:16px; margin-bottom:30px;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin-top:0;">
                ¿Qué puedes hacer?
            </h3>

            <p>✓ Revisa el motivo indicado.</p>
            <p>✓ Corrige la información o documentos necesarios.</p>
            <p>✓ Contacta a soporte si necesitas orientación.</p>
            <p>✓ Podrás enviar nuevamente tu solicitud cuando esté lista.</p>
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
        Revisar mi solicitud
    </a>
</div>

@endsection