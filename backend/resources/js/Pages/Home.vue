<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { Head } from '@inertiajs/vue3'

const scrolled = ref(false)
const menuOpen = ref(false)

const onScroll = () => { scrolled.value = window.scrollY > 40 }

let io: IntersectionObserver | null = null

onMounted(() => {
  window.addEventListener('scroll', onScroll, { passive: true })
  onScroll()

  io = new IntersectionObserver((entries) => {
    entries.forEach((e) => {
      if (e.isIntersecting) {
        e.target.classList.add('in')
        if (e.target.classList.contains('route')) e.target.classList.add('drawn')
        io?.unobserve(e.target)
      }
    })
  }, { threshold: 0.15 })

  document.querySelectorAll('[data-reveal], .route').forEach((el) => io?.observe(el))
})

onBeforeUnmount(() => {
  window.removeEventListener('scroll', onScroll)
  io?.disconnect()
})
</script>

<template>
  <Head title="AndanDO · Descubre tu país andando" />

  <div class="andando">
    <!-- ====================== NAV ====================== -->
    <header
      class="fixed top-0 inset-x-0 z-50 transition-colors duration-300"
      :class="scrolled ? 'nav-solid text-[var(--c-ink)]' : 'text-white'"
    >
      <nav class="max-w-7xl mx-auto px-5 sm:px-8 h-[72px] flex items-center justify-between">
        <!-- LOGO (placeholder) -> sustituir por <img src="/images/logo-andando.svg" alt="AndanDO" class="h-8"> -->
        <a href="#" class="flex items-center gap-2.5">
          <span class="grid place-items-center w-9 h-9 rounded-xl bg-[var(--c-bermellon)] shadow-lg">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M12 2C7.6 2 4 5.5 4 9.8 4 15.4 12 22 12 22s8-6.6 8-12.2C20 5.5 16.4 2 12 2Z" fill="#fff"/><circle cx="12" cy="9.6" r="2.8" fill="var(--c-bermellon)"/></svg>
          </span>
          <span class="font-display font-extrabold text-[22px] tracking-tight">Andan<span class="text-[var(--c-bermellon)]">DO</span></span>
        </a>

        <div class="hidden md:flex items-center gap-8 text-[15px] font-semibold">
          <a href="#experiencias" class="hover:opacity-70 transition">Experiencias</a>
          <a href="#como" class="hover:opacity-70 transition">Cómo funciona</a>
          <a href="#anfitriones" class="hover:opacity-70 transition">Anfitriones</a>
        </div>

        <a href="#descarga" class="cta hidden sm:inline-flex items-center gap-2 bg-[var(--c-bermellon)] text-white font-bold text-[15px] px-5 py-2.5 rounded-full shadow-lg hover:bg-[var(--c-bermellon-deep)]">
          Descargar app
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M5 12h14M13 6l6 6-6 6" stroke="#fff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>
        </a>

        <button class="md:hidden grid place-items-center w-10 h-10" aria-label="Abrir menú" @click="menuOpen = !menuOpen">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none"><path d="M4 7h16M4 12h16M4 17h16" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/></svg>
        </button>
      </nav>

      <div v-show="menuOpen" class="md:hidden bg-white text-[var(--c-ink)] border-t border-[var(--c-arena)] px-5 py-4 space-y-1">
        <a href="#experiencias" class="block py-2.5 font-semibold" @click="menuOpen = false">Experiencias</a>
        <a href="#como" class="block py-2.5 font-semibold" @click="menuOpen = false">Cómo funciona</a>
        <a href="#anfitriones" class="block py-2.5 font-semibold" @click="menuOpen = false">Anfitriones</a>
        <a href="#descarga" class="cta mt-2 inline-flex items-center gap-2 bg-[var(--c-bermellon)] text-white font-bold px-5 py-2.5 rounded-full" @click="menuOpen = false">Descargar app</a>
      </div>
    </header>

    <!-- ====================== HERO ====================== -->
    <section class="relative overflow-hidden bg-[var(--c-mar)] text-white">
      <div class="glow absolute -top-24 -left-24 w-[420px] h-[420px] rounded-full bg-[var(--c-mar-bright)] opacity-50"></div>
      <div class="glow absolute top-40 -right-20 w-[360px] h-[360px] rounded-full bg-[var(--c-bermellon)] opacity-30"></div>
      <svg class="absolute inset-0 w-full h-full opacity-[0.12]" viewBox="0 0 1200 700" fill="none" preserveAspectRatio="xMidYMid slice" aria-hidden="true">
        <path d="M-50 560 C 250 560 280 280 520 300 S 820 520 1100 360 1300 180 1300 180" stroke="white" stroke-width="2.5" stroke-dasharray="2 14" stroke-linecap="round"/>
      </svg>

      <div class="relative max-w-7xl mx-auto px-5 sm:px-8 pt-32 pb-20 lg:pt-40 lg:pb-28 grid lg:grid-cols-[1.05fr_.95fr] gap-12 lg:gap-8 items-center">
        <div>
          <p class="rise d1 eyebrow text-[12px] sm:text-[13px] font-bold uppercase text-[var(--c-bermellon-bright)] mb-5 flex items-center gap-2">
            <span class="w-6 h-px bg-[var(--c-bermellon-bright)] inline-block"></span>
            Turismo interno · República Dominicana
          </p>
          <h1 class="rise d2 font-display font-extrabold leading-[0.98] tracking-tight text-[clamp(2.6rem,6.2vw,4.7rem)]">
            Descubre tu país,<br>
            <span class="relative inline-block">
              una experiencia
              <svg class="absolute -bottom-2 left-0 w-full" height="14" viewBox="0 0 300 14" fill="none" preserveAspectRatio="none" aria-hidden="true"><path d="M2 9C60 3 120 3 180 7s100 2 118-2" stroke="var(--c-bermellon)" stroke-width="5" stroke-linecap="round"/></svg>
            </span><br>
            a la vez.
          </h1>
          <p class="rise d3 mt-7 text-[17px] sm:text-[19px] leading-relaxed text-white/80 max-w-xl">
            AndanDO te conecta con anfitriones locales para vivir playas, montañas, cultura y aventura por toda RD. Explora, reserva y empieza a andar — todo desde una sola app.
          </p>
          <div class="rise d4 mt-9 flex flex-wrap items-center gap-4">
            <a href="#descarga" class="cta inline-flex items-center gap-2 bg-[var(--c-bermellon)] text-white font-bold text-[16px] px-7 py-4 rounded-full shadow-xl hover:bg-[var(--c-bermellon-deep)]">
              Descargar la app
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M12 3v12m0 0 4.5-4.5M12 15l-4.5-4.5M5 19h14" stroke="#fff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>
            </a>
            <a href="#como" class="inline-flex items-center gap-2 font-bold text-[16px] text-white/90 px-3 py-4 hover:text-white transition">
              <span class="grid place-items-center w-10 h-10 rounded-full border border-white/30">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M8 5v14l11-7L8 5Z" fill="#fff"/></svg>
              </span>
              Cómo funciona
            </a>
          </div>
          <div class="rise d5 mt-10 flex flex-wrap gap-x-6 gap-y-3 text-[13.5px] font-semibold text-white/75">
            <span class="flex items-center gap-2"><span class="text-[var(--c-bermellon-bright)]">●</span> Anfitriones verificados</span>
            <span class="flex items-center gap-2"><span class="text-[var(--c-bermellon-bright)]">●</span> Pago seguro</span>
            <span class="flex items-center gap-2"><span class="text-[var(--c-bermellon-bright)]">●</span> Cobertura nacional</span>
            <span class="flex items-center gap-2"><span class="text-[var(--c-bermellon-bright)]">●</span> Soporte local</span>
          </div>
        </div>

        <!-- phone mockup -->
        <div class="rise d3 relative justify-self-center lg:justify-self-end">
          <div class="floaty relative w-[270px] sm:w-[300px]">
            <div class="glow absolute inset-0 bg-[var(--c-bermellon)] opacity-40 rounded-[3rem]"></div>
            <div class="relative rounded-[2.6rem] bg-[#0A1452] p-3 shadow-2xl ring-1 ring-white/10">
              <div class="rounded-[2rem] overflow-hidden bg-white">
                <div class="bg-[var(--c-mar)] px-5 pt-4 pb-5 text-white">
                  <div class="flex items-center justify-between text-[11px] font-semibold opacity-80"><span>9:41</span><span>RD ▾</span></div>
                  <p class="mt-3 text-[13px] text-white/70">Hola, viajero 👋</p>
                  <p class="font-display font-extrabold text-[19px] leading-tight">¿Qué quieres<br>vivir hoy?</p>
                  <div class="mt-3 flex items-center gap-2 bg-white/15 rounded-full px-3.5 py-2 text-[12px] text-white/80">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><circle cx="11" cy="11" r="7" stroke="#fff" stroke-width="2"/><path d="m20 20-3-3" stroke="#fff" stroke-width="2" stroke-linecap="round"/></svg>
                    Buscar experiencias
                  </div>
                </div>
                <div class="px-4 pt-3 flex gap-2 text-[11px] font-bold">
                  <span class="px-3 py-1.5 rounded-full bg-[var(--c-bermellon)] text-white">Cerca de mí</span>
                  <span class="px-3 py-1.5 rounded-full bg-[var(--c-arena)] text-[var(--c-mar)]">Playas</span>
                  <span class="px-3 py-1.5 rounded-full bg-[var(--c-arena)] text-[var(--c-mar)]">Aventura</span>
                </div>
                <div class="p-4">
                  <div class="rounded-2xl overflow-hidden border border-[var(--c-arena)] shadow-sm">
                    <!-- IMG placeholder -> /images/exp-featured.jpg -->
                    <div class="h-28 bg-gradient-to-br from-[var(--c-mar-bright)] to-[var(--c-bermellon)] relative grid place-items-center">
                      <span class="absolute top-2 left-2 text-[10px] font-bold bg-white/90 text-[var(--c-mar)] px-2 py-0.5 rounded-full">Destacado</span>
                      <svg width="34" height="34" viewBox="0 0 24 24" fill="none" opacity=".9"><path d="M3 18l5-6 4 4 3-4 6 6" stroke="#fff" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/><circle cx="8" cy="7" r="2.2" fill="#fff"/></svg>
                    </div>
                    <div class="p-3">
                      <div class="flex items-center justify-between">
                        <p class="font-display font-bold text-[14px] text-[var(--c-ink)]">Salto El Limón</p>
                        <span class="text-[11px] font-bold text-[var(--c-bermellon)]">★ 4.9</span>
                      </div>
                      <p class="text-[11.5px] text-[var(--c-ink)]/55">Samaná · Senderismo + cascada</p>
                      <div class="mt-2 flex items-center justify-between">
                        <p class="text-[13px] font-extrabold text-[var(--c-mar)]">RD$ 1,500 <span class="text-[10px] font-medium text-[var(--c-ink)]/50">/ persona</span></p>
                        <span class="text-[11px] font-bold text-white bg-[var(--c-mar)] px-3 py-1.5 rounded-full">Reservar</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="absolute -left-6 top-28 bg-white rounded-2xl shadow-xl px-3.5 py-2.5 flex items-center gap-2 text-[var(--c-ink)] -rotate-6">
              <span class="grid place-items-center w-7 h-7 rounded-full bg-[var(--c-bermellon)]/10"><svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M12 2C8 2 5 5 5 8.5 5 13 12 21 12 21s7-8 7-12.5C19 5 16 2 12 2Z" fill="var(--c-bermellon)"/><circle cx="12" cy="8.5" r="2.3" fill="#fff"/></svg></span>
              <div><p class="text-[10px] font-semibold text-[var(--c-ink)]/55 leading-none">Anfitrión local</p><p class="text-[12px] font-bold leading-tight">Verificado ✓</p></div>
            </div>
          </div>
        </div>
      </div>

      <div class="relative -mb-px"><svg viewBox="0 0 1440 80" fill="none" class="w-full block" preserveAspectRatio="none"><path d="M0 80h1440V20c-240 40-480 40-720 20S240-10 0 20v60Z" fill="#fff"/></svg></div>
    </section>

    <!-- ====================== EXPERIENCIAS ====================== -->
    <section id="experiencias" class="py-20 sm:py-28 bg-white">
      <div class="max-w-7xl mx-auto px-5 sm:px-8">
        <div class="max-w-2xl" data-reveal>
          <p class="eyebrow text-[12px] font-bold uppercase text-[var(--c-bermellon)] mb-3">Qué puedes vivir</p>
          <h2 class="font-display font-extrabold text-[clamp(2rem,4.5vw,3.2rem)] leading-[1.02] tracking-tight text-[var(--c-ink)]">Un país entero por explorar</h2>
          <p class="mt-4 text-[17px] text-[var(--c-ink)]/65 leading-relaxed">Cada plan lo crea un anfitrión que conoce su tierra. Elige por lo que te mueve.</p>
        </div>

        <div class="mt-12 grid sm:grid-cols-2 lg:grid-cols-3 gap-5">
          <article data-reveal class="lift group rounded-3xl overflow-hidden border border-[var(--c-arena)] bg-white hover:shadow-2xl hover:border-transparent">
            <!-- IMG placeholder -> /images/exp-playas.jpg -->
            <div class="h-44 relative bg-gradient-to-br from-[#1FA2C9] to-[var(--c-mar)] grid place-items-center">
              <svg width="46" height="46" viewBox="0 0 24 24" fill="none" opacity=".95"><path d="M3 17c2 0 2-1.5 4.5-1.5S9.5 17 12 17s2-1.5 4.5-1.5S18.5 17 21 17" stroke="#fff" stroke-width="1.8" stroke-linecap="round"/><circle cx="17" cy="7" r="3" fill="#fff"/></svg>
              <span class="absolute top-3 left-3 flex items-center gap-1.5 text-[11px] font-bold text-white bg-white/15 px-2.5 py-1 rounded-full backdrop-blur"><span class="w-1.5 h-1.5 rounded-full bg-[var(--c-bermellon-bright)]"></span> Parada</span>
            </div>
            <div class="p-6">
              <h3 class="font-display font-bold text-[20px] text-[var(--c-ink)]">Playas & costa</h3>
              <p class="mt-1.5 text-[14.5px] text-[var(--c-ink)]/60 leading-relaxed">Cayos, snorkel y atardeceres frente al Caribe.</p>
            </div>
          </article>

          <article data-reveal class="lift group rounded-3xl overflow-hidden border border-[var(--c-arena)] bg-white hover:shadow-2xl hover:border-transparent">
            <!-- IMG placeholder -> /images/exp-montanas.jpg -->
            <div class="h-44 relative bg-gradient-to-br from-[#2E7D52] to-[var(--c-mar-deep)] grid place-items-center">
              <svg width="46" height="46" viewBox="0 0 24 24" fill="none" opacity=".95"><path d="m3 19 6-11 4 6 2-3 6 8H3Z" fill="#fff"/></svg>
              <span class="absolute top-3 left-3 flex items-center gap-1.5 text-[11px] font-bold text-white bg-white/15 px-2.5 py-1 rounded-full backdrop-blur"><span class="w-1.5 h-1.5 rounded-full bg-[var(--c-bermellon-bright)]"></span> Parada</span>
            </div>
            <div class="p-6">
              <h3 class="font-display font-bold text-[20px] text-[var(--c-ink)]">Montañas & aventura</h3>
              <p class="mt-1.5 text-[14.5px] text-[var(--c-ink)]/60 leading-relaxed">Senderismo, rafting y rutas de altura en Jarabacoa.</p>
            </div>
          </article>

          <article data-reveal class="lift group rounded-3xl overflow-hidden border border-[var(--c-arena)] bg-white hover:shadow-2xl hover:border-transparent">
            <!-- IMG placeholder -> /images/exp-cultura.jpg -->
            <div class="h-44 relative bg-gradient-to-br from-[var(--c-bermellon)] to-[#8A1E12] grid place-items-center">
              <svg width="46" height="46" viewBox="0 0 24 24" fill="none" opacity=".95"><path d="M4 21h16M5 21V9l7-4 7 4v12M9 21v-6h6v6" stroke="#fff" stroke-width="1.8" stroke-linejoin="round" stroke-linecap="round"/></svg>
              <span class="absolute top-3 left-3 flex items-center gap-1.5 text-[11px] font-bold text-white bg-white/15 px-2.5 py-1 rounded-full backdrop-blur"><span class="w-1.5 h-1.5 rounded-full bg-white"></span> Parada</span>
            </div>
            <div class="p-6">
              <h3 class="font-display font-bold text-[20px] text-[var(--c-ink)]">Cultura & historia</h3>
              <p class="mt-1.5 text-[14.5px] text-[var(--c-ink)]/60 leading-relaxed">Zona Colonial, museos y pueblos con alma.</p>
            </div>
          </article>

          <article data-reveal class="lift group rounded-3xl overflow-hidden border border-[var(--c-arena)] bg-white hover:shadow-2xl hover:border-transparent">
            <!-- IMG placeholder -> /images/exp-sabores.jpg -->
            <div class="h-44 relative bg-gradient-to-br from-[#C98A1F] to-[var(--c-bermellon-deep)] grid place-items-center">
              <svg width="46" height="46" viewBox="0 0 24 24" fill="none" opacity=".95"><path d="M7 3v8a3 3 0 0 0 6 0V3M10 3v18M17 3c-1.5 1-2 3-2 5s.5 4 2 5v8" stroke="#fff" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>
              <span class="absolute top-3 left-3 flex items-center gap-1.5 text-[11px] font-bold text-white bg-white/15 px-2.5 py-1 rounded-full backdrop-blur"><span class="w-1.5 h-1.5 rounded-full bg-white"></span> Parada</span>
            </div>
            <div class="p-6">
              <h3 class="font-display font-bold text-[20px] text-[var(--c-ink)]">Sabores & gastronomía</h3>
              <p class="mt-1.5 text-[14.5px] text-[var(--c-ink)]/60 leading-relaxed">Tours de café, cacao y cocina criolla.</p>
            </div>
          </article>

          <article data-reveal class="lift group rounded-3xl overflow-hidden border border-[var(--c-arena)] bg-white hover:shadow-2xl hover:border-transparent">
            <!-- IMG placeholder -> /images/exp-naturaleza.jpg -->
            <div class="h-44 relative bg-gradient-to-br from-[#1FA37A] to-[var(--c-mar)] grid place-items-center">
              <svg width="46" height="46" viewBox="0 0 24 24" fill="none" opacity=".95"><path d="M12 3C8 7 6 10 6 14a6 6 0 0 0 12 0c0-4-2-7-6-11Z" fill="#fff"/></svg>
              <span class="absolute top-3 left-3 flex items-center gap-1.5 text-[11px] font-bold text-white bg-white/15 px-2.5 py-1 rounded-full backdrop-blur"><span class="w-1.5 h-1.5 rounded-full bg-[var(--c-bermellon-bright)]"></span> Parada</span>
            </div>
            <div class="p-6">
              <h3 class="font-display font-bold text-[20px] text-[var(--c-ink)]">Naturaleza & cascadas</h3>
              <p class="mt-1.5 text-[14.5px] text-[var(--c-ink)]/60 leading-relaxed">Charcos de Damajagua, ríos y reservas naturales.</p>
            </div>
          </article>

          <article data-reveal class="lift group rounded-3xl overflow-hidden border border-[var(--c-arena)] bg-white hover:shadow-2xl hover:border-transparent">
            <!-- IMG placeholder -> /images/exp-mar.jpg -->
            <div class="h-44 relative bg-gradient-to-br from-[var(--c-mar-bright)] to-[#0A2A8A] grid place-items-center">
              <svg width="46" height="46" viewBox="0 0 24 24" fill="none" opacity=".95"><path d="M3 18c1.5 0 1.5-1 3-1s1.5 1 3 1 1.5-1 3-1 1.5 1 3 1 1.5-1 3-1M5 16l1-9 6 3 6-5v11" stroke="#fff" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg>
              <span class="absolute top-3 left-3 flex items-center gap-1.5 text-[11px] font-bold text-white bg-white/15 px-2.5 py-1 rounded-full backdrop-blur"><span class="w-1.5 h-1.5 rounded-full bg-[var(--c-bermellon-bright)]"></span> Parada</span>
            </div>
            <div class="p-6">
              <h3 class="font-display font-bold text-[20px] text-[var(--c-ink)]">Mar & navegación</h3>
              <p class="mt-1.5 text-[14.5px] text-[var(--c-ink)]/60 leading-relaxed">Avistamiento de ballenas, catamarán e islas.</p>
            </div>
          </article>
        </div>
      </div>
    </section>

    <!-- ====================== CÓMO FUNCIONA ====================== -->
    <section id="como" class="py-20 sm:py-28 bg-[var(--c-arena)] relative overflow-hidden">
      <div class="max-w-7xl mx-auto px-5 sm:px-8">
        <div class="max-w-2xl mb-14" data-reveal>
          <p class="eyebrow text-[12px] font-bold uppercase text-[var(--c-bermellon)] mb-3">Tu ruta en 3 pasos</p>
          <h2 class="font-display font-extrabold text-[clamp(2rem,4.5vw,3.2rem)] leading-[1.02] tracking-tight text-[var(--c-ink)]">De la idea al plan, andando</h2>
        </div>

        <div class="relative">
          <svg class="route hidden md:block absolute left-0 right-0 top-[56px] w-full pointer-events-none" height="40" viewBox="0 0 1000 40" fill="none" preserveAspectRatio="none" aria-hidden="true">
            <path d="M120 20 H880" stroke="var(--c-bermellon)" stroke-width="3" stroke-dasharray="3 12" stroke-linecap="round"/>
          </svg>

          <div class="grid md:grid-cols-3 gap-10 md:gap-6 relative">
            <div data-reveal class="text-center md:text-left">
              <div class="relative inline-grid md:flex place-items-center w-[112px] h-[112px] rounded-full bg-white shadow-xl mx-auto md:mx-0">
                <span class="font-display font-extrabold text-[40px] text-[var(--c-mar)]">01</span>
                <span class="absolute -top-1 -right-1 grid place-items-center w-9 h-9 rounded-full bg-[var(--c-bermellon)] shadow-lg">
                  <svg width="17" height="17" viewBox="0 0 24 24" fill="none"><circle cx="11" cy="11" r="7" stroke="#fff" stroke-width="2"/><path d="m20 20-3-3" stroke="#fff" stroke-width="2" stroke-linecap="round"/></svg>
                </span>
              </div>
              <h3 class="font-display font-bold text-[22px] mt-6 text-[var(--c-ink)]">Explora</h3>
              <p class="mt-2 text-[15.5px] text-[var(--c-ink)]/60 leading-relaxed max-w-xs mx-auto md:mx-0">Busca experiencias por zona, fecha o tipo de plan y descubre lo que tu país esconde.</p>
            </div>

            <div data-reveal class="text-center md:text-left">
              <div class="relative inline-grid md:flex place-items-center w-[112px] h-[112px] rounded-full bg-white shadow-xl mx-auto md:mx-0">
                <span class="font-display font-extrabold text-[40px] text-[var(--c-mar)]">02</span>
                <span class="absolute -top-1 -right-1 grid place-items-center w-9 h-9 rounded-full bg-[var(--c-bermellon)] shadow-lg">
                  <svg width="17" height="17" viewBox="0 0 24 24" fill="none"><path d="M5 12l4 4 10-10" stroke="#fff" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg>
                </span>
              </div>
              <h3 class="font-display font-bold text-[22px] mt-6 text-[var(--c-ink)]">Reserva</h3>
              <p class="mt-2 text-[15.5px] text-[var(--c-ink)]/60 leading-relaxed max-w-xs mx-auto md:mx-0">Aparta tu cupo en segundos con pago seguro. Sin filas, sin complicaciones.</p>
            </div>

            <div data-reveal class="text-center md:text-left">
              <div class="relative inline-grid md:flex place-items-center w-[112px] h-[112px] rounded-full bg-white shadow-xl mx-auto md:mx-0">
                <span class="font-display font-extrabold text-[40px] text-[var(--c-mar)]">03</span>
                <span class="absolute -top-1 -right-1 grid place-items-center w-9 h-9 rounded-full bg-[var(--c-bermellon)] shadow-lg">
                  <svg width="17" height="17" viewBox="0 0 24 24" fill="none"><path d="M12 2C8 2 5 5 5 8.5 5 13 12 21 12 21s7-8 7-12.5C19 5 16 2 12 2Z" fill="#fff"/><circle cx="12" cy="8.5" r="2.3" fill="var(--c-bermellon)"/></svg>
                </span>
              </div>
              <h3 class="font-display font-bold text-[22px] mt-6 text-[var(--c-ink)]">Andá</h3>
              <p class="mt-2 text-[15.5px] text-[var(--c-ink)]/60 leading-relaxed max-w-xs mx-auto md:mx-0">Vive el plan junto a un anfitrión local verificado. Tú solo disfruta el camino.</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- ====================== ANFITRIONES ====================== -->
    <section id="anfitriones" class="py-20 sm:py-24 bg-white">
      <div class="max-w-7xl mx-auto px-5 sm:px-8 grid lg:grid-cols-2 gap-12 items-center">
        <div data-reveal>
          <p class="eyebrow text-[12px] font-bold uppercase text-[var(--c-bermellon)] mb-3">¿Tienes algo que mostrar?</p>
          <h2 class="font-display font-extrabold text-[clamp(2rem,4.2vw,3rem)] leading-[1.04] tracking-tight text-[var(--c-ink)]">Conviértete en anfitrión y comparte tu rincón de RD</h2>
          <p class="mt-4 text-[17px] text-[var(--c-ink)]/65 leading-relaxed max-w-lg">Publica tus experiencias, llega a viajeros de todo el país y genera ingresos haciendo lo que amas. Nosotros ponemos la plataforma; tú, el lugar.</p>
          <div class="mt-7 flex flex-wrap gap-3">
            <span class="inline-flex items-center gap-2 bg-[var(--c-arena)] text-[var(--c-mar)] font-bold text-[14px] px-4 py-2.5 rounded-full">✓ Sin costo de publicación</span>
            <span class="inline-flex items-center gap-2 bg-[var(--c-arena)] text-[var(--c-mar)] font-bold text-[14px] px-4 py-2.5 rounded-full">✓ Cobros gestionados</span>
            <span class="inline-flex items-center gap-2 bg-[var(--c-arena)] text-[var(--c-mar)] font-bold text-[14px] px-4 py-2.5 rounded-full">✓ Verificación incluida</span>
          </div>
        </div>
        <div data-reveal class="relative">
          <!-- IMG placeholder -> /images/anfitrion.jpg -->
          <div class="aspect-[4/3] rounded-[2rem] bg-gradient-to-br from-[var(--c-mar)] via-[var(--c-mar-bright)] to-[var(--c-bermellon)] relative overflow-hidden shadow-2xl grid place-items-center">
            <svg class="absolute inset-0 w-full h-full opacity-20" viewBox="0 0 400 300" fill="none" preserveAspectRatio="none"><path d="M-20 220C80 220 100 120 200 130s140 80 240 30" stroke="#fff" stroke-width="2" stroke-dasharray="2 12"/></svg>
            <svg width="64" height="64" viewBox="0 0 24 24" fill="none" opacity=".9"><circle cx="12" cy="8" r="4" stroke="#fff" stroke-width="1.8"/><path d="M4 20c0-4 4-6 8-6s8 2 8 6" stroke="#fff" stroke-width="1.8" stroke-linecap="round"/></svg>
          </div>
        </div>
      </div>
    </section>

    <!-- ====================== DESCARGA ====================== -->
    <section id="descarga" class="relative overflow-hidden bg-[var(--c-mar-deep)] text-white">
      <div class="glow absolute -top-20 right-10 w-[380px] h-[380px] rounded-full bg-[var(--c-bermellon)] opacity-25"></div>
      <div class="glow absolute bottom-0 -left-20 w-[320px] h-[320px] rounded-full bg-[var(--c-mar-bright)] opacity-40"></div>
      <svg class="absolute inset-0 w-full h-full opacity-[0.10]" viewBox="0 0 1200 500" fill="none" preserveAspectRatio="xMidYMid slice" aria-hidden="true"><path d="M-50 380C250 380 280 120 520 160S900 360 1300 180" stroke="#fff" stroke-width="2.5" stroke-dasharray="2 14"/></svg>

      <div class="relative max-w-6xl mx-auto px-5 sm:px-8 py-20 sm:py-24 grid lg:grid-cols-2 gap-14 items-center">
        <div data-reveal>
          <p class="eyebrow text-[12px] font-bold uppercase text-[var(--c-bermellon-bright)] mb-4">Llévala en el bolsillo</p>
          <h2 class="font-display font-extrabold text-[clamp(2.1rem,4.8vw,3.4rem)] leading-[1.02] tracking-tight">Pronto, todo RD<br>en tu mano.</h2>
          <p class="mt-5 text-[17px] text-white/75 leading-relaxed max-w-md">AndanDO llega muy pronto a iOS y Android. Escanea el código y sé de los primeros en empezar a andar.</p>

          <!-- store badges (placeholder: próximamente) -->
          <div class="mt-8 flex flex-wrap gap-3">
            <span class="inline-flex items-center gap-3 bg-white/10 ring-1 ring-white/15 rounded-2xl px-5 py-3 cursor-default">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="#fff"><path d="M16.4 12.6c0-2 1.6-2.9 1.7-3-.9-1.4-2.4-1.6-2.9-1.6-1.2-.1-2.4.7-3 .7-.6 0-1.6-.7-2.6-.7-1.3 0-2.6.8-3.2 2-1.4 2.4-.4 6 1 8 .6 1 1.4 2.1 2.4 2 1-.04 1.3-.6 2.5-.6s1.5.6 2.6.6 1.7-1 2.3-2c.7-1.1 1-2.1 1-2.2-.1 0-2-.8-2-2.9ZM14.5 5.5c.5-.7.9-1.6.8-2.5-.8 0-1.7.5-2.3 1.2-.5.6-.9 1.5-.8 2.4.9.1 1.8-.4 2.3-1.1Z"/></svg>
              <span class="text-left leading-tight"><span class="block text-[10px] text-white/60 font-semibold">Próximamente en</span><span class="block text-[15px] font-bold">App Store</span></span>
            </span>
            <span class="inline-flex items-center gap-3 bg-white/10 ring-1 ring-white/15 rounded-2xl px-5 py-3 cursor-default">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none"><path d="M4 3.5 14.5 12 4 20.5c-.3.2-.7 0-.7-.4V3.9c0-.4.4-.6.7-.4Z" fill="#fff"/><path d="m13 10.5 3.6-2.1c.5-.3.5-1 0-1.3L13 5" stroke="#fff" stroke-width="1.6" stroke-linecap="round"/><path d="m13 13.5 3.6 2.1c.5.3.5 1 0 1.3L13 19" stroke="#fff" stroke-width="1.6" stroke-linecap="round"/></svg>
              <span class="text-left leading-tight"><span class="block text-[10px] text-white/60 font-semibold">Próximamente en</span><span class="block text-[15px] font-bold">Google Play</span></span>
            </span>
          </div>
          <p class="mt-4 text-[13px] text-white/45">Aún no publicada. Deja tu correo en la app o síguenos para el lanzamiento.</p>
        </div>

        <!-- QR placeholder -->
        <div data-reveal class="justify-self-center lg:justify-self-end">
          <div class="bg-white rounded-3xl p-7 shadow-2xl text-center w-[300px]">
            <!-- QR placeholder -> sustituir por <img src="/images/qr-descarga.svg" alt="QR para descargar AndanDO"> al publicar -->
            <div class="aspect-square rounded-2xl border-[3px] border-dashed border-[var(--c-mar)]/25 grid place-items-center bg-[var(--c-arena)]">
              <div class="text-center px-6">
                <svg width="52" height="52" viewBox="0 0 24 24" fill="none" class="mx-auto"><path d="M4 4h6v6H4V4ZM14 4h6v6h-6V4ZM4 14h6v6H4v-6Z" stroke="var(--c-mar)" stroke-width="1.6"/><path d="M14 14h2v2h-2zM18 14h2v2h-2zM14 18h2v2h-2zM18 18h2v2h-2z" fill="var(--c-mar)"/></svg>
                <p class="mt-3 text-[13px] font-bold text-[var(--c-mar)]">QR de descarga</p>
                <p class="text-[11.5px] text-[var(--c-ink)]/45">(placeholder · se activa al publicar)</p>
              </div>
            </div>
            <p class="mt-4 text-[14px] font-bold text-[var(--c-ink)]">Escanéalo con tu cámara</p>
            <p class="text-[12.5px] text-[var(--c-ink)]/50">Te llevará a la app cuando esté lista</p>
          </div>
        </div>
      </div>
    </section>

    <!-- ====================== FOOTER ====================== -->
    <footer class="bg-[#070E33] text-white/70">
      <div class="max-w-7xl mx-auto px-5 sm:px-8 py-14 grid sm:grid-cols-2 lg:grid-cols-[1.4fr_1fr_1fr_1fr] gap-10">
        <div>
          <!-- LOGO footer (placeholder) -->
          <a href="#" class="flex items-center gap-2.5 mb-4">
            <span class="grid place-items-center w-9 h-9 rounded-xl bg-[var(--c-bermellon)]">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M12 2C7.6 2 4 5.5 4 9.8 4 15.4 12 22 12 22s8-6.6 8-12.2C20 5.5 16.4 2 12 2Z" fill="#fff"/><circle cx="12" cy="9.6" r="2.8" fill="var(--c-bermellon)"/></svg>
            </span>
            <span class="font-display font-extrabold text-[22px] text-white tracking-tight">Andan<span class="text-[var(--c-bermellon)]">DO</span></span>
          </a>
          <p class="text-[14px] leading-relaxed max-w-xs">Turismo interno hecho fácil. Conectamos viajeros con anfitriones locales por toda República Dominicana.</p>
        </div>
        <div>
          <p class="font-bold text-white text-[14px] mb-4">Explora</p>
          <ul class="space-y-2.5 text-[14px]">
            <li><a href="#experiencias" class="hover:text-white transition">Experiencias</a></li>
            <li><a href="#como" class="hover:text-white transition">Cómo funciona</a></li>
            <li><a href="#descarga" class="hover:text-white transition">Descargar app</a></li>
          </ul>
        </div>
        <div>
          <p class="font-bold text-white text-[14px] mb-4">Anfitriones</p>
          <ul class="space-y-2.5 text-[14px]">
            <li><a href="#anfitriones" class="hover:text-white transition">Publica tu experiencia</a></li>
            <li><a href="#" class="hover:text-white transition">Centro de ayuda</a></li>
            <li><a href="#" class="hover:text-white transition">Verificación</a></li>
          </ul>
        </div>
        <div>
          <p class="font-bold text-white text-[14px] mb-4">Legal</p>
          <ul class="space-y-2.5 text-[14px]">
            <li><a href="#" class="hover:text-white transition">Términos</a></li>
            <li><a href="#" class="hover:text-white transition">Privacidad</a></li>
            <li><a href="#" class="hover:text-white transition">Contacto</a></li>
          </ul>
        </div>
      </div>
      <div class="border-t border-white/10">
        <div class="max-w-7xl mx-auto px-5 sm:px-8 py-6 flex flex-col sm:flex-row items-center justify-between gap-3 text-[13px]">
          <p>© 2026 AndanDO · Hecho en República Dominicana 🇩🇴</p>
          <div class="flex items-center gap-4">
            <a href="#" aria-label="Instagram" class="hover:text-white transition"><svg width="20" height="20" viewBox="0 0 24 24" fill="none"><rect x="3" y="3" width="18" height="18" rx="5" stroke="currentColor" stroke-width="1.8"/><circle cx="12" cy="12" r="4" stroke="currentColor" stroke-width="1.8"/><circle cx="17" cy="7" r="1.2" fill="currentColor"/></svg></a>
            <a href="#" aria-label="Facebook" class="hover:text-white transition"><svg width="20" height="20" viewBox="0 0 24 24" fill="none"><path d="M14 8h2V5h-2c-1.7 0-3 1.3-3 3v2H9v3h2v6h3v-6h2l1-3h-3V8c0-.001.4 0 1 0Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg></a>
            <a href="#" aria-label="TikTok" class="hover:text-white transition"><svg width="20" height="20" viewBox="0 0 24 24" fill="none"><path d="M14 4c.5 2.5 2 4 4.5 4.2v3C16.8 11 15.5 10.4 14 9.4V15a5 5 0 1 1-5-5c.3 0 .7 0 1 .1v3a2 2 0 1 0 1 1.8V4h3Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/></svg></a>
          </div>
        </div>
      </div>
    </footer>
  </div>
</template>

<style scoped>
/* Fuentes: idealmente añade el <link> en tu app.blade.php (ver instrucciones).
   Este @import garantiza que funcione aunque no lo agregues. */
@import url('https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,400..800&family=Manrope:wght@400..800&display=swap');

.andando{
  --c-mar:#1B2E9E;
  --c-mar-deep:#111C66;
  --c-mar-bright:#2D49F0;
  --c-bermellon:#EE4128;
  --c-bermellon-deep:#D8351C;
  --c-bermellon-bright:#FF6A3D;
  --c-ink:#0B1240;
  --c-arena:#EEF1FF;

  font-family:'Manrope',system-ui,sans-serif;
  color:var(--c-ink);
  -webkit-font-smoothing:antialiased;
}
.font-display{ font-family:'Bricolage Grotesque','Manrope',sans-serif; }
.eyebrow{ letter-spacing:.18em; }

.nav-solid{
  background:rgba(255,255,255,.88);
  backdrop-filter:blur(12px);
  box-shadow:0 1px 0 rgba(11,18,64,.08), 0 12px 40px -28px rgba(11,18,64,.5);
}

/* Carga del hero */
@keyframes rise{ from{opacity:0; transform:translateY(22px)} to{opacity:1; transform:translateY(0)} }
.rise{ opacity:0; animation:rise .8s cubic-bezier(.22,1,.36,1) forwards; }
.d1{animation-delay:.05s}.d2{animation-delay:.18s}.d3{animation-delay:.31s}.d4{animation-delay:.44s}.d5{animation-delay:.57s}

/* Reveal al hacer scroll */
:deep([data-reveal]){ opacity:0; transform:translateY(28px); transition:opacity .7s cubic-bezier(.22,1,.36,1), transform .7s cubic-bezier(.22,1,.36,1); }
:deep([data-reveal].in){ opacity:1; transform:none; }

/* Trazado de la ruta */
:deep(.route) path{ stroke-dasharray:1; stroke-dashoffset:1; }
:deep(.route.drawn) path{ animation:draw 1.6s ease forwards; }
@keyframes draw{ to{ stroke-dashoffset:0 } }

.lift{ transition:transform .35s cubic-bezier(.22,1,.36,1), box-shadow .35s ease, border-color .35s ease; }
.lift:hover{ transform:translateY(-6px); }

.cta{ transition:transform .2s ease, box-shadow .25s ease, background .25s ease; }
.cta:hover{ transform:translateY(-2px); }
.cta:active{ transform:translateY(0); }

a:focus-visible, button:focus-visible{ outline:3px solid var(--c-bermellon); outline-offset:3px; border-radius:6px; }

@keyframes float{ 0%,100%{transform:translateY(0)} 50%{transform:translateY(-12px)} }
.floaty{ animation:float 6s ease-in-out infinite; }
.glow{ filter:blur(60px); }

@media (prefers-reduced-motion: reduce){
  .rise,:deep([data-reveal]),:deep(.route) path,.floaty{
    animation:none !important; opacity:1 !important; transform:none !important; transition:none !important; stroke-dashoffset:0 !important;
  }
}
</style>