{% docs __overview__ %}
# Bellabeat case study: dbt project

This project turns public Fitbit data (35 users, March–May 2016) into the cleaned tables and headline figures behind the [Bellabeat case study report](https://ppppppeter.github.io/bellabeat-case-study/bellabeat_case_study.html), built with dbt on DuckDB. Models are layered **staging** (one view per raw CSV) → **intermediate** (parse dates, drop duplicates, resolve the overlap between the two exports) → **marts** (activity, sleep, weight and user tables) → **report** (the figures quoted in the report). Thirteen data tests guard the data: unique and not-null keys, accepted values, one row per user-day and per user-night, no day over 1,440 logged minutes, and never more time asleep than in bed. The main finding: users average 8,169 steps a day but spend about 11.9 waking hours sedentary, and more sitting goes with less sleep, so Bellabeat should market its app as a coach against sitting and for better sleep rather than as a step counter.

Open the lineage graph with the blue button at the bottom right of the page.
{% enddocs %}
