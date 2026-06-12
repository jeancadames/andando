<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <style>
        @page { margin: 0; }

        body {
            margin: 0;
            font-family: DejaVu Sans, sans-serif;
            color: #0f172a;
            background: #ffffff;
            font-size: 12px;
        }

        .header {
            background: #003b73;
            color: white;
            padding: 24px 36px 30px;
        }

        .logo-box {
            background: white;
            border-radius: 16px;
            width: 110px;
            height: 48px;
            text-align: center;
            line-height: 48px;
            margin-bottom: 20px;
        }

        .logo {
            max-width: 86px;
            max-height: 34px;
            vertical-align: middle;
        }

        .doc-number {
            float: right;
            text-align: right;
            font-size: 11px;
            margin-top: 4px;
        }

        .confirmed {
            color: #00e676;
            font-weight: bold;
            margin-bottom: 8px;
            font-size: 13px;
        }

        h1 {
            margin: 0 0 6px;
            font-size: 24px;
            letter-spacing: .4px;
        }

        .issued {
            font-size: 11px;
            color: #dbeafe;
        }

        .content {
            padding: 20px 36px 26px;
        }

        .cover {
            height: 155px;
            border-radius: 16px;
            overflow: hidden;
            background: #e5e7eb;
            margin-bottom: 16px;
        }

        .cover img {
            width: 100%;
            height: 155px;
            object-fit: cover;
        }

        .category {
            display: inline-block;
            background: #dc2626;
            color: white;
            padding: 5px 9px;
            border-radius: 999px;
            font-size: 10px;
            font-weight: bold;
            margin-bottom: 7px;
        }

        .experience-title {
            font-size: 20px;
            font-weight: bold;
            margin-bottom: 14px;
            color: #0f172a;
            page-break-inside: avoid;
        }

        .box {
            border-radius: 16px;
            padding: 14px;
            margin-bottom: 12px;
            page-break-inside: avoid;
            break-inside: avoid;
        }

        .blue-box {
            background: #eff6ff;
            border: 1px solid #bfdbfe;
        }

        .yellow-box {
            background: #fffbeb;
            border: 1px solid #fde68a;
        }

        .gray-box {
            background: #f1f5f9;
        }

        .red-box {
            background: #fff1f2;
            border: 1px solid #fecdd3;
        }

        .section-title {
            font-size: 12px;
            font-weight: bold;
            letter-spacing: .6px;
            color: #003b73;
            margin-bottom: 10px;
            text-transform: uppercase;
        }

        .grid {
            width: 100%;
        }

        .grid td {
            width: 50%;
            padding: 5px 0;
            vertical-align: top;
        }

        .label {
            color: #64748b;
            font-size: 10px;
        }

        .value {
            font-size: 12px;
            font-weight: bold;
            color: #0f172a;
            margin-top: 2px;
        }

        .divider {
            border-top: 2px dashed #e5e7eb;
            margin: 16px 0;
        }

        .section-block {
            page-break-inside: avoid !important;
            break-inside: avoid !important;
        }

        .avatar {
            width: 38px;
            height: 38px;
            border-radius: 50%;
            background: #003b73;
            color: white;
            text-align: center;
            line-height: 38px;
            font-weight: bold;
            font-size: 14px;
        }

        .included-item {
            margin-bottom: 7px;
            color: #334155;
        }

        .check {
            color: #22c55e;
            font-weight: bold;
            margin-right: 6px;
        }

        .payment-row {
            width: 100%;
            margin-bottom: 10px;
            page-break-inside: avoid;
        }

        .payment-row td:last-child {
            text-align: right;
            font-weight: bold;
        }

        .total {
            font-size: 18px;
            color: #003b73;
            font-weight: bold;
        }

        .footer {
            background: #003b73;
            color: white;
            padding: 18px 36px;
            text-align: center;
            page-break-inside: avoid;
        }

        .footer-logo-box {
            background: white;
            border-radius: 14px;
            width: 92px;
            height: 40px;
            text-align: center;
            line-height: 40px;
            margin-bottom: 10px;
        }

        .footer-logo {
            max-width: 72px;
            max-height: 28px;
            vertical-align: middle;
        }

        .small {
            font-size: 10px;
            color: #64748b;
        }

        .footer .small {
            color: #bfdbfe;
        }
    </style>
</head>
<body>

<div class="header">
    <div class="doc-number">
        Documento No.<br>
        <strong>{{ $booking->booking_code }}</strong>
    </div>

    <div class="logo-box">
        @if($logoPath)
            <img class="logo" src="{{ $logoPath }}">
        @else
            <strong style="color:#003b73;">AndanDO</strong>
        @endif
    </div>

    <div class="confirmed">✓ Reserva Confirmada</div>
    <h1>COMPROBANTE DE RESERVA</h1>
    <div class="issued">
        Emitido el {{ now()->locale('es')->translatedFormat('d \d\e F \d\e Y') }}
    </div>
</div>

<div class="content">

    <div class="cover">
        @if($coverPath)
            <img src="{{ $coverPath }}">
        @endif
    </div>

    @if($experience?->category)
        <div class="category">{{ $experience->category }}</div>
    @endif

    <div class="experience-title">
        {{ $experience?->title ?? 'Experiencia reservada' }}
    </div>

    <div class="box blue-box section-block">
        <div class="section-title">Detalles de la experiencia</div>

        <table class="grid">
            <tr>
                <td>
                    <div class="label">Fecha</div>
                    <div class="value">
                        {{ $startsAt ? $startsAt->locale('es')->translatedFormat('d \d\e F \d\e Y') : 'No especificada' }}
                    </div>
                </td>
                <td>
                    <div class="label">Hora de inicio</div>
                    <div class="value">
                        {{ $startsAt ? $startsAt->format('h:i A') : 'No especificada' }}
                    </div>
                </td>
            </tr>
            <tr>
                <td>
                    <div class="label">Viajeros</div>
                    <div class="value">
                        {{ $booking->guests_count }}
                        {{ $booking->guests_count == 1 ? 'persona' : 'personas' }}
                    </div>
                </td>
                <td>
                    <div class="label">Duración</div>
                    <div class="value">
                        {{ $experience?->duration ?? 'No especificada' }}
                    </div>
                </td>
            </tr>
        </table>
    </div>

    <div class="box yellow-box section-block">
        <div class="section-title" style="color:#b45309;">Punto de recogida</div>

        <div class="value">
            {{ $pickupPointText }}
        </div>

        <div class="small" style="margin-top:6px; color:#92400e;">
            Preséntate en este punto 15 minutos antes del inicio de la experiencia.
        </div>

        <div class="small" style="margin-top:6px; color:#92400e;">
            Si tienes dudas sobre cómo llegar, contacta al proveedor desde la app antes de la salida.
        </div>
    </div>

    <div class="section-block">
        <div class="divider"></div>

        <table style="width:100%;">
            <tr>
                <td style="width:50%; vertical-align:top;">
                    <div class="section-title">Código de reserva</div>

                    <div class="value" style="font-size:17px; color:#003b73;">
                        {{ $booking->booking_code }}
                    </div>

                    <div style="margin-top:9px;">
                        <div><span class="check">✓</span> Pago verificado</div>
                        <div><span class="check">✓</span> Confirmación instantánea</div>
                        <div><span class="check">✓</span> Proveedor verificado</div>
                    </div>
                </td>

                <td style="width:50%; vertical-align:top; padding-left:24px;">
                    <div class="section-title">Titular de la reserva</div>

                    <table style="width:100%;">
                        <tr>
                            <td style="width:46px;">
                                <div class="avatar">
                                    {{ strtoupper(mb_substr($booking->customer_name ?? 'C', 0, 1)) }}
                                </div>
                            </td>
                            <td>
                                <div class="value">{{ $booking->customer_name }}</div>
                                <div class="small">{{ $booking->customer_email }}</div>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
        </table>

        <div class="divider"></div>
    </div>

    @if(count($includedItems) > 0)
        <div class="section-block" style="margin-top:12px;">
            <div class="section-title">Incluido en tu experiencia</div>

            @foreach($includedItems as $item)
                <div class="included-item">
                    <span class="check">✓</span> {{ $item }}
                </div>
            @endforeach
        </div>
    @endif

    <div class="divider"></div>

    <div class="section-block">
        <div class="section-title">Resumen de pago</div>

        <table class="payment-row">
            <tr>
                <td>
                    RD${{ number_format((float) $booking->unit_price, 2) }}
                    × {{ $booking->guests_count }}
                    {{ $booking->guests_count == 1 ? 'persona' : 'personas' }}
                </td>
                <td>RD${{ number_format((float) $booking->total_amount, 2) }}</td>
            </tr>
        </table>

        <div style="border-top:1px solid #e5e7eb; margin:12px 0;"></div>

        <table class="payment-row">
            <tr>
                <td><strong>Total pagado</strong></td>
                <td class="total">RD${{ number_format((float) $booking->total_amount, 2) }}</td>
            </tr>
        </table>
    </div>

    <div class="box gray-box section-block" style="margin-top:14px;">
        <div class="section-title">Proveedor de la experiencia</div>
        <div class="value">
            {{ $provider?->business_name ?? $provider?->name ?? 'Proveedor AndanDO' }}
        </div>

        @if($provider?->phone)
            <div style="margin-top:8px;">Tel: {{ $provider->phone }}</div>
        @endif

        @if($provider?->email)
            <div>Email: {{ $provider->email }}</div>
        @endif
    </div>

    <div class="box red-box section-block">
        <div class="section-title" style="color:#dc2626;">Política de cancelación</div>
        <div>
            {{ $cancellationPolicyText }}
        </div>
    </div>

</div>

<div class="footer section-block">
    <div class="footer-logo-box">
        @if($logoPath)
            <img class="footer-logo" src="{{ $logoPath }}">
        @else
            <strong style="color:#003b73;">AndanDO</strong>
        @endif
    </div>

    <div class="small">
        Este comprobante es tu documento oficial de reserva. Preséntalo al proveedor al inicio de tu experiencia.
    </div>

    <div style="margin-top:12px; font-size:11px;">
        República Dominicana<br>
        andando.com.do
    </div>

    <div class="small" style="margin-top:10px;">
        © {{ now()->year }} AndanDO · {{ $booking->booking_code }}
    </div>
</div>

</body>
</html>