<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>{{ $title ?? 'AndanDO' }}</title>
</head>
<body style="margin:0; padding:0; background:#f4f7fb; font-family:Arial, Helvetica, sans-serif; color:#0f172a;">

<table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f7fb; padding:32px 0;">
    <tr>
        <td align="center">

            <table width="680" cellpadding="0" cellspacing="0" style="background:#ffffff; border-radius:18px; overflow:hidden; box-shadow:0 10px 35px rgba(15,23,42,0.10);">

                <!-- Header -->
                <tr>
                    <td style="background:#003b88; padding:28px 40px;">
                        <img src="{{ config('mail.logo_url') }}" alt="AndanDO" style="height:70px; display:block;">
                    </td>
                </tr>

                <!-- Hero / Content -->
                <tr>
                    <td style="padding:40px;">
                        @yield('content')
                    </td>
                </tr>

                <!-- Help -->
                <tr>
                    <td style="padding:0 40px 32px 40px;">
                        <table width="100%" cellpadding="0" cellspacing="0" style="background:#f1f6ff; border-radius:14px;">
                            <tr>
                                <td style="padding:22px;">
                                    <strong style="color:#003b88;">¿Necesitas ayuda?</strong><br>
                                    <span style="font-size:14px;">Estamos aquí para ti.</span>
                                </td>
                                <td style="padding:22px; text-align:right;">
                                    <a href="mailto:soporte@andando.do" style="color:#003b88; font-weight:bold; text-decoration:none;">
                                        soporte@andando.do
                                    </a><br>
                                    <span style="font-size:14px;">Lunes a domingo 8:00 AM - 8:00 PM</span>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>

                <!-- Footer -->
                <tr>
                    <td style="background:#003b88; color:#ffffff; padding:28px 40px;">
                        <table width="100%">
                            <tr>
                                <td>
                                    <img src="{{ config('mail.logo_url') }}" alt="AndanDO" style="height:52px; display:block;">
                                </td>
                                <td style="text-align:right; font-size:13px;">
                                    © {{ date('Y') }} AndanDO. Todos los derechos reservados.
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>

            </table>

        </td>
    </tr>
</table>

</body>
</html>