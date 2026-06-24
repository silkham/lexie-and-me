<!--
  Lexie & Me — Supabase sync wiring
  =================================
  Three blocks (A, B, C). Edit index.html in GitHub and place each as described.
  Replace the two placeholders in Block A with your values from Supabase
  (Project Settings → API): SUPABASE_URL and SUPABASE_ANON_KEY.

  What this does: on load, the app pulls the shared state from Supabase (falling
  back to local if offline). Every save writes to both local storage AND
  Supabase. A realtime subscription means Christine's phone refreshes when you
  change something, and vice versa. Last write wins — fine for two people who
  aren't editing the same second.
-->


<!-- ===================================================================
     BLOCK A  —  Supabase library + config
     WHERE: in the <head>, right after the Google Fonts <link> tags.
     (Adding the <script> in head is fine; it loads before the app runs.)
     =================================================================== -->
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
<script>
  const SUPABASE_URL  = "https://YOURPROJECT.supabase.co";   // <-- paste your Project URL
  const SUPABASE_ANON = "PASTE_YOUR_ANON_PUBLIC_KEY_HERE";    // <-- paste your anon public key
  const HOUSEHOLD_ID  = "household-CHANGE-ME-to-a-long-random-string"; // use the SAME string as in the SQL                              // matches the row created by the SQL
  const sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON);
</script>


<!-- ===================================================================
     BLOCK B  —  cloud save + load helpers
     WHERE: in the main <script>, immediately AFTER this existing line:
                 function save(){localStorage.setItem(LS,JSON.stringify(S))}
     Leave that line in place. These helpers wrap around it.
     =================================================================== -->
<script>
  // Push current state to Supabase (debounced so rapid edits batch into one write)
  let _syncTimer=null;
  function cloudSave(){
    clearTimeout(_syncTimer);
    _syncTimer=setTimeout(async ()=>{
      try{
        await sb.from('household_state')
          .upsert({ id:HOUSEHOLD_ID, state:S, updated_at:new Date().toISOString() });
      }catch(e){ /* offline — local copy already saved, will sync next change */ }
    },600);
  }

  // Pull shared state from Supabase and adopt it
  async function cloudLoad(){
    try{
      const { data, error } = await sb.from('household_state')
        .select('state').eq('id',HOUSEHOLD_ID).single();
      if(!error && data && data.state && Object.keys(data.state).length){
        S = data.state;
        // re-run the same migration guards as on local load, so old shapes are safe
        if(Array.isArray(S.meals)||!S.meals||!S.meals.bf){S.meals={bf:seedBreakfast.slice(0,3),ln:seedLunch.slice(0,3)};S.plans={}}
        if(!S.dayMeals)S.dayMeals={};
        if(!S.commitments)S.commitments=[];
        if(!S.plans)S.plans={};
        localStorage.setItem(LS, JSON.stringify(S));
        return true;
      }
    }catch(e){}
    return false;
  }

  // Wrap save() so every local save also triggers a cloud save.
  // (We keep the original save for local storage; this just adds the cloud step.)
  const _origSave = save;
  save = function(){ _origSave(); cloudSave(); };

  // Live updates: when the other phone writes, refresh this one.
  sb.channel('household')
    .on('postgres_changes',
        { event:'UPDATE', schema:'public', table:'household_state', filter:`id=eq.${HOUSEHOLD_ID}` },
        payload=>{
          if(payload.new && payload.new.state){
            S = payload.new.state;
            if(!S.dayMeals)S.dayMeals={};
            localStorage.setItem(LS, JSON.stringify(S));
            // redraw whatever screen is showing
            const cur=document.querySelector('.screen.on');
            if(cur){const id=cur.id; if(id==='today')renderToday(); else go(id);}
          }
        })
    .subscribe();
</script>


<!-- ===================================================================
     BLOCK C  —  load from cloud on startup
     WHERE: replace the existing two-line init at the very bottom of the
     main <script>:
                 /* init */
                 renderToday();getWeather();
     with the version below.
     =================================================================== -->
<script>
  /* init */
  (async ()=>{
    await cloudLoad();   // adopt shared state if it exists
    renderToday();
    getWeather();
  })();
</script>
