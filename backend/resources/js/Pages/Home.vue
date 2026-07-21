<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { Head } from '@inertiajs/vue3'

const scrolled = ref(false)
const menuOpen = ref(false)
const logoError = ref(false)        // nav: cae al wordmark si aún no subes el archivo
const logoErrorFooter = ref(false)  // footer: idem, versión blanca

const words = ['playas', 'montañas', 'cascadas', 'rutas de café', 'aventuras']
const wordIndex = ref(0)

const cats = ['Playas', 'Montañas', 'Cascadas', 'Zona Colonial', 'Ballenas', 'Café & cacao', 'Rafting', 'Islas', 'Senderismo', 'Cenotes', 'Gastronomía', 'Kitesurf']
const marqueeCats = [...cats, ...cats] // duplicado para loop continuo

const onScroll = () => { scrolled.value = window.scrollY > 40 }

let io: IntersectionObserver | null = null
let wordTimer: number | undefined

onMounted(() => {
  window.addEventListener('scroll', onScroll, { passive: true })
  onScroll()

  wordTimer = window.setInterval(() => {
    wordIndex.value = (wordIndex.value + 1) % words.length
  }, 1900)

  io = new IntersectionObserver((entries) => {
    entries.forEach((e) => {
      if (e.isIntersecting) { e.target.classList.add('in'); io?.unobserve(e.target) }
    })
  }, { threshold: 0.15 })
  document.querySelectorAll('[data-reveal]').forEach((el) => io?.observe(el))
})

onBeforeUnmount(() => {
  window.removeEventListener('scroll', onScroll)
  window.clearInterval(wordTimer)
  io?.disconnect()
})
</script>

<template>
  <Head title="AndanDO · Descubre tu país andando" />

  <div class="andando">
    <!-- ===== NAV ===== -->
    <header
      class="fixed top-0 inset-x-0 z-50 transition-colors duration-300"
      :class="scrolled ? 'nav-solid' : ''"
    >
      <nav class="max-w-7xl mx-auto px-5 sm:px-8 h-[70px] flex items-center justify-between">
        <!-- LOGO: sube tu archivo a  public/images/logo-andando.png  y aparece solo -->
        <a href="#" class="flex items-center gap-2.5">
          <img
            v-if="!logoError"
            src="/images/logo-andando.png"
            alt="AndanDO"
            class="h-12 w-auto"
            @error="logoError = true"
          />
          <template v-else>
            <span class="grid place-items-center w-9 h-9 rounded-2xl bg-[var(--blue)]">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M12 2C7.6 2 4 5.5 4 9.8 4 15.4 12 22 12 22s8-6.6 8-12.2C20 5.5 16.4 2 12 2Z" fill="#fff"/><circle cx="12" cy="9.6" r="2.8" fill="var(--blue)"/></svg>
            </span>
            <span class="display font-extrabold text-[22px] tracking-tight text-[var(--blue)]">Andan<span class="text-[var(--red)]">DO</span></span>
          </template>
        </a>

        <div class="hidden md:flex items-center gap-8 text-[15px] font-semibold text-[var(--ink)]">
          <a href="#como" class="hover:text-[var(--blue)] transition">Cómo funciona</a>
          <a href="#anfitriones" class="hover:text-[var(--blue)] transition">Anfitriones</a>
        </div>

        <a href="#descarga" class="cta hidden sm:inline-flex items-center gap-2 bg-[var(--blue)] text-white font-bold text-[15px] px-5 py-2.5 rounded-2xl hover:brightness-110">
          Descargar app
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M5 12h14M13 6l6 6-6 6" stroke="#fff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>
        </a>

        <button class="md:hidden grid place-items-center w-10 h-10 text-[var(--blue)]" aria-label="Menú" @click="menuOpen = !menuOpen">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none"><path d="M4 7h16M4 12h16M4 17h16" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/></svg>
        </button>
      </nav>

      <div v-show="menuOpen" class="md:hidden bg-white border-t border-[var(--line)] px-5 py-4 space-y-1 text-[var(--ink)]">
        <a href="#como" class="block py-2.5 font-semibold" @click="menuOpen = false">Cómo funciona</a>
        <a href="#anfitriones" class="block py-2.5 font-semibold" @click="menuOpen = false">Anfitriones</a>
        <a href="#descarga" class="mt-2 inline-flex bg-[var(--blue)] text-white font-bold px-5 py-2.5 rounded-2xl" @click="menuOpen = false">Descargar app</a>
      </div>
    </header>

    <!-- ===== HERO (centrado) ===== -->
    <section class="relative overflow-hidden bg-white pt-32 pb-20 sm:pt-40 sm:pb-24">
      <!-- motivo de ruta muy sutil detrás -->
      <svg class="absolute inset-x-0 top-24 mx-auto w-full max-w-5xl h-full opacity-[0.06] pointer-events-none" viewBox="0 0 1000 400" fill="none" preserveAspectRatio="xMidYMid meet" aria-hidden="true">
        <path d="M20 320 C 220 320 240 120 460 150 S 780 320 980 120" stroke="var(--blue)" stroke-width="3" stroke-dasharray="2 14" stroke-linecap="round"/>
      </svg>

      <div class="relative max-w-4xl mx-auto px-5 sm:px-8 text-center">
        <p class="rise d1 eyebrow inline-flex items-center gap-2 text-[12px] font-bold uppercase text-[var(--blue)] bg-[var(--blue-050)] px-3.5 py-1.5 rounded-full mb-7">
          <span class="w-1.5 h-1.5 rounded-full bg-[var(--red)]"></span> Turismo interno · República Dominicana
        </p>
        <h1 class="rise d2 display font-extrabold leading-[0.98] tracking-tight text-[clamp(2.6rem,6.5vw,5rem)] text-[var(--blue)]">
          Descubre las mejores
          <span class="rot h-[1.05em] align-bottom">
            <span
              v-for="(w, i) in words"
              :key="w"
              :class="{ on: wordIndex === i }"
            >{{ w }}</span>
          </span><br>
          de tu país.
        </h1>
        <p class="rise d3 mt-7 text-[17px] sm:text-[19px] leading-relaxed text-[var(--ink)]/70 max-w-2xl mx-auto">
          AndanDO te conecta con anfitriones locales para vivir playas, montañas, cultura y aventura por toda RD. Explora, reserva y empieza a andar — todo desde una sola app.
        </p>
        <div class="rise d4 mt-9 flex flex-wrap items-center justify-center gap-3.5">
          <a href="#descarga" class="cta inline-flex items-center gap-2 bg-[var(--blue)] text-white font-bold text-[16px] px-7 py-4 rounded-2xl shadow-lg shadow-[var(--blue)]/30 hover:brightness-110">
            Descargar la app
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M12 3v12m0 0 4.5-4.5M12 15l-4.5-4.5M5 19h14" stroke="#fff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>
          </a>
          <a href="#como" class="inline-flex items-center gap-2 font-bold text-[16px] text-[var(--blue)] px-4 py-4 hover:underline">
            Cómo funciona
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M5 12h14M13 6l6 6-6 6" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>
          </a>
        </div>
        <div class="rise d5 mt-9 flex flex-wrap justify-center gap-x-5 gap-y-2 text-[13px] font-semibold text-[var(--muted)]">
          <span class="flex items-center gap-1.5"><span class="text-[var(--red)]">●</span> Anfitriones verificados</span>
          <span class="flex items-center gap-1.5"><span class="text-[var(--red)]">●</span> Pago seguro</span>
          <span class="flex items-center gap-1.5"><span class="text-[var(--red)]">●</span> Cobertura nacional</span>
        </div>
      </div>
    </section>

    <!-- ===== MARQUEE ===== -->
    <section class="py-4 bg-[var(--blue)] overflow-hidden">
      <div class="marquee">
        <div class="track text-white">
          <span
            v-for="(c, i) in marqueeCats"
            :key="i"
            class="inline-flex items-center gap-2 text-[15px] font-bold px-4 py-2 rounded-full bg-white/10 ring-1 ring-white/15"
          >
            <span class="w-1.5 h-1.5 rounded-full bg-[var(--red)]"></span>{{ c }}
          </span>
        </div>
      </div>
    </section>

    <!-- ===== CÓMO FUNCIONA ===== -->
    <section id="como" class="py-20 sm:py-24 bg-white">
      <div class="max-w-7xl mx-auto px-5 sm:px-8">
        <div class="max-w-2xl mb-12" data-reveal>
          <p class="eyebrow text-[12px] font-bold uppercase text-[var(--red)] mb-3">Tu ruta en 3 pasos</p>
          <h2 class="display font-extrabold text-[clamp(1.9rem,4.2vw,3rem)] leading-[1.03] tracking-tight text-[var(--blue)]">De la idea al plan, andando</h2>
        </div>
        <div class="grid md:grid-cols-3 gap-5">
          <div data-reveal class="lift rounded-2xl border border-[var(--line)] p-7 hover:shadow-xl hover:shadow-[var(--blue)]/10">
            <div class="flex items-center justify-between">
              <span class="display font-extrabold text-[36px] text-[var(--blue)]">01</span>
              <span class="grid place-items-center w-11 h-11 rounded-2xl bg-[var(--blue-050)]"><svg width="20" height="20" viewBox="0 0 24 24" fill="none"><circle cx="11" cy="11" r="7" stroke="var(--blue)" stroke-width="2"/><path d="m20 20-3-3" stroke="var(--blue)" stroke-width="2" stroke-linecap="round"/></svg></span>
            </div>
            <h3 class="display font-bold text-[21px] mt-5 text-[var(--ink)]">Explora</h3>
            <p class="mt-2 text-[15px] text-[var(--ink)]/60 leading-relaxed">Filtra por zona, fecha o tipo de plan y descubre lo que tu país esconde.</p>
          </div>
          <div data-reveal class="lift rounded-2xl border border-[var(--line)] p-7 hover:shadow-xl hover:shadow-[var(--blue)]/10">
            <div class="flex items-center justify-between">
              <span class="display font-extrabold text-[36px] text-[var(--blue)]">02</span>
              <span class="grid place-items-center w-11 h-11 rounded-2xl bg-[var(--blue-050)]"><svg width="20" height="20" viewBox="0 0 24 24" fill="none"><path d="M5 12l4 4 10-10" stroke="var(--blue)" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg></span>
            </div>
            <h3 class="display font-bold text-[21px] mt-5 text-[var(--ink)]">Reserva</h3>
            <p class="mt-2 text-[15px] text-[var(--ink)]/60 leading-relaxed">Aparta tu cupo en segundos con pago seguro. Sin filas, sin llamadas.</p>
          </div>
          <div data-reveal class="lift rounded-2xl p-7 bg-[var(--blue)] text-white">
            <div class="flex items-center justify-between">
              <span class="display font-extrabold text-[36px] text-white">03</span>
              <span class="grid place-items-center w-11 h-11 rounded-2xl bg-white/15"><svg width="20" height="20" viewBox="0 0 24 24" fill="none"><path d="M12 2C8 2 5 5 5 8.5 5 13 12 21 12 21s7-8 7-12.5C19 5 16 2 12 2Z" fill="#fff"/><circle cx="12" cy="8.5" r="2.3" fill="var(--blue)"/></svg></span>
            </div>
            <h3 class="display font-bold text-[21px] mt-5">Andá</h3>
            <p class="mt-2 text-[15px] text-white/80 leading-relaxed">Vive el plan junto a un anfitrión local verificado. Tú solo disfruta.</p>
          </div>
        </div>
      </div>
    </section>

    <!-- ===== ANFITRIONES ===== -->
    <section id="anfitriones" class="py-20 bg-[var(--surface)]">
      <div class="max-w-7xl mx-auto px-5 sm:px-8 grid lg:grid-cols-2 gap-12 items-center">
        <div data-reveal>
          <p class="eyebrow text-[12px] font-bold uppercase text-[var(--red)] mb-3">¿Tienes algo que mostrar?</p>
          <h2 class="display font-extrabold text-[clamp(1.9rem,4vw,2.8rem)] leading-[1.05] tracking-tight text-[var(--blue)]">Sé anfitrión y comparte tu rincón de RD</h2>
          <p class="mt-4 text-[17px] text-[var(--ink)]/65 leading-relaxed max-w-lg">Publica tus experiencias, llega a viajeros de todo el país y genera ingresos haciendo lo que amas.</p>
          <div class="mt-6 flex flex-wrap gap-2.5">
            <span class="bg-white border border-[var(--line)] text-[var(--ink)] font-bold text-[14px] px-4 py-2.5 rounded-full">✓ Sin costo de publicación</span>
            <span class="bg-white border border-[var(--line)] text-[var(--ink)] font-bold text-[14px] px-4 py-2.5 rounded-full">✓ Cobros gestionados</span>
            <span class="bg-white border border-[var(--line)] text-[var(--ink)] font-bold text-[14px] px-4 py-2.5 rounded-full">✓ Verificación incluida</span>
          </div>
          <a href="#descarga" class="inline-block mt-6 text-[15px] font-bold text-[var(--red)] underline decoration-[var(--red)] underline-offset-4">Me interesa ser afiliado →</a>
        </div>
        <div data-reveal class="relative">
          <!-- IMG placeholder -> sube  public/images/anfitrion.jpg  y cambia el div por <img> -->
          <div class="aspect-[4/3] rounded-2xl bg-[var(--blue)] relative overflow-hidden grid place-items-center">
            <svg class="absolute inset-0 w-full h-full opacity-20" viewBox="0 0 400 300" preserveAspectRatio="none"><path d="M-20 220C80 220 100 120 200 130s140 80 240 30" stroke="#fff" stroke-width="2" stroke-dasharray="2 12" fill="none"/></svg>
            <svg width="60" height="60" viewBox="0 0 24 24" fill="none" opacity=".9"><circle cx="12" cy="8" r="4" stroke="#fff" stroke-width="1.8"/><path d="M4 20c0-4 4-6 8-6s8 2 8 6" stroke="#fff" stroke-width="1.8" stroke-linecap="round"/></svg>
          </div>
        </div>
      </div>
    </section>

    <!-- ===== DESCARGA ===== -->
    <section id="descarga" class="relative overflow-hidden bg-[var(--blue)] text-white">
      <div class="relative max-w-6xl mx-auto px-5 sm:px-8 py-20 grid lg:grid-cols-2 gap-12 items-center">
        <div data-reveal>
          <p class="eyebrow text-[12px] font-bold uppercase text-white/70 mb-4">Llévala en el bolsillo</p>
          <h2 class="display font-extrabold text-[clamp(2rem,4.6vw,3.2rem)] leading-[1.02] tracking-tight">Pronto, todo RD<br>en tu mano.</h2>
          <p class="mt-5 text-[17px] text-white/80 leading-relaxed max-w-md">AndanDO llega muy pronto a iOS y Android. Escanea el código y sé de los primeros en andar.</p>
          <div class="mt-8 flex flex-wrap gap-3">
            <span class="inline-flex items-center gap-3 bg-white/12 ring-1 ring-white/20 rounded-2xl px-5 py-3">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="#fff"><path d="M16.4 12.6c0-2 1.6-2.9 1.7-3-.9-1.4-2.4-1.6-2.9-1.6-1.2-.1-2.4.7-3 .7-.6 0-1.6-.7-2.6-.7-1.3 0-2.6.8-3.2 2-1.4 2.4-.4 6 1 8 .6 1 1.4 2.1 2.4 2 1-.04 1.3-.6 2.5-.6s1.5.6 2.6.6 1.7-1 2.3-2c.7-1.1 1-2.1 1-2.2-.1 0-2-.8-2-2.9ZM14.5 5.5c.5-.7.9-1.6.8-2.5-.8 0-1.7.5-2.3 1.2-.5.6-.9 1.5-.8 2.4.9.1 1.8-.4 2.3-1.1Z"/></svg>
              <span class="leading-tight"><span class="block text-[10px] text-white/70 font-semibold">Próximamente en</span><span class="block text-[15px] font-bold">App Store</span></span>
            </span>
            <span class="inline-flex items-center gap-3 bg-white/12 ring-1 ring-white/20 rounded-2xl px-5 py-3">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none"><path d="M4 3.5 14.5 12 4 20.5c-.3.2-.7 0-.7-.4V3.9c0-.4.4-.6.7-.4Z" fill="#fff"/><path d="m13 10.5 3.6-2.1c.5-.3.5-1 0-1.3L13 5" stroke="#fff" stroke-width="1.6" stroke-linecap="round"/><path d="m13 13.5 3.6 2.1c.5.3.5 1 0 1.3L13 19" stroke="#fff" stroke-width="1.6" stroke-linecap="round"/></svg>
              <span class="leading-tight"><span class="block text-[10px] text-white/70 font-semibold">Próximamente en</span><span class="block text-[15px] font-bold">Google Play</span></span>
            </span>
          </div>
        </div>
        <div data-reveal class="justify-self-center lg:justify-self-end">
          <div class="floaty bg-white rounded-2xl p-7 shadow-2xl text-center w-[290px]">
            <!-- QR placeholder -> sustituir por <img src="/images/qr-descarga.svg"> al publicar -->
            <div class="aspect-square rounded-2xl border-[3px] border-dashed border-[var(--blue)]/30 grid place-items-center bg-[var(--blue-050)]">
              <div class="px-6"><svg width="50" height="50" viewBox="0 0 24 24" fill="none" class="mx-auto"><path d="M4 4h6v6H4V4ZM14 4h6v6h-6V4ZM4 14h6v6H4v-6Z" stroke="var(--blue)" stroke-width="1.6"/><path d="M14 14h2v2h-2zM18 14h2v2h-2zM14 18h2v2h-2zM18 18h2v2h-2z" fill="var(--blue)"/></svg>
              <p class="mt-3 text-[13px] font-bold text-[var(--blue)]">QR de descarga</p><p class="text-[11px] text-[var(--ink)]/45">(placeholder)</p></div>
            </div>
            <p class="mt-4 text-[14px] font-bold text-[var(--ink)]">Escanéalo con tu cámara</p>
          </div>
        </div>
      </div>
    </section>

    <!-- ===== FOOTER ===== -->
    <footer class="bg-[var(--ink)] text-white/65">
      <div class="max-w-7xl mx-auto px-5 sm:px-8 py-12 flex flex-col sm:flex-row items-center justify-between gap-4">
        <a href="#" class="flex items-center gap-2.5">
          <!-- opcional: versión blanca en  public/images/logo-andando-white.png -->
          <img
            v-if="!logoErrorFooter"
            src="/images/logo-andando-white.png"
            alt="AndanDO"
            class="h-8 w-auto"
            @error="logoErrorFooter = true"
          />
          <template v-else>
            <span class="grid place-items-center w-9 h-9 rounded-2xl bg-[var(--red)]"><svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M12 2C7.6 2 4 5.5 4 9.8 4 15.4 12 22 12 22s8-6.6 8-12.2C20 5.5 16.4 2 12 2Z" fill="#fff"/><circle cx="12" cy="9.6" r="2.8" fill="var(--red)"/></svg></span>
            <span class="display font-extrabold text-[20px] text-white">Andan<span class="text-[var(--red)]">DO</span></span>
          </template>
        </a>
        <p class="text-[13px]">© 2026 AndanDO · Hecho en República Dominicana 🇩🇴</p>
      </div>
    </footer>
  </div>
</template>

<style scoped>
/* Fuentes: idealmente añade el <link> en app.blade.php (ver nota). Este @import lo hace funcionar sin tocar nada. */
@import url('https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,400..800&family=Manrope:wght@400..800&display=swap');

.andando{
  /* ===== COLORES EXACTOS DE LA APP (bandera RD) ===== */
  --blue:#002D62;   /* AppColors.primaryBlue · argb 255,0,45,98 */
  --red:#CE1126;    /* AppColors.primaryRed  · argb 255,206,17,38 */
  --ink:#0E1726;    /* textDark (inferido) */
  --muted:#8A94A6;  /* mutedForeground */
  --line:#E5E7EB;
  --surface:#F8F9FA;
  --blue-050: color-mix(in srgb, var(--blue) 8%, white);
  --red-050:  color-mix(in srgb, var(--red) 10%, white);

  font-family:'Manrope',system-ui,sans-serif;
  color:var(--ink);
  -webkit-font-smoothing:antialiased;
}
.display{ font-family:'Bricolage Grotesque','Manrope',sans-serif; }
.eyebrow{ letter-spacing:.16em; }

.nav-solid{
  background:rgba(255,255,255,.92);
  backdrop-filter:blur(14px);
  box-shadow:0 1px 0 rgba(14,23,38,.06), 0 16px 44px -30px rgba(14,23,38,.5);
}

@keyframes rise{ from{opacity:0; transform:translateY(20px)} to{opacity:1; transform:translateY(0)} }
.rise{ opacity:0; animation:rise .8s cubic-bezier(.22,1,.36,1) forwards; }
.d1{animation-delay:.05s}.d2{animation-delay:.16s}.d3{animation-delay:.27s}.d4{animation-delay:.38s}.d5{animation-delay:.5s}

[data-reveal]{ opacity:0; transform:translateY(26px); transition:opacity .7s cubic-bezier(.22,1,.36,1), transform .7s cubic-bezier(.22,1,.36,1); }
[data-reveal].in{ opacity:1; transform:none; }

.rot{ display:inline-grid; }
.rot > span{ grid-area:1/1; opacity:0; transform:translateY(14px); transition:opacity .5s, transform .5s; color:var(--red); white-space:nowrap; }
.rot > span.on{ opacity:1; transform:none; }

.track{ display:flex; gap:12px; width:max-content; animation:marq 34s linear infinite; }
.marquee:hover .track{ animation-play-state:paused; }
@keyframes marq{ to{ transform:translateX(-50%) } }

.lift{ transition:transform .3s cubic-bezier(.22,1,.36,1), box-shadow .3s, border-color .3s; }
.lift:hover{ transform:translateY(-5px); }
.cta{ transition:transform .2s, box-shadow .25s, filter .25s; }
.cta:hover{ transform:translateY(-2px); }
@keyframes float{ 0%,100%{transform:translateY(0)} 50%{transform:translateY(-9px)} }
.floaty{ animation:float 6s ease-in-out infinite; }

a:focus-visible, button:focus-visible{ outline:3px solid var(--red); outline-offset:3px; border-radius:8px; }

@media (prefers-reduced-motion: reduce){
  .rise,[data-reveal],.track,.floaty{ animation:none !important; transition:none !important; }
  .rise,[data-reveal]{ opacity:1 !important; transform:none !important; }
}
</style>
