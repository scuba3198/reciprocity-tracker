import {createClient} from '@supabase/supabase-js'

const client = createClient(
  'https://ofmfmmkijmpkwvmduuex.supabase.co',
  'sb_publishable_PBk_8v__Bbf50us0jIk1tg_ZgnE_2ai',
)
let writeQueue = Promise.resolve()
let latestWrite = 0
const guestLedgerKey = 'good-faith.people.v2'

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

export function subscribe(callback) {
  let previousUserId
  const {data} = client.auth.onAuthStateChange((_event, session) => {
    const userId = session?.user.id ?? ''
    if (userId !== previousUserId) {
      previousUserId = userId
      callback(userId, session?.user.email ?? '')
    }
  })
  return () => data.subscription.unsubscribe()
}

export async function auth(action, email, password) {
  const result = action === 'signup'
    ? await client.auth.signUp({email, password})
    : action === 'signin'
      ? await client.auth.signInWithPassword({email, password})
      : await client.auth.signOut()
  if (result.error) throw new Error(result.error.message)
  if (action === 'signup' && !result.data.session) return 'Check your email to confirm your account.'
  return action === 'signout' ? 'Signed out.' : 'Signed in.'
}

export async function loadOrMigrate(userId, localPeople) {
  return enqueueWrite(async () => {
    await assertCurrentUser(userId)
    const storage = browserStorage()
    const pending = await recoverPending(userId, storage, writeLedger, assertCurrentUser)
    if (pending !== null) {
      consumeGuestLedger(userId, false, storage)
      return pending
    }

    const table = client.from('good_faith_ledgers')
    const {data, error} = await table.select('people').eq('user_id', userId).maybeSingle()
    if (error) throw error
    const initial = initialLedger(data, guestSeed(localPeople))
    if (!initial.insert) {
      await assertCurrentUser(userId)
      consumeGuestLedger(userId, false, storage)
      return JSON.stringify(initial.people)
    }

    await assertCurrentUser(userId)
    const {error: insertError} = await table.insert({user_id: userId, people: initial.people})
    if (!insertError) {
      await assertCurrentUser(userId)
      consumeGuestLedger(userId, true, storage)
      return JSON.stringify(initial.people)
    }
    // A concurrent first sign-in may have inserted the row; that cloud row wins.
    const {data: existing, error: readError} = await table.select('people').eq('user_id', userId).maybeSingle()
    if (readError) throw readError
    if (existing) {
      await assertCurrentUser(userId)
      consumeGuestLedger(userId, false, storage)
      return JSON.stringify(existing.people)
    }
    throw insertError
  })
}

async function assertCurrentUser(userId) {
  const {data: {user}, error} = await client.auth.getUser()
  if (error) throw error
  if (user?.id !== userId) throw new Error('Account changed while loading the ledger.')
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
  const {error} = await client.from('good_faith_ledgers')
    .upsert({user_id: userId, people}, {onConflict: 'user_id'})
  if (error) throw error
}
