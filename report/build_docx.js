// Build the Bellabeat case study as .docx: node build_docx.js <summary.json> <charts dir> <out.docx>
const fs = require("fs"), path = require("path");
const { Document, Packer, Paragraph, TextRun, HeadingLevel, ImageRun, Table, TableRow, TableCell,
  WidthType, ShadingType, BorderStyle, AlignmentType, LevelFormat, Footer, PageNumber } = require("docx");

const [, , SUMMARY, CHARTS, OUT] = process.argv;
const D = JSON.parse(fs.readFileSync(SUMMARY, "utf8"));
const fmt = n => n.toLocaleString("en-US");
const pct = (a, b) => Math.round(a / b * 100);
const TEAL = "0E7470", PLUM = "8B3A6C", MUTED = "5D6B69", RULE = "DBE2E0";
const CONTENT_W = 9026; // A4 width minus 1" margins, in DXA

// "**bold**" segments become bold runs
const runs = (t, o = {}) => t.split(/(\*\*[^*]+\*\*)/).filter(Boolean).map(s =>
  s.startsWith("**") ? new TextRun({ text: s.slice(2, -2), bold: true, ...o }) : new TextRun({ text: s, ...o }));
const p = (t, o = {}) => new Paragraph({ children: runs(t, o.run), spacing: { after: 120 }, ...o.para });
const note = t => p(t, { run: { color: MUTED, size: 18 } });
const h1 = (t, eyebrow) => [
  new Paragraph({ children: [new TextRun({ text: eyebrow.toUpperCase(), color: TEAL, size: 16, bold: true, characterSpacing: 40 })], spacing: { before: 360 } }),
  new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun(t)] })];
const h2 = t => new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun(t)] });
const bullet = t => new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: runs(t), spacing: { after: 60 } });
const numberRefs = []; // each numbered list gets its own reference so numbering restarts at 1
const numbered = items => { const ref = "num" + numberRefs.length; numberRefs.push(ref);
  return items.map(t => new Paragraph({ numbering: { reference: ref, level: 0 }, children: runs(t), spacing: { after: 60 } })); };

function image(file, title, sub) {
  const buf = fs.readFileSync(path.join(CHARTS, file));
  const w = buf.readUInt32BE(16), h = buf.readUInt32BE(20), width = 600;
  return [
    new Paragraph({ children: [new TextRun({ text: title, bold: true })], spacing: { before: 240, after: 40 }, keepNext: true }),
    new Paragraph({ children: [new TextRun({ text: sub, color: MUTED, size: 18 })], spacing: { after: 80 }, keepNext: true }),
    new Paragraph({ children: [new ImageRun({ type: "png", data: buf, transformation: { width, height: Math.round(width * h / w) },
      altText: { title, description: sub, name: file } })], spacing: { after: 80 } })];
}

function table(rows, widths, header) {
  const border = { style: BorderStyle.SINGLE, size: 4, color: RULE };
  const borders = { top: border, bottom: border, left: border, right: border };
  return new Table({
    width: { size: CONTENT_W, type: WidthType.DXA }, columnWidths: widths,
    rows: rows.map((r, i) => new TableRow({ tableHeader: header && i === 0, children: r.map((c, j) => new TableCell({
      width: { size: widths[j], type: WidthType.DXA }, borders, margins: { top: 60, bottom: 60, left: 100, right: 100 },
      shading: header && i === 0 ? { type: ShadingType.CLEAR, fill: "E8F2F1", color: "auto" } : undefined,
      children: [new Paragraph({ children: runs(c, { size: 19, bold: header && i === 0 ? true : undefined }) })] })) })) });
}

const ms = D.minutes_split, totalMin = Object.values(ms).reduce((a, b) => a + b);

const body = [
  new Paragraph({ children: [new TextRun({ text: "GOOGLE DATA ANALYTICS · CASE STUDY 2", color: TEAL, size: 16, bold: true, characterSpacing: 40 })] }),
  new Paragraph({ heading: HeadingLevel.TITLE, children: [new TextRun("How Bellabeat can use smart-device habits to grow the Bellabeat app")] }),
  p(`An analysis of ${D.n_users} Fitbit users over two months in 2016: when people move, when they sit, how they sleep, and which features they actually use. Prepared for Urška Sršen, Sando Mur and the Bellabeat marketing analytics team.`, { run: { color: MUTED, size: 24 } }),
  table([["Average steps per day", "Waking time sedentary", "Days reaching 10,000 steps", "Sleep trackers under 7 h"],
    [`**${fmt(D.avg_steps)}**`, `**~${D.avg_sed_waking_h} h**`, `**${D.pct_days_10k}%**`, `**${D.pct_users_under7}%**`]], [2256, 2256, 2257, 2257], true),

  ...h1("Business task", "Ask"),
  p("Analyse how consumers use non-Bellabeat smart fitness devices, then apply those trends to one Bellabeat product to guide marketing strategy. The three guiding questions:"),
  ...numbered(["What are the trends in smart device usage?", "How could these trends apply to Bellabeat customers?",
    "How could these trends influence Bellabeat marketing strategy?"]),
  p("**Product focus: the Bellabeat app.** Every Bellabeat device (Leaf, Time, Spring) feeds the app, and the app leads into the paid membership, so app engagement is the lever that reaches all customers.", { para: { spacing: { before: 120, after: 120 } } }),
  note("Stakeholders: Urška Sršen (cofounder, CCO), Sando Mur (cofounder, executive team), Bellabeat marketing analytics team."),

  ...h1("Data sources", "Prepare"),
  p("**FitBit Fitness Tracker Data** (Kaggle, uploaded by Möbius, CC0 public domain). Generated by respondents to an Amazon Mechanical Turk survey between 12 March and 12 May 2016. It ships as two exports (3.12.16–4.11.16 and 4.12.16–5.12.16) of 29 CSV files in total, in long format with one row per user per day, hour, minute or second."),
  table([["File", "Grain", "Used for"],
    ["dailyActivity_merged", "user × day", "steps, distance, activity minutes, calories (both periods)"],
    ["hourlySteps_merged", "user × hour", "time-of-day pattern (both periods)"],
    ["sleepDay_merged", "user × night", "minutes asleep, time in bed (period 2 only)"],
    ["weightLogInfo_merged", "log entry", "feature adoption (weight logging)"],
    ["heartrate_seconds_merged", "user × 5 sec", "feature adoption (heart rate)"]], [3000, 1700, 4326], true),
  h2("Does it ROCCC?"),
  table([["Criterion", "Rating", "Reason"],
    ["Reliable", "Low", "35 users is a small sample, self-selected through MTurk, with no age, gender or location data."],
    ["Original", "Low", "Third-party upload, not collected by Bellabeat or Fitbit directly."],
    ["Comprehensive", "Medium", "Rich activity and sleep metrics, but sleep covers only 24 users and weight only 13."],
    ["Current", "Low", "Collected in 2016."],
    ["Cited", "Medium", "Source and licence are documented on Kaggle and Zenodo."]], [1900, 1100, 6026], true),
  p("The biggest gap for Bellabeat is that the users are not known to be women, Bellabeat's target market. The findings below are directional and should be confirmed with Bellabeat's own app data before large spend decisions.",
    { para: { spacing: { before: 200, after: 120 }, border: { left: { style: BorderStyle.SINGLE, size: 18, color: PLUM, space: 8 } }, indent: { left: 200 } } }),
  note("Privacy: users are identified only by a 10-digit Id, with no personal information. The data was downloaded with kagglehub and the raw CSVs were kept unchanged."),

  ...h1("Cleaning and transformation", "Process"),
  p("Tool: SQL, run in DuckDB. DuckDB queries the CSVs directly and handles the multi-million-row heart rate file easily, which a spreadsheet cannot. Keeping every step in SQL scripts (01_load.sql, 02_clean.sql, 03_analysis.sql) makes the work repeatable and easy to review."),
  ...numbered(D.log),
  bullet("Parsed all date and datetime text fields (for example 4/12/2016 1:00:00 AM) into proper datetime types with strptime."),
  bullet("Resolved duplicate user-days and user-hours with row_number() OVER (PARTITION BY Id, date), keeping the most complete row."),
  bullet("Added derived columns: wear time (sum of the four activity-minute columns), weekday, combined very + fairly active minutes, and awake-in-bed minutes (time in bed − minutes asleep)."),
  bullet("Classified each user by average daily steps: under 5,000 sedentary, 5,000–7,499 lightly active, 7,500–9,999 fairly active, 10,000+ very active."),
  bullet("Ran a SQL checks view before analysis: no duplicate user-days or user-nights, no day over 1,440 minutes, no one asleep longer than in bed, no null steps or dates. All five return 0."),

  ...h1("Summary of the analysis", "Analyze"),
  ...[
    `After cleaning: **${D.n_users} users, ${fmt(D.n_days)} tracked days** from ${D.date_range[0]} to ${D.date_range[1]}. Users logged between ${D.days_per_user.min} and ${D.days_per_user.max} days (median ${D.days_per_user["50%"]}).`,
    `Users average **${fmt(D.avg_steps)} steps** a day (median ${fmt(D.median_steps)}), below the commonly cited 10,000. Only ${D.pct_days_10k}% of days reach 10,000.`,
    `On the ${fmt(D.scatter_sed_sleep.length)} days with sleep tracked, users spend **${D.avg_sed_waking_h} waking hours sedentary**. The all-day average of ${D.avg_sed_h} h overstates this, because on the ${fmt(D.n_days - D.scatter_sed_sleep.length)} days without a sleep record the device logs sleep as sedentary (${D.avg_sed_nosleep_h} h).`,
    `A typical day also holds ${Math.round(D.avg_light_min / 6) / 10} hours of light activity and only ${D.avg_active_min} minutes of fairly or very active exercise.`,
    "Steps follow the working day: almost nothing before 6:00, a lunchtime peak at 12:00–14:00 and the highest peak at 17:00–19:00.",
    `Steps and calories burned are moderately correlated (r = ${D.corr_steps_cal}), so more movement does pay off in energy use.`,
    `${D.sleep_users} of ${D.n_users} users tracked sleep, and only ${D.sleep_users_regular} did so on 15 or more nights. Average sleep is ${D.avg_sleep_h} hours, ${D.pct_nights_under7}% of nights fall short of 7 hours, and users lie awake in bed ${D.avg_awake_in_bed} minutes on average.`,
    `Sedentary minutes and minutes asleep are negatively correlated (r = ${D.corr_sed_sleep}).`,
    `The device was worn for 23+ hours on only **${D.pct_days_full_wear}%** of days (average wear ${D.avg_wear_h} h), so many users take it off, most likely at night.`,
    `Weight logging was used by ${D.weight_users} users and ${D.weight_manual_pct}% of entries were typed in by hand. Heart rate data exists for ${D.hr_users} users.`,
  ].map(bullet),

  ...h1("Key findings", "Share"),
  ...image("1_minutes.png", "Most of the waking day is spent sitting", "Average minutes per tracked day, by intensity"),
  note(`All tracked days. On the ${fmt(D.n_days - D.scatter_sed_sleep.length)} days without a sleep record, time asleep is counted as sedentary (${D.avg_sed_nosleep_h} h). On the ${fmt(D.scatter_sed_sleep.length)} days with sleep tracked, waking sedentary time is ${D.avg_sed_waking_h} h, still most of the waking day.`),
  ...image("2_hourly.png", "Activity peaks at lunch and after work", "Average steps per hour of the day, all users. Highlighted: 12:00–14:00 and 17:00–19:00"),
  ...image("3_levels.png", "Users split evenly across four activity levels", "Number of users by average daily steps"),
  note("A single “get to 10,000 steps” message fits only about a quarter of users. Half average under 7,500 steps."),
  ...image("4_sleep.png", "More sitting goes with less sleep", "Each dot is one user-day with both activity and sleep recorded"),
  note(`r = ${D.corr_sed_sleep} across ${fmt(D.scatter_sed_sleep.length)} user-days. Part of this link is built in, because a day has a fixed 1,440 minutes, so it shows association, not cause. It is still a strong story for pairing activity and sleep features.`),
  ...image("5_weekday.png", "Sunday is the least active day", "Average steps by weekday"),
  ...image("6_adoption.png", "Features that need extra effort go unused", `Share of the ${D.n_users} users who produced any data for each feature`),
  note(`Steps record automatically, so every user has them. Sleep needs the device worn overnight, and weight needs a smart scale or manual entry (${D.weight_manual_pct}% of weight entries were manual).`),

  ...h1("Top three recommendations for the Bellabeat app", "Act"),
  ...[
    ["1. Market the app as a coach against sitting, not a step counter",
      "Lead campaigns with “move a little more, more often”. In the app, send gentle nudges after long sedentary spells, timed around the noon and 17:00–19:00 peaks when users already move, and set personal goals from each user's own baseline instead of a fixed 10,000 steps.",
      `Evidence: ~${D.avg_sed_waking_h} waking hours sedentary, ${D.avg_active_min} active minutes, ${D.pct_days_10k}% of days at 10,000 steps, users spread evenly across four activity levels.`],
    ["2. Make sleep the headline feature, linked to daytime activity",
      "Position Bellabeat as the brand that connects how you move with how you sleep. Use a wind-down reminder at bedtime, a morning sleep score, and app content that shows each user her own sitting-to-sleep link. Promote the Leaf as jewellery comfortable enough to wear overnight, since watches are often taken off at night.",
      `Evidence: ${D.pct_users_under7}% of sleep trackers average under 7 h, ${D.avg_awake_in_bed} min awake in bed, r = ${D.corr_sed_sleep} between sitting and sleep, device worn all day on only ${D.pct_days_full_wear}% of days.`],
    ["3. Automate tracking and use it to sell the membership",
      "Low-effort features get used; manual ones do not. Auto-sync wherever possible (for example, pair the Spring bottle for hydration and connected scales for weight) and replace manual logs with one-tap check-ins. Use weekly summaries and Sunday activity challenges in the app as a free taste of personalised membership coaching.",
      `Evidence: automatic step data from 100% of users versus ${pct(D.weight_users, D.n_users)}% for weight logging; Sunday averages ${fmt(D.weekday.Sunday.steps)} steps, the lowest of the week.`],
  ].flatMap(([t, b, e]) => [new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun({ text: t, color: PLUM })] }), p(b), note(e)]),
  h2("Next steps and additional data"),
  bullet("Repeat the analysis on Bellabeat's own app data, which covers women and includes stress, cycle and hydration tracking."),
  bullet("Add a larger, recent public dataset with demographics (for example, national health surveys on physical activity and sleep) to test whether these patterns hold for women."),
  bullet("A/B test the sedentary nudges and the sleep messaging and measure retention and membership conversion."),
];

const doc = new Document({
  title: "Bellabeat Smart Device Study",
  styles: {
    default: { document: { run: { font: "Calibri", size: 21 } } },
    paragraphStyles: [
      { id: "Title", name: "Title", basedOn: "Normal", next: "Normal", run: { font: "Georgia", size: 44, color: "1C2A29" }, paragraph: { spacing: { before: 80, after: 200 } } },
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true, run: { font: "Georgia", size: 32, color: "1C2A29" }, paragraph: { spacing: { before: 40, after: 160 }, outlineLevel: 0, keepNext: true } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true, run: { font: "Georgia", size: 25, color: "1C2A29" }, paragraph: { spacing: { before: 240, after: 100 }, outlineLevel: 1, keepNext: true } },
    ],
  },
  numbering: { config: [
    { reference: "bullets", levels: [{ level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 540, hanging: 280 } } } }] },
    ...numberRefs.map(reference => ({ reference, levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 540, hanging: 320 } } } }] })),
  ] },
  sections: [{
    properties: { page: { margin: { top: 1440, bottom: 1440, left: 1440, right: 1440 } } },
    footers: { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.RIGHT,
      children: [new TextRun({ text: "Bellabeat case study · ", color: MUTED, size: 16 }), new TextRun({ children: [PageNumber.CURRENT], color: MUTED, size: 16 })] })] }) },
    children: body,
  }],
});
Packer.toBuffer(doc).then(b => { fs.writeFileSync(OUT, b); console.log("wrote", OUT, b.length, "bytes"); });
