# Conceptual Data Pipeline: Unified Customer Complaint Intelligence
### Beejan Technologies

Beejan Technologies is a telecommunication company that wants to scale with data. To achieve this, they want a unified customer complaint records system so that the management and operations can better serve their customers and create value for the business.

## The Problem

Customers complain about three major issues – Poor Network, Incorrect Billing, and Bad Customer Service.

## The Challenge

Data is scattered and stored in different formats, Downstream users manually compile spreadsheets, Reports are delayed, no single pipeline exists for data flow, and Team work in silos.

## The Ask

Design a solution to bring all the data together and develop a conceptual end-to-end data pipeline.

## The Solution

<img src="./media/image1.png" style="width:6.24051in;height:3.28403in" />

Fig 1.1 Beejan Technologies Conceptual data pipeline

## 1. Design Choices

**Sources.** Four channels feed the pipeline: social media mentions, call center logs, SMS, and website form submissions. Social media is continuous and unstructured (free text, sometimes media); call center logs are semi-structured records generated per call, usually available shortly after a call ends rather than instantly; SMS arrives as short, unstructured text, often in bursts; website forms are structured, low-volume, and arrive one at a time as customers submit them. Because the channels differ this much in structure and arrival pattern, the pipeline is designed as a **hybrid batch-plus-Near real time system**

**Ingestion.** Each source is paired with the ingestion pattern that fits its nature: social media and SMS are treated as near-real-time feeds, pushed or pulled continuously into a staging area as small events; call center logs and website forms are treated as batch drops using full or incremental load ingestion, since they are naturally produced in files or periodic exports and don't need sub-minute latency. A **landing zone** sits in front of everything — its only job is to accept data in whatever shape it arrives and record where it came from and when, without touching the content.

**Storage.** Two conceptual stores exist. A **data lake** holds raw, untouched copies of everything (for traceability and reprocessing) plus a curated layer of cleaned, standardized records. A **data warehouse** holds the final, modeled, curated, analytics-ready tables — one row per complaint, joined with dimensions like time, channel, category, and customer. The lake favors an open, columnar file format so it stays cheap, and reprocessable if classification logic changes later; the warehouse favors a quarriable, columnar table structure optimized for aggregation, reporting and dashboarding. Keeping both is intentional: the lake is the system's memory and safety net; the warehouse is its fast-answer layer.

**Processing and transformation.** Once landed, records go through three logical passes: (a) **standardization** — normalizing timestamps, encodings, language, customer identifiers, and channel-specific fields into one common complaint schema; (b) **cleaning** — deduplicating repeated complaints (a customer messaging twice, or a call and a follow-up SMS about the same issue), and handling missing fields; (c) **classification and enrichment** — tagging each complaint with a category (e.g., network, billing, service), a severity or urgency signal, sentiment, and any resolved metadata (customer segment, region, product line). Classification is deliberately layered: a fast rules/keyword pass catches obvious cases quickly, and anything ambiguous is routed to a more sophisticated text-understanding pass. This two-speed approach keeps latency low for the majority of clear-cut complaints while still handling nuance.

**Serving.** Downstream consumers fall into three groups with different needs: (1) reporting/management wants aggregated dashboards and trend views refreshed on a regular cadence; (2) operational teams (network, billing, customer service) want near-real-time alerts when a spike or urgent complaint appears; (3) analysts occasionally want ad-hoc, row-level queries for investigation. The serving layer is designed to support all three from the same warehouse — scheduled dashboard refreshes, an alerting rule layer watching for thresholds, and direct query access for analysts — rather than building separate pipelines per audience.

**Orchestration and monitoring.** The pipeline runs on a mix of cadences: streaming sources flow continuously; batch sources trigger on a fixed schedule (e.g., hourly or daily, matching how often the source system actually produces new files). Every stage emits its own health signal — records in, records out, error count, processing time — and a central watcher compares these against expectations, raising an alert when a stage stalls, a source stops sending data, or error rates spike. Failures degrade gracefully: a broken enrichment step shouldn't block ingestion, and a stalled batch source shouldn't stop the streaming ones.

**DataOps.** The design assumes the pipeline is version-controlled, deployed through repeatable, automated promotion from a test setting into production, and observable end-to-end (logs, metrics, and lineage from source to served table). Reprocessing must be safe — because raw data is preserved in the lake, classification or cleaning logic can be corrected and rerun without re-collecting anything.

## 2. Assumptions

- Beejan already has some access to each channel's raw data (export files, log dumps, message feeds) — this brief does not assume ownership of the channel systems themselves.

- Call center logs are structured enough to be machine-read (fielded records), even if the "complaint text" inside them is free text.

- A basic pre-built complaint taxonomy (network, billing, service, other) exists or can be defined jointly with the reporting team.

- Data volumes are meaningful ("thousands daily") but not so large that specialized big-data engineering is a prerequisite for a first version.

- Customer identity can be reasonably reconciled across channels (e.g., a phone number or account ID appears in most records), which is what enables deduplication and a single customer view.

- Latency expectations differ by audience: management is fine with hourly/daily aggregates; operations wants near-real-time alerting on urgent issues.

## 3. Challenges and Unknowns

- **Cross-channel identity resolution** is the hardest unknown — without a reliable shared key, deduplicating "the same complaint, different channel" is unreliable.

- **Classification accuracy** on free text (especially SMS, which is short and abbreviation-heavy) will need ongoing tuning; a fixed rule set will drift as language and issues evolve.

- **Language and dialect variation** in customer text may reduce classification quality if not accounted for early.

- **Backpressure and late data** — a source going down and then dumping a backlog needs a defined recovery behavior, or downstream reports silently miss data.

- **Data quality ownership** — who is accountable when a source consistently sends malformed data is an organizational question, not just a technical one.

- **Privacy and retention** — complaint text may contain personal or sensitive details; retention rules and access controls need definition before this becomes a production system.
