import './styles/index.css';
import { state, mobile, setRenderer } from './state.js';
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

if (mobile.addEventListener) mobile.addEventListener('change', draw);
else if (mobile.addListener) mobile.addListener(draw);

draw();
initMotion();
