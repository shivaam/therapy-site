import './styles.css';
import { jsPDF } from 'jspdf';

const traits = [
  { name: "Growth ↔ Contentment", lo: "Satisfied with where I am", hi: "Constantly improving", default: 5 },
  { name: "Productivity ↔ Rest", lo: "Comfortable slowing down", hi: "Always need to be productive", default: 5 },
  { name: "Control ↔ Flexibility", lo: "Allow things to unfold", hi: "Prefer strong control", default: 5 },
  { name: "Conflict Avoidance ↔ Confrontation", lo: "Avoid conflict", hi: "Address issues quickly", default: 5 },
  { name: "Emotional Expression ↔ Containment", lo: "Express emotions openly", hi: "Keep emotions controlled", default: 5 },
  { name: "Independence ↔ Reliance on Others", lo: "Comfortable relying on others", hi: "Prefer full independence", default: 5 },
  { name: "Ambition ↔ Stability", lo: "Prefer stability", hi: "Pursue bigger achievements", default: 5 },
  { name: "Discipline ↔ Spontaneity", lo: "Strict structure", hi: "Spontaneous approach", default: 5 },
  { name: "Responsibility ↔ Lightness", lo: "Allow life to feel lighter", hi: "Strong sense of responsibility", default: 5 },
  { name: "Certainty ↔ Exploration", lo: "Prefer certainty", hi: "Comfortable exploring uncertainty", default: 5 },
  { name: "Self-Improvement ↔ Self-Acceptance", lo: "Allow imperfection", hi: "Constant self-improvement", default: 5 },
];

const values = traits.map(t => t.default);

function el(tag, attrs = {}, ...children) {
  const e = document.createElement(tag);
  for (const k in attrs) {
    if (k.startsWith('on') && typeof attrs[k] === 'function') e.addEventListener(k.slice(2), attrs[k]);
    else if (k === 'html') e.innerHTML = attrs[k];
    else e.setAttribute(k, attrs[k]);
  }
  for (const c of children) if (c) e.appendChild(typeof c === 'string' ? document.createTextNode(c) : c);
  return e;
}

function build() {
  const app = document.getElementById('app');
  app.innerHTML = '';

  const container = el('div', { class: 'container' });

  // Header
  const header = el('div', { class: 'header' },
    el('div', { class: 'tag' }, 'Self-Assessment'),
    el('div', { class: 'title' }, 'Personal Psychological Equalizer'),
    el('div', { class: 'subtitle' }, 'Think of each quality like a slider on a music equalizer. Choose the level that feels sustainable and realistic for you right now.')
  );

  // Rules
  const rules = el('div', { class: 'rules' },
    el('span', { class: 'rule' }, 'Scale: 1–9'),
    el('span', { class: 'rule' }, 'At least 3 sliders in 4–6'),
    el('span', { class: 'rule' }, 'At least 2 sliders below 5'),
    el('span', { class: 'rule' }, 'Sustainable, not ideal')
  );

  // Controls
  const controls = el('div', { class: 'controls' },
    el('button', { class: 'btn', onclick: () => resetAll() }, 'Reset'),
    el('button', { class: 'btn primary', onclick: () => exportPDF() }, 'Export PDF')
  );

  // Grid
  const grid = el('div', { class: 'grid', id: 'grid' });

  traits.forEach((t, i) => {
    const card = el('div', { class: 'card' });

    const info = el('div', null,
      el('div', { class: 'trait-name' }, t.name),
      el('div', { class: 'poles' },
        el('span', null, '1 — ' + t.lo),
        el('span', null, '9 — ' + t.hi)
      )
    );

    const track = el('div', { class: 'track' });
    const trackBar = el('div', { class: 'track-bar' });
    const fill = el('div', { class: 'fill', id: `fill-${i}`, style: `width:${pct(values[i])}%` });
    const thumb = el('div', { class: 'thumb', id: `thumb-${i}`, style: `left:${pct(values[i])}%` });
    const range = el('input', { type: 'range', min: '1', max: '9', value: String(values[i]), class: 'range', id: `range-${i}` });
    range.addEventListener('input', (ev) => update(i, parseInt(ev.target.value)));
    track.append(trackBar, fill, thumb, range);

    const value = el('div', { class: 'value', id: `value-${i}` }, String(values[i]));
    card.append(info, track, value);
    grid.append(card);
  });

  // Validation
  const validation = el('div', { class: 'validation' },
    el('div', { class: 'val-item' },
      el('div', { class: 'dot', id: 'dot-range' }),
      el('span', { class: 'val-text', id: 'txt-range' }, '0 of 3 in 4–6 range')
    ),
    el('div', { class: 'val-item' },
      el('div', { class: 'dot', id: 'dot-below' }),
      el('span', { class: 'val-text', id: 'txt-below' }, '0 of 2 below 5')
    )
  );

  const footer = el('div', { class: 'footer' }, 'Personal Psychological Equalizer');

  container.append(header, rules, controls, grid, validation, footer);
  app.append(container);
  validate();
}

function pct(v) { return (v - 1) / 8 * 100; }

function update(i, v) {
  values[i] = v;
  const p = pct(v);
  document.getElementById(`fill-${i}`).style.width = p + '%';
  document.getElementById(`thumb-${i}`).style.left = p + '%';
  document.getElementById(`value-${i}`).textContent = String(v);
  validate();
}

function validate() {
  const inRange = values.filter(v => v >= 4 && v <= 6).length;
  const below5 = values.filter(v => v < 5).length;
  const r1 = inRange >= 3;
  const r2 = below5 >= 2;
  document.getElementById('dot-range').className = 'dot ' + (r1 ? 'ok' : 'fail');
  document.getElementById('dot-below').className = 'dot ' + (r2 ? 'ok' : 'fail');
  document.getElementById('txt-range').textContent = `${inRange} of 3 in 4\u20136 range`;
  document.getElementById('txt-below').textContent = `${below5} of 2 below 5`;
}

function resetAll() {
  traits.forEach((t, i) => {
    const r = document.getElementById(`range-${i}`);
    if (r) r.value = t.default;
    update(i, t.default);
  });
}

function exportPDF() {
  const doc = new jsPDF({ unit: 'mm', format: 'a4' });
  const W = 210, H = 297, margin = 24;
  const usable = W - margin * 2;

  // Background
  doc.setFillColor(250, 250, 248);
  doc.rect(0, 0, W, H, 'F');

  // Header line
  doc.setDrawColor(26, 26, 26);
  doc.setLineWidth(0.4);
  doc.line(margin, 22, W - margin, 22);

  // Tag
  doc.setFont('helvetica', 'normal');
  doc.setFontSize(8);
  doc.setTextColor(184, 134, 11);
  doc.text('SELF-ASSESSMENT', margin, 18);

  // Date
  const date = new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });
  doc.setTextColor(122, 116, 104);
  doc.text(date, W - margin, 18, { align: 'right' });

  // Title
  doc.setFont('helvetica', 'normal');
  doc.setFontSize(20);
  doc.setTextColor(26, 26, 26);
  doc.text('Personal Psychological Equalizer', margin, 36);

  // Subtitle
  doc.setFontSize(9);
  doc.setTextColor(122, 116, 104);
  doc.text('Levels chosen based on what feels sustainable and realistic.', margin, 44);

  // Divider
  doc.setDrawColor(232, 229, 224);
  doc.setLineWidth(0.2);
  doc.line(margin, 50, W - margin, 50);

  // Sliders
  let y = 60;
  const rowH = 16;
  const barX = margin + 72;
  const barW = 80;

  traits.forEach((t, i) => {
    const v = values[i];
    const p = (v - 1) / 8;

    // Trait name
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(8.5);
    doc.setTextColor(26, 26, 26);
    doc.text(t.name, margin, y + 3);

    // Track bg
    doc.setFillColor(234, 230, 223);
    doc.roundedRect(barX, y, barW, 3, 1.5, 1.5, 'F');

    // Track fill
    const fillW = barW * p;
    if (fillW > 0) {
      doc.setFillColor(26, 26, 26);
      doc.roundedRect(barX, y, fillW, 3, 1.5, 1.5, 'F');
    }

    // Thumb
    doc.setFillColor(26, 26, 26);
    doc.circle(barX + barW * p, y + 1.5, 2.2, 'F');
    doc.setFillColor(250, 250, 248);
    doc.circle(barX + barW * p, y + 1.5, 1, 'F');

    // Value
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(12);
    doc.setTextColor(26, 26, 26);
    doc.text(String(v), barX + barW + 10, y + 3.5);

    y += rowH;
    if (y > 270) { doc.addPage(); y = 24; }
  });

  // Footer line
  doc.setDrawColor(26, 26, 26);
  doc.setLineWidth(0.4);
  doc.line(margin, H - 20, W - margin, H - 20);

  doc.setFont('helvetica', 'normal');
  doc.setFontSize(7.5);
  doc.setTextColor(122, 116, 104);
  doc.text('Personal Psychological Equalizer  ·  ' + date, margin, H - 14);

  doc.save('psychological-equalizer.pdf');
}

build();

window.resetAll = resetAll;
window.exportPDF = exportPDF;
