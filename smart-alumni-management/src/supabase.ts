import { createClient } from '@supabase/supabase-js'

const SUPABASE_URL = 'https://agzctzbsmjbstoiyenrf.supabase.co'
const SUPABASE_KEY = 'sb_publishable_9mDQ1g-Ue60AXuD5UeipoA_ol5eyCPD'

export const supabase = createClient(SUPABASE_URL, SUPABASE_KEY)
