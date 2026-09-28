import {createClient} from '@supabase/supabase-js'

const client = createClient(
  'https://ofmfmmkijmpkwvmduuex.supabase.co',
  'sb_publishable_PBk_8v__Bbf50us0jIk1tg_ZgnE_2ai',
)
let writeQueue = Promise.resolve()
let latestWrite = 0
let latestScenarioWrite = 0
const guestLedgerKey = 'good-faith.people.v2'
const guestScenariosKey = 'good-faith.think-ahead.v1'

export const browserStorage = () => globalThis.localStorage

export function guestSeed(localPeople) {
  return JSON.parse(localPeople)
}

export function consumeGuestLedger(userId, imported, storage = browserStorage()) {
  const guest = storage.getItem(guestLedgerKey)
  if (!imported && guest !== null && guest !== '[]') {
    storage.setItem(`good-faith.archived-ledger.${userId}.${crypto.randomUUID()}`, guest)
  }
  storage.removeItem(guestLedgerKey)
}

export function consumeGuestScenarios(userId, imported, storage = browserStorage()) {
  const guest = storage.getItem(guestScenariosKey)
  if (!imported && guest !== null && guest !== '[]') {
    storage.setItem(`good-faith.archived-scenarios.${userId}.${crypto.randomUUID()}`, guest)
  }
  storage.removeItem(guestScenariosKey)
}

export function persistPending(userId, people, storage = browserStorage()) {
  storage.setItem(`good-faith.pending.${userId}`, people)
}

export async function recoverPending(userId, storage, push, assertUser) {
  const key = `good-faith.pending.${userId}`
  const people = storage.getItem(key)
  if (people === null) return null
  await assertUser(userId)
  await push(userId, JSON.parse(people))
  await assertUser(userId)
  if (storage.getItem(key) === people) storage.removeItem(key)
  return people
}

export function enqueueWrite(write) {
  writeQueue = writeQueue.catch(() => {}).then(write)
  return writeQueue
}

export function initialLedger(row, localPeople) {
  return row ? {people: row.people, insert: false} : {people: localPeople, insert: true}
}

export function initialScenarios(cloud, local) {
  return cloud.length === 0 && local.length > 0 ? {scenarios: local, imported: true} : {scenarios: cloud, imported: false}
}

export const missingScenariosColumn = error => ['42703', 'PGRST204'].includes(error?.code) && error.message?.includes('scenarios')

export const accountTolerance = (user, fallback = 2) => [1, 2].includes(user?.user_metadata?.cure_tolerance)
  ? user.user_metadata.cure_tolerance : fallback

export function subscribe(callback) {
  let previousUserId
  const {data} = client.auth.onAuthStateChange((_event, session) => {
    const userId = session?.user.id ?? ''
    if (userId !== previousUserId || _event === 'PASSWORD_RECOVERY') {
      previousUserId = userId
      callback(userId, session?.user.email ?? '', _event)
    }
  })
  return () => data.subscription.unsubscribe()
}

export async function auth(action, email, password) {
  const result = action === 'signup'
    ? await client.auth.signUp({email, password})
    : action === 'signin'
      ? await client.auth.signInWithPassword({email, password})
      : action === 'reset'
        ? await client.auth.resetPasswordForEmail(email, {redirectTo: 'https://scuba3198.github.io/reciprocity-tracker/'})
        : action === 'update-password'
          ? await client.auth.updateUser({password})
          : await client.auth.signOut({scope: 'local'})
  if (result.error) throw new Error(result.error.message)
  if (action === 'signup' && !result.data.session) return 'Check your email to confirm your account.'
  if (action === 'reset') return 'If that email has an account, a password reset link has been sent.'
  if (action === 'update-password') return 'Your password has been updated.'
  return action === 'signout' ? 'Signed out.' : 'Signed in.'
}

export async function loadOrMigrate(userId, localPeople, localTolerance, localScenarios = '[]') {
  return enqueueWrite(async () => {
    const user = await assertCurrentUser(userId)
    const tolerance = accountTolerance(user, localTolerance)
    if (user.user_metadata?.cure_tolerance !== tolerance && tolerance === 2) await saveTolerance(userId, tolerance)
    const storage = browserStorage()
    const pending = await recoverPending(userId, storage, writeLedger, assertCurrentUser)
    const table = client.from('good_faith_ledgers')
    const {data, error} = await table.select('people,scenarios').eq('user_id', userId).maybeSingle()
    if (missingScenariosColumn(error)) {
      const {data: oldRow, error: oldError} = await table.select('people').eq('user_id', userId).maybeSingle()
      if (oldError) throw oldError
      if (oldRow) {
        await assertCurrentUser(userId)
        consumeGuestLedger(userId, false, storage)
        return {people: pending ?? JSON.stringify(oldRow.people), scenarios: '[]', scenariosReady: false, tolerance}
      }
      await assertCurrentUser(userId)
      const {error: insertError} = await table.insert({user_id: userId, people: guestSeed(localPeople)})
      if (insertError) {
        const {data: concurrent, error: readError} = await table.select('people').eq('user_id', userId).maybeSingle()
        if (readError) throw readError
        if (!concurrent) throw insertError
        await assertCurrentUser(userId)
        consumeGuestLedger(userId, false, storage)
        return {people: JSON.stringify(concurrent.people), scenarios: '[]', scenariosReady: false, tolerance}
      }
      await assertCurrentUser(userId)
      consumeGuestLedger(userId, true, storage)
      return {people: localPeople, scenarios: '[]', scenariosReady: false, tolerance}
    }
    if (error) throw error
    const pendingScenarios = await recoverPendingScenarios(userId, storage)
    if (pending !== null) {
      consumeGuestLedger(userId, false, storage)
      await assertCurrentUser(userId)
      consumeGuestScenarios(userId, false, storage)
      return {people: pending, scenarios: pendingScenarios ?? JSON.stringify(data?.scenarios ?? []), scenariosReady: true, tolerance}
    }

    const initial = initialLedger(data, guestSeed(localPeople))
    if (!initial.insert) {
      await assertCurrentUser(userId)
      const chosen = initialScenarios(data.scenarios ?? [], JSON.parse(localScenarios))
      if (chosen.imported) await writeScenarios(userId, chosen.scenarios)
      await assertCurrentUser(userId)
      consumeGuestLedger(userId, false, storage)
      consumeGuestScenarios(userId, chosen.imported, storage)
      return {people: JSON.stringify(initial.people), scenarios: pendingScenarios ?? JSON.stringify(chosen.scenarios), scenariosReady: true, tolerance}
    }

    await assertCurrentUser(userId)
    const {error: insertError} = await table.insert({user_id: userId, people: initial.people, scenarios: JSON.parse(localScenarios)})
    if (!insertError) {
      await assertCurrentUser(userId)
      consumeGuestLedger(userId, true, storage)
      consumeGuestScenarios(userId, true, storage)
      return {people: JSON.stringify(initial.people), scenarios: localScenarios, scenariosReady: true, tolerance}
    }
    // A concurrent first sign-in may have inserted the row; that cloud row wins.
    const {data: existing, error: readError} = await table.select('people,scenarios').eq('user_id', userId).maybeSingle()
    if (readError) throw readError
    if (existing) {
      await assertCurrentUser(userId)
      const chosen = initialScenarios(existing.scenarios ?? [], JSON.parse(localScenarios))
      if (chosen.imported) await writeScenarios(userId, chosen.scenarios)
      await assertCurrentUser(userId)
      consumeGuestLedger(userId, false, storage)
      consumeGuestScenarios(userId, chosen.imported, storage)
      return {people: JSON.stringify(existing.people), scenarios: JSON.stringify(chosen.scenarios), scenariosReady: true, tolerance}
    }
    throw insertError
  })
}

export function persistPendingScenarios(userId, scenarios, storage = browserStorage()) {
  storage.setItem(`good-faith.pending-scenarios.${userId}`, scenarios)
}

export async function recoverPendingScenarios(userId, storage = browserStorage()) {
  const key = `good-faith.pending-scenarios.${userId}`
  const scenarios = storage.getItem(key)
  if (scenarios === null) return null
  await assertCurrentUser(userId)
  await writeScenarios(userId, JSON.parse(scenarios))
  await assertCurrentUser(userId)
  if (storage.getItem(key) === scenarios) storage.removeItem(key)
  return scenarios
}

export function saveScenarios(userId, scenarios) {
  const revision = ++latestScenarioWrite
  try {
    persistPendingScenarios(userId, scenarios)
  } catch (error) {
    return Promise.resolve(`error:${error.message}`)
  }
  return enqueueWrite(async () => {
    try {
      await assertCurrentUser(userId)
      await writeScenarios(userId, JSON.parse(scenarios))
      const key = `good-faith.pending-scenarios.${userId}`
      if (browserStorage().getItem(key) === scenarios) browserStorage().removeItem(key)
      return revision === latestScenarioWrite ? 'saved' : 'queued'
    } catch (error) {
      return revision === latestScenarioWrite ? `error:${error.message}` : 'queued'
    }
  })
}

async function writeScenarios(userId, scenarios) {
  const {data, error} = await client.from('good_faith_ledgers')
    .update({scenarios}).eq('user_id', userId).select('user_id').single()
  if (error) throw error
  if (data.user_id !== userId) throw new Error('Account changed before scenarios could sync.')
}

async function assertCurrentUser(userId) {
  const {data: {user}, error} = await client.auth.getUser()
  if (error) throw error
  if (user?.id !== userId) throw new Error('Account changed while loading the ledger.')
  return user
}

export async function saveTolerance(userId, tolerance) {
  if (tolerance !== 1 && tolerance !== 2) throw new Error('Invalid CURE tolerance.')
  await assertCurrentUser(userId)
  const {data, error} = await client.auth.updateUser({data: {cure_tolerance: tolerance}})
  if (error) throw error
  if (data.user?.id !== userId) throw new Error('Account changed while saving CURE tolerance.')
}

export function save(userId, people) {
  const revision = ++latestWrite
  try {
    persistPending(userId, people)
  } catch (error) {
    return Promise.resolve(`error:${error.message}`)
  }
  return enqueueWrite(async () => {
    try {
      const {data: {user}, error: userError} = await client.auth.getUser()
      if (userError) throw userError
      if (user?.id !== userId) throw new Error('Account changed before the ledger could sync.')
      await writeLedger(userId, JSON.parse(people))
      const key = `good-faith.pending.${userId}`
      if (browserStorage().getItem(key) === people) browserStorage().removeItem(key)
      return revision === latestWrite ? 'saved' : 'queued'
    } catch (error) {
      return revision === latestWrite ? `error:${error.message}` : 'queued'
    }
  })
}

async function writeLedger(userId, people) {
  const {data, error} = await client.from('good_faith_ledgers')
    .update({people}).eq('user_id', userId).select('user_id').single()
  if (error) throw error
  if (data.user_id !== userId) throw new Error('Account changed before the ledger could sync.')
}
