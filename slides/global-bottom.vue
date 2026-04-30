<script setup>
import { useNav } from '@slidev/client'
import { computed } from 'vue'

const nav = useNav()

const currentPage = computed(() => nav.currentPage.value)
const total = computed(() => nav.total.value)
const isFirst = computed(() => currentPage.value <= 1)
const isLast = computed(() => currentPage.value >= total.value)
const progressWidth = computed(() => ((currentPage.value / total.value) * 100) + '%')

function goPrev() {
  nav.prev()
}
function goNext() {
  nav.next()
}
</script>

<template>
  <div class="slide-nav-controls">
    <!-- Left Arrow -->
    <button
      class="nav-arrow nav-arrow-left"
      :class="{ 'nav-arrow-disabled': isFirst }"
      :disabled="isFirst"
      @click="goPrev"
      aria-label="Slide anterior"
    >
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="15 18 9 12 15 6" />
      </svg>
    </button>

    <!-- Right Arrow -->
    <button
      class="nav-arrow nav-arrow-right"
      :class="{ 'nav-arrow-disabled': isLast }"
      :disabled="isLast"
      @click="goNext"
      aria-label="Slide siguiente"
    >
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="9 18 15 12 9 6" />
      </svg>
    </button>

    <!-- Page Indicator -->
    <div class="slide-indicator">
      <div class="slide-indicator-inner">
        <button
          class="indicator-arrow"
          :class="{ 'indicator-arrow-disabled': isFirst }"
          :disabled="isFirst"
          @click.stop="goPrev"
          aria-label="Anterior"
        >
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="15 18 9 12 15 6" />
          </svg>
        </button>
        <span class="slide-indicator-current">{{ currentPage }}</span>
        <span class="slide-indicator-separator">/</span>
        <span class="slide-indicator-total">{{ total }}</span>
        <button
          class="indicator-arrow"
          :class="{ 'indicator-arrow-disabled': isLast }"
          :disabled="isLast"
          @click.stop="goNext"
          aria-label="Siguiente"
        >
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="9 18 15 12 9 6" />
          </svg>
        </button>
      </div>
      <!-- Progress bar -->
      <div class="slide-progress-bar">
        <div
          class="slide-progress-fill"
          :style="{ width: progressWidth }"
        />
      </div>
    </div>
  </div>
</template>
