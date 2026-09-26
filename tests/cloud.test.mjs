import assert from 'node:assert/strict'
import test from 'node:test'
import {consumeGuestLedger, enqueueWrite, guestSeed, initialLedger, persistPending, recoverPending} from '../src/Supabase.js'

test('first sign-in copies local data only when cloud is empty and queues writes in order', async () => {
  const local = [{id: 'local'}]
  const cloud = [{id: 'cloud'}]
  assert.deepEqual(initialLedger(null, local), {people: local, insert: true})
  assert.deepEqual(initialLedger({people: cloud}, local), {people: cloud, insert: false})

  const order = []
  await Promise.all([
    enqueueWrite(async () => { await new Promise(resolve => setTimeout(resolve, 10)); order.push(1) }),
    enqueueWrite(async () => { order.push(2) }),
  ])
  assert.deepEqual(order, [1, 2])
})

test('failed sync survives reload and reauth restores the account snapshot before returning data', async () => {
  const values = new Map()
  const storage = {
    getItem: key => values.get(key) ?? null,
    setItem: (key, value) => values.set(key, value),
    removeItem: key => values.delete(key),
  }
  const pending = JSON.stringify([{id: 'unsynced'}])
  persistPending('account-a', pending, storage)

  await assert.rejects(recoverPending('account-a', storage, async () => { throw new Error('offline') }, async () => {}), /offline/)
  assert.equal(storage.getItem('good-faith.pending.account-a'), pending)

  const applied = []
  await recoverPending('account-a', storage, async (_id, people) => applied.push(...people), async id => assert.equal(id, 'account-a'))
  assert.deepEqual(applied, [{id: 'unsynced'}])
  assert.equal(storage.getItem('good-faith.pending.account-a'), null)

  storage.setItem('good-faith.people.v2', JSON.stringify([{id: 'migrated'}]))
  consumeGuestLedger('account-a', true, storage)
  assert.equal(storage.getItem('good-faith.people.v2'), null)
  assert.equal([...values.keys()].some(key => key.startsWith('good-faith.archived-ledger.account-a.')), false)
  assert.deepEqual(guestSeed(JSON.stringify([{id: 'new-guest-ledger'}])), [{id: 'new-guest-ledger'}])

  storage.setItem('good-faith.people.v2', JSON.stringify([{id: 'preexisting-guest'}]))
  consumeGuestLedger('account-a', false, storage)
  assert.equal(storage.getItem('good-faith.people.v2'), null)
  const archive = [...values.keys()].find(key => key.startsWith('good-faith.archived-ledger.account-a.'))
  assert.deepEqual(JSON.parse(storage.getItem(archive)), [{id: 'preexisting-guest'}])
})

test('account switch waits for in-flight writes and never recovers another account snapshot', async () => {
  const values = new Map([['good-faith.pending.account-a', JSON.stringify([{id: 'latest'}])]])
  const storage = {
    getItem: key => values.get(key) ?? null,
    setItem: (key, value) => values.set(key, value),
    removeItem: key => values.delete(key),
  }
  let release
  let currentUser = 'account-a'
  const order = []
  const firstWrite = enqueueWrite(async () => {
    await new Promise(resolve => { release = resolve })
    order.push('old write finished')
  })
  const accountReload = enqueueWrite(async () => {
    order.push('account-b load')
    const pending = await recoverPending('account-b', storage, async () => assert.fail('cross-account pending write'), async id => assert.equal(currentUser, id))
    assert.equal(pending, null)
  })
  await new Promise(resolve => setTimeout(resolve, 0))
  assert.deepEqual(order, [])
  currentUser = 'account-b'
  release()
  await Promise.all([firstWrite, accountReload])
  assert.deepEqual(order, ['old write finished', 'account-b load'])
  assert.ok(storage.getItem('good-faith.pending.account-a'))
})
