@extends('emails.layouts.app')

@section('content')

<h1 style="font-size:36px; color:#003b88; margin-bottom:16px;">
    Experiencia pausada ⚠️
</h1>

<p style="font-size:16px; line-height:1.7;">
    Hola <strong>{{ $user->name }}</strong>,
</p>

<p style="font-size:16px; line-height:1.7;">
    Te informamos que una de tus experiencias fue pausada por el equipo de AndanDO.
</p>

<table width="100%" cellpadding="0" cellspacing="0"
       style="border:1px solid #e5e7eb; border-radius:16px; margin:30px 0;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin-top:0;">
                Detalles de la experiencia
            </h3>

            <p><strong>Experiencia:</strong> {{ $experience->title }}</p>
            <p><strong>Provincia:</strong> {{ $experience->province ?? 'No especificada' }}</p>
            <p><strong>Estado:</strong> Pausada / desactivada</p>
        </td>
    </tr>
</table>

<table width="100%" cellpadding="0" cellspacing="0"
       style="background:#f1f6ff; border-radius:16px; margin-bottom:30px;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin-top:0;">
                ¿Qué significa esto?
            </h3>

            <p>✓ La experiencia ya no estará visible para nuevas reservas.</p>
            <p>✓ El equipo de AndanDO puede revisarla antes de reactivarla.</p>
            <p>✓ Si tienes dudas, contacta a soporte.</p>
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