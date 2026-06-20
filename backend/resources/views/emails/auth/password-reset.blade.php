@extends('emails.layouts.app')

@section('content')

<h1 style="font-size:36px; color:#003b88; margin-bottom:16px;">
    Recupera tu contraseña 🔐
</h1>

<p style="font-size:16px; line-height:1.7;">
    Hola <strong>{{ $user->name }}</strong>,
</p>

<p style="font-size:16px; line-height:1.7;">
    Recibimos una solicitud para restablecer la contraseña de tu cuenta en AndanDO.
</p>

<table width="100%" cellpadding="0" cellspacing="0"
       style="background:#f1f6ff; border-radius:16px; margin:30px 0;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin-top:0;">
                Información importante
            </h3>

            <p>✓ Este enlace expirará pronto por seguridad.</p>
            <p>✓ Si no solicitaste este cambio, puedes ignorar este correo.</p>
            <p>✓ Nunca compartas este enlace con nadie.</p>
        </td>
    </tr>
</table>

<div style="text-align:center;">
    <a href="{{ $resetUrl }}"
       style="background:#ef233c;
              color:white;
              padding:14px 34px;
              text-decoration:none;
              border-radius:8px;
              font-weight:bold;
              display:inline-block;">
        Crear nueva contraseña
    </a>
</div>

<p style="font-size:13px; line-height:1.6; color:#64748b; margin-top:28px;">
    Si el botón no funciona, copia y pega este enlace en tu navegador:<br>
    <span style="word-break:break-all;">{{ $resetUrl }}</span>
</p>

@endsection