@extends('emails.layouts.app')

@section('content')

<h1 style="font-size:36px; color:#003b88; margin-bottom:16px;">
    Contraseña actualizada 🔐
</h1>

<p style="font-size:16px; line-height:1.7;">
    Hola <strong>{{ $user->name }}</strong>,
</p>

<p style="font-size:16px; line-height:1.7;">
    Te confirmamos que la contraseña de tu cuenta AndanDO fue actualizada correctamente.
</p>

<table width="100%" cellpadding="0" cellspacing="0"
       style="background:#f1f6ff; border-radius:16px; margin:30px 0;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin-top:0;">
                Información de seguridad
            </h3>

            <p>✓ Tu contraseña ha sido modificada.</p>
            <p>✓ Si realizaste este cambio, no necesitas hacer nada más.</p>
            <p>✓ Si no reconoces esta acción, contacta inmediatamente a soporte.</p>
        </td>
    </tr>
</table>

<div style="text-align:center;">
    <a href="mailto:soporte@andando.do"
       style="background:#ef233c;
              color:white;
              padding:14px 34px;
              text-decoration:none;
              border-radius:8px;
              font-weight:bold;">
        Contactar soporte
    </a>
</div>

@endsection