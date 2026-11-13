import './styles/index.css';
import { state, mobile, setRenderer, render, findPerson } from './state.js';
import { load, KEY } from './core/storage.js';
import { cancelEdit } from './actions.js';
import { initHelp, helpOpen, closeHelp } from './ui/help.js';
import { drawRail, initRail } from './ui/rail.js';
import { drawStrip } from './ui/strip.js';
import { drawDetail } from './ui/detail.js';
import { initImportExport } from './ui/import-export.js';
import { initAddPerson } from './ui/add-person.js';
import { initMotion } from './ui/motion.js';

function draw() { drawRail(); drawStrip(); drawDetail(); }
setRenderer(draw);

initHelp();
initRail();
initImportExport();
initAddPerson();

document.addEventListener('keydown', e => {
  if (e.key !== 'Escape') return;
  if (helpOpen()) closeHelp();
  else if (state.editing) cancelEdit();
});

// Another tab saved: adopt its data, or this tab's next save would silently overwrite it.
addEventListener('storage', e => {
  if (e.key !== KEY && e.key !== null) return;
  state.people = load();
  state.editing = null;
  if (!findPerson(state.selected)) state.selected = state.people.length ? state.people[0].id : null;
  render();
});

if (mobile.addEventListener) mobile.addEventListener('change', draw);
else if (mobile.addListener) mobile.addListener(draw);

draw();
initMotion();
