import assert from 'node:assert/strict'
import {readFileSync} from 'node:fs'
import test from 'node:test'

test('install manifest stays within the deployment path and supplies real PNG icons', () => {
  const html = readFileSync(new URL('../index.html', import.meta.url), 'utf8')
  assert.match(html, /rel="manifest" href="%BASE_URL%manifest\.webmanifest"/)
  const manifest = JSON.parse(readFileSync(new URL('../public/manifest.webmanifest', import.meta.url), 'utf8'))
  assert.equal(manifest.name, 'Good Faith')
  assert.equal(manifest.display, 'standalone')
  for (const base of ['https://example.com/', 'https://example.com/reciprocity-tracker/']) {
    const manifestUrl = new URL('manifest.webmanifest', base)
    for (const field of ['id', 'start_url', 'scope']) {
      assert.equal(new URL(manifest[field], manifestUrl).href, base)
    }
    for (const size of [192, 512]) {
      const icon = manifest.icons.find(icon => icon.sizes === `${size}x${size}`)
      assert.ok(icon, `Missing ${size}px icon`)
      assert.equal(icon.type, 'image/png')
      assert.equal(icon.purpose, 'any')
      assert.equal(new URL(icon.src, manifestUrl).href, `${base}icon-${size}.png`)
      const png = readFileSync(new URL(`../public/${icon.src}`, import.meta.url))
      assert.equal(png.subarray(0, 8).toString('hex'), '89504e470d0a1a0a')
      assert.equal(png.readUInt32BE(16), size)
      assert.equal(png.readUInt32BE(20), size)
    }
  }
})
