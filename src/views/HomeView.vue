<template>
  <div class="home">
    <div>{{ env }} | {{ feature }}</div>
    <img alt="Vue logo" src="../assets/logo.png">
    <HelloWorld msg="Welcome to Your Vue.js App"/>
  </div>
</template>

<script>
// @ is an alias to /src
import HelloWorld from '@/components/HelloWorld.vue'

import { env, feature } from '../../env.cligenerated.json'

export default {
  name: 'HomeView',
  components: {
    HelloWorld
  },

  computed: {
    env: () => env,
    feature: () => feature
  }
}
</script>
